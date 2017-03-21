//
//  Discover
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage
import SVProgressHUD
import SwipeNavigationController

class Discover: UICollectionViewController, UITabBarControllerDelegate, UISearchBarDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Variable to hold objects to discover
    var discoverObjects = [PFObject]()
    // Set pipeline method
    var page: Int = 50
    
    // Refresher
    var refresher: UIRefreshControl!
    // Search Bar
    var searchBar = UISearchBar()
    
    
    // Function to refresh
    func refresh() {
        // Query Discover
        fetchDiscover()
        // Reload data
        self.collectionView!.reloadData()
    }
    
    // Function to show Search
    func showSearch() {
        // Push to SearchEngine
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    // Fetch Public Users
    func fetchDiscover() {
        
        // Fetch blocked users
        _ = appDelegate.queryRelationships()
        
        // Fetch objects
        let publicAccounts = PFUser.query()!
        publicAccounts.limit = self.page
        publicAccounts.order(byAscending: "createdAt")
        publicAccounts.whereKey("private", equalTo: false)
        publicAccounts.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                // Clear arrays
                self.discoverObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) {
                        self.discoverObjects.append(object)
                    }
                }

                // Check for other users
                if PFUser.current()!.value(forKey: "location") != nil {
                    // Fetch People Near You
                    self.discoverGeoCodes()
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    
    
    // Function to fetch geoLocation
    func discoverGeoCodes() {
        // Find location
        let discover = PFUser.query()!
        discover.limit = self.page
        discover.order(byAscending: "createdAt")
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) && !self.discoverObjects.contains(where: {$0.objectId! == object.objectId!}) && (object.objectId! !=  PFUser.current()!.objectId!) {
                        self.discoverObjects.append(object)
                    }
                }
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            // Reload data
            self.collectionView!.reloadData()
        })
    }

    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.collectionView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)

        // Fetch public accounts
        fetchDiscover()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        self.collectionView!.addSubview(refresher)
        
        // Configure navigationBar and tabBar
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.delegate = self
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.backgroundColor = UIColor.white
        
        // SearchbarDelegates
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.frame.size.width = UIScreen.main.bounds.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Clear searchBar text
        self.searchBar.text! = ""
        
        // Resign frist responder
        self.searchBar.resignFirstResponder()
        
        // Configure navigationBar, tabBar, and statusBar
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.delegate = self
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    
    // MARK: - SearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Show SearchEngine
        self.showSearch()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Resign first responder
        self.searchBar.resignFirstResponder()
    }
    
    
    // MARK: - UICollectionViewHeader
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Size should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 200)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "discoverHeader", for: indexPath) as! DiscoverHeader
        
        // Set delegate
        header.delegate = self
        // Set titles
        header.ssTitle.text! = "rp\nSELECTED 🔍 STORIES"
        header.ssTitle.numberOfLines = 2
        
        // Tap title to search
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(showSearch))
        searchTap.numberOfTapsRequired = 1
        header.ssTitle.isUserInteractionEnabled = true
        header.ssTitle.addGestureRecognizer(searchTap)
        
        // Update Stories
        header.updateUI()

        return header
    }

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return discoverObjects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "discoverCell", for: indexPath) as! DiscoverCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2.0
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Fetch Discover Objects
        discoverObjects[indexPath.row].fetchIfNeededInBackground(block:  {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get username
                cell.rpUsername.text! = object!["username"] as! String
                
                // (2) Get profile photo
                // Handle optional chaining
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Append to otherObject
        otherObject.append(self.discoverObjects[indexPath.row])
        // Append to otherName
        otherName.append(self.discoverObjects[indexPath.row].value(forKey: "username") as! String)
        
        // Push to VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.discoverObjects.count {
            // Increase page size to load more posts
            page = page + 50
            // Query friends
            fetchDiscover()
        }
    }
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.collectionView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            // Reload data
            fetchDiscover()
        }
    }
}
