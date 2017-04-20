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

import DZNEmptyDataSet
import SDWebImage
import SVProgressHUD
import SwipeNavigationController


class Discover: UICollectionViewController, UITabBarControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate, UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Variable to hold objects to discover
    var discoverObjects = [PFObject]()
    
    // Set pipeline method
    var page: Int = 500
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Boolean to determine randomized query; whether function will fetch public/private accounts
    var switchBool: Bool? = false
    
    @IBOutlet weak var searchBar: UITextField!
    
    // Function to refresh
    func refresh() {
        // Fetch Discover
        fetchDiscover()
        // End refresher
        refresher.endRefreshing()
        // Reload data
        self.collectionView!.reloadData()
    }

    // Fetch Users and shuffle results
    func fetchDiscover() {
        // Fetch blocked users
        _ = appDelegate.queryRelationships()

        let publicWProPic = PFUser.query()!
        publicWProPic.whereKey("private", equalTo: false)
        publicWProPic.whereKey("proPicExists", equalTo: true)
        
        let privateWProPic = PFUser.query()!
        privateWProPic.whereKey("private", equalTo: true)
        privateWProPic.whereKey("proPicExists", equalTo: true)
        
        let both = PFQuery.orQuery(withSubqueries: [publicWProPic, privateWProPic])
        if switchBool == true {
            both.order(byAscending: "createdAt")
        } else {
            both.order(byDescending: "createdAt")
        }
        both.limit = self.page
        both.whereKey("objectId", notEqualTo: "mWwx2cy2H7")
        both.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                // Clear arrays
                self.discoverObjects.removeAll(keepingCapacity: false)
                let shuffled = objects!.shuffled()
                
                for object in shuffled {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) {
                        self.discoverObjects.append(object)
                    }
                }
                
                // FETCH nearby users
                if PFUser.current()!.value(forKey: "location") != nil {
                    self.discoverGeoCodes()
                }
                

                if self.discoverObjects.count == 0 {
                    // MARK: - DZNEmptyDataSet
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
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
        discover.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        discover.limit = self.page
        discover.order(byAscending: "createdAt")
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) && !self.discoverObjects.contains(where: {$0.objectId! == object.objectId!}) {
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
    
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.discoverObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "\n\n💩\nSomething Went Wrong"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Button title
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Tap To Reload"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Determine randomized integer
        let randomInt = arc4random()
        if randomInt % 2 == 0 {
            // Even
            switchBool = true
        } else {
            // Odd
            switchBool = false
        }
        // Fetch public accounts
        fetchDiscover()
    }
    
    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.collectionView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Resign frist responder
        self.searchBar.resignFirstResponder()
        
        // Configure navigationBar, tabBar, and statusBar
        self.extendedLayoutIncludesOpaqueBars = true
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.clear)
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.backgroundColor = UIColor.white
        
        // Set UITabBarController's Delegate
        self.navigationController?.tabBarController?.delegate = self
        
        // Pull to refresh action
        refresher = UIRefreshControl()

        
        // Determine randomized integer that SHUFFLES OBJECTS
        let randomInt = arc4random()
        if randomInt % 2 == 0 {
            // Even
            switchBool = true
            refresher.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
        } else {
            // Odd
            switchBool = false
            refresher.backgroundColor = UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
        }
        
        // Fetch public accounts
        fetchDiscover()
        
        // Add UIRefresher
        refresher.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)

        // UITextField (searchBar)
        searchBar.delegate = self
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.navigationController?.navigationItem.titleView = searchBar
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    // MARK: - UITextField delegate method
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Push to SearchEngine
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - UICollectionViewHeader
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Size should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 215)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "discoverHeader", for: indexPath) as! DiscoverHeader
        
        // Set delegate
        header.delegate = self
        header.ssTitle.text = "rp\nSELECTED 🗞 STORIES"

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
        cell.rpUserProPic.layer.borderColor = UIColor.randomColor().cgColor
        cell.rpUserProPic.layer.borderWidth = 1.50
        cell.rpUserProPic.clipsToBounds = true

        // (1) Set username
        cell.rpUsername.text! = (self.discoverObjects[indexPath.row].value(forKey: "username") as! String).lowercased()
        
        // (2) Get and set profile photo
        // Handle optional chaining
        if let proPic = self.discoverObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_addActivityIndicator()
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Append to <otherObject> and <otherName>
        otherObject.append(self.discoverObjects[indexPath.row])
        otherName.append(self.discoverObjects[indexPath.row].value(forKey: "username") as! String)
        // Push to VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.collectionView!.contentOffset.y >= self.collectionView!.contentSize.height - self.view.frame.size.height * 2 {
//            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.discoverObjects.count {
            // Increase page size to load more posts
            page = page + 50
            
            // Fetch objects
            let accounts = PFUser.query()!
            accounts.whereKey("objectId", notEqualTo: "mWwx2cy2H7")
            accounts.whereKey("private", equalTo: switchBool ?? true)
            accounts.whereKey("proPicExists", equalTo: switchBool ?? true)
            accounts.limit = self.page
            if switchBool == true {
                accounts.order(byDescending: "createdAt")
            } else {
                accounts.order(byAscending: "createdAt")
            }
            accounts.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                    for object in objects! {
                        // Skip blockedUsers and duplicates
                        if !blockedUsers.contains(where: {$0.objectId == object.objectId}) && !self.discoverObjects.contains(where: {$0.objectId! == object.objectId!}) {
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
    }
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.collectionView!.contentOffset.y <= -200.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }
}
