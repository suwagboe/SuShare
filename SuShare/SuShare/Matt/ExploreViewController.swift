//
//  ExploreViewController.swift
//  SuShare
//
//  Created by Matthew Ramos on 5/23/20.
//  Copyright © 2020 Matthew Ramos. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ExploreViewController: UIViewController {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var exploreButton: UIButton!
    @IBOutlet weak var friendsButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    
    var suShareListener: ListenerRegistration?
    var emptyView = EmptyView(title: "No SuShares Available", message: "Enter valid input or try a different query")
    var boldFont: UIFont?
    var thinFont: UIFont?
    
    
     private let circularTransition = CircularTransition()
    
    //------------------------
    //Jaheed
    var sideMenuOpen = false
    let transiton = SlideInTransition()
    var topView: UIView?
    var didTapMenuType: ((MenuType) -> Void)?
    var gesture = UITapGestureRecognizer()
    //------------------------
    
    var originalSusus = [SuShare]() {
        didSet {
            if currentSusus.isEmpty {
                currentSusus = originalSusus
            }
        }
    }
    
    var currentSusus = [SuShare]() {
        didSet {
            collectionView.reloadData()
            if currentSusus.isEmpty {
                collectionView.backgroundView = emptyView
            } else {
                collectionView.backgroundView = nil
            }
        }
    }
    var currentTags = [Int]()
    var currentQuery = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        toggleExplore()
        boldFont = exploreButton.titleLabel?.font
        thinFont = friendsButton.titleLabel?.font
        setSuShareListener()
        
        
        createButton.layer.cornerRadius = createButton.frame.size.width / 2
        
    }
    
    //---------------------------------------------------------------------------------
    // JAHEED
    @IBAction func didTapMenu(_ sender: UIBarButtonItem) {
        guard let menuViewController = storyboard?.instantiateViewController(identifier: "MenuViewController") as? MenuViewController else{return}
        menuViewController.didTapMenuType = { menuType in
            self.transitionToNew(menuType)
        }
        
         let tap = UITapGestureRecognizer(target: self, action:    #selector(self.handleTap(_:)))
        transiton.dimmingView.addGestureRecognizer(tap)

        menuViewController.modalPresentationStyle = .overCurrentContext
        menuViewController.transitioningDelegate = self
        present(menuViewController, animated: true)
        
    }
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
           dismiss(animated: true, completion: nil)
       }
    
    func transitionToNew(_ menuType: MenuType) {
        let title = String(describing: menuType).capitalized
        self.title = title
        
        topView?.removeFromSuperview()
        switch menuType {
        case .username:
            print("tapped")
        case .friends:
            let storyboard: UIStoryboard = UIStoryboard(name: "Friends", bundle: nil)
            let friendsVC = storyboard.instantiateViewController(identifier: "UserFriendsViewController")
            self.navigationController?.pushViewController(friendsVC, animated: true)
        case .search:
            self.navigationController?.pushViewController(AddFriendViewController(), animated: true)
        case .settings:
            //UIViewController.showViewController(storyBoardName: "UserSettings", viewControllerId: "SettingsViewController")
            let storyboard: UIStoryboard = UIStoryboard(name: "UserSettings", bundle: nil)
            let settingsVC = storyboard.instantiateViewController(identifier: "SettingsViewController")
            self.navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    //---------------------------------------------------------------------------------
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        suShareListener?.remove()
        
    }
    
    private func toggleExplore() {
        exploreButton.isEnabled = false
        friendsButton.isEnabled = true
        exploreButton.underline()
        
    }
    
    private func setSuShareListener() {
        suShareListener = Firestore.firestore().collection(DatabaseService.suShareCollection).addSnapshotListener( { [weak self] (snapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error getting favorites", message: "\(error.localizedDescription)")
                }
            } else if let snapshot = snapshot {
                let suShareData = snapshot.documents.map { $0.data() }
                let suShares = suShareData.map { SuShare($0)}
                self?.originalSusus = suShares
                
            }
            }
        )
    }
    @IBAction func exploreButtonPressed(_ sender: UIButton) {
        friendsButton.removeLine()
        exploreButton.titleLabel?.font = boldFont
        friendsButton.titleLabel?.font = thinFont
        toggleExplore()
    }
    
    @IBAction func friendsButtonPressed(_ sender: UIButton) {
        friendsButton.isEnabled.toggle()
        exploreButton.isEnabled.toggle()
        exploreButton.titleLabel?.font = thinFont
        friendsButton.titleLabel?.font = boldFont
        exploreButton.removeLine()
        friendsButton.underline()
    }
    
    
    @IBAction func tagButtonPressed(_ sender: UIButton) {
        let wasPressed = tagFilter(tag: sender.tag)
        switch wasPressed {
        case true:
            sender.backgroundColor = .systemGray4
        case false:
            sender.backgroundColor = .systemGray6
        }
    }
    
    private func tagFilter(tag: Int) -> Bool {
        var wasPressed = false
        if !currentTags.contains(tag) {
            currentTags.append(tag)
            wasPressed.toggle()
        } else {
            guard let index = currentTags.firstIndex(of: tag) else {
                return wasPressed
            }
            currentTags.remove(at: index)
            if currentTags.isEmpty && currentQuery == "" {
                currentSusus = originalSusus
                return wasPressed
            }
        }
        currentSusus = originalSusus.filter { currentTags.contains($0.category.first ?? 0)}
        return wasPressed
    }

    //need to add case for returning to 0 tags, with query
    
    // createSuShare segue
    
    @IBAction func buttonPressed(_ sender: UIButton) {
       // performSegue(withIdentifier: "goToCreateSusu", sender: self)
         
        //https://stackoverflow.com/questions/18777627/segue-from-one-storyboard-to-a-different-storyboard
        let vc = UIStoryboard(name: "CreateSusu", bundle: nil).instantiateViewController(withIdentifier: "CreateSusu") as? CreateSusuViewController
        
      //  https://www.appcoda.com/ios-programming-101-how-to-hide-tab-bar-navigation-controller/#:~:text=When%20it's%20set%20to%20YES,the%20RecipeDetailViewController%20to%20%E2%80%9CYES%E2%80%9D.
        vc?.hidesBottomBarWhenPushed = true // hides the botton tab bar
        
        self.show(vc!, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "goToCreateSusu" {
               guard let createVC = segue.destination as? CreateSusuViewController else { return }
             //  createVC.transitioningDelegate = self
           // createVC.modalPresentationStyle = .popover
           // navigationController?.pushViewController(createVC, animated: true)
            
//            createVC.transitioningDelegate = self
//            createVC.modalPresentationStyle = .custom
//            navigationController?.pushViewController(createVC, animated: true)
        //    present(createVC, animated: true)
           }
       }

}

extension ExploreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        currentSusus.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as? ExploreCell else {
            fatalError("Couldn't downcast to ExploreCell, check cellForItemAt")
        }
        
        let suShare = currentSusus[indexPath.row]
        
        cell.configureCell(suShare: suShare)
        cell.shadowConfig()
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let storyboard = UIStoryboard(name: "SushareDetail", bundle: nil)
//        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
//             return
//        }
//        detailVC.sushare = currentSusus[indexPath.row]
//        navigationController?.pushViewController(detailVC, animated: true)
        navigationController?.pushViewController(PaymentViewController(), animated: true)
    }
    
    
}

extension ExploreViewController: UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = UIScreen.main.bounds.size.height / 3
        let width =
            UIScreen.main.bounds.size.width - 100
        return CGSize(width: width, height: height * 2)
    }
    
    //need insets
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    
}

extension ExploreViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text?.lowercased(), !query.isEmpty else {
            if !currentTags.isEmpty {
                currentSusus = originalSusus.filter { currentTags.contains($0.category.first ?? 0)}
            } else {
                currentSusus = originalSusus
            }
            return
        }
        currentQuery = query
        currentSusus = originalSusus.filter { $0.description.lowercased().contains(query) || $0.susuTitle.lowercased().contains(query)}

    }
}

//---------------------------------------------------------------------------------
// Jaheed

extension ExploreViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if source.modalPresentationStyle == .custom {
           circularTransition.transitionMode = .present
                       //circularTransition.startingPoint = createButton.center
                      // circularTransition.circleColor = createButton.backgroundColor!
            
            return circularTransition
        } else {
            transiton.isPresenting = true
                 return transiton
        }
        
     
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transiton.isPresenting = false
        return transiton
    }
}
