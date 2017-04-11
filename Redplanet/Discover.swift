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


/*
 These extensions add a shuffle() method to any mutable collection and a shuffled() method to any sequence
*/
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of given collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}
extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}



class Discover: UICollectionViewController, UITabBarControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate, UITextFieldDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Variable to hold objects to discover
    var discoverObjects = [PFObject]()
    // Set pipeline method
    var page: Int = 100
    
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
    
    // Fetch Public Users
    func fetchDiscover() {
        
        // Fetch blocked users
        _ = appDelegate.queryRelationships()
        
        
        // Fetch objects
        let accounts = PFUser.query()!
//        accounts.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        accounts.whereKey("private", equalTo: true)
        accounts.whereKey("proPicExists", equalTo: true)
//        accounts.whereKey("objectId", containedIn: a)
//        if switchBool == true {
//            accounts.order(byAscending: "createdAt")
//        } else {
//            accounts.order(byDescending: "createdAt")
//        }
        accounts.order(byAscending: "createdAt")
        accounts.limit = self.page
        accounts.findObjectsInBackground(block: {
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

                if self.discoverObjects.count == 0 {
                    print("FIRED HERE AGAIN")
                    // Call viewDidLoad() again
                    self.viewDidLoad()
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
        let font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Reload data...
        self.viewDidLoad()
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
        // MARK: - UINavigationBar Extension
        // Configure UINavigationBar, and show UITabBar
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
        
        // Determine randomized integer
        let randomInt = arc4random()
        if randomInt % 2 == 0 {
            // Even
            switchBool = true
        } // Otherwise odd; set to false by default
        

        // Fetch public accounts
        fetchDiscover()
        
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
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
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

        // (1) Set username
        cell.rpUsername.text! = (self.discoverObjects[indexPath.row].value(forKey: "username") as! String).lowercased()
        
        // (2) Get and set profile photo
        // Handle optional chaining
        if let proPic = discoverObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_addActivityIndicator()
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
    
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
            accounts.whereKey("private", equalTo: switchBool ?? true)
            accounts.whereKey("proPicExists", equalTo: true)
            accounts.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
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
