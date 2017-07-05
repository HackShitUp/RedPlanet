//
//  Home.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit
import DZNEmptyDataSet

import Parse
import ParseUI
import Bolts

import OneSignal
import SDWebImage

// Define NotificationName
let homeNotification = Notification.Name(rawValue: "home")

/*
 UITableViewController class that represents "Home" in the main interface of the app. This class is a relationship view controller
 to "MasterUI.swift" and is the 1st of the 5 icons in the bottom tab-bar.
*/

class Home: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate Constant
    let appDelegate = AppDelegate()
    
    // Array to hold following
    var following = [PFObject]()
    
    // Array to hold posts/skipped
    var posts = [PFObject]()
    var skipped = [PFObject]()
    
    
    var collections = [PFObject]()
    
    // Set Current User's Most Recent Post
    var currentUserPost = [PFObject]()
    
    // PFQuery Limit - Pipeline method
    var page: Int = 50
    // UIRefreshControl
    var refresher: UIRefreshControl!
    
    
    
    // Function to refresh data
    func refresh() {
        refresher.endRefreshing()
    }
    
    // QUERY: FOLLOWING
    func fetchFollowing() {
        
        // Begin UIRefreshControl
        self.refresher.beginRefreshing()
        
        // MARK: - AppDelegate
        _ = appDelegate.queryRelationships()
        
        // Following
        let following = PFQuery(className: "FollowMe")
        following.whereKey("isFollowing", equalTo: true)
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.limit = 1000000
        following.includeKeys(["follower", "following"])
        following.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // End UIRefreshControl
                self.refresher.endRefreshing()
                
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                // Append current user
                self.following.append(PFUser.current()!)
                
                for object in objects! {
                    self.following.append(object.object(forKey: "following") as! PFUser)
                }
                
                self.fetchFirstPosts(forGroup: self.following)
                
            } else {
                print(error?.localizedDescription as Any)
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FETCH COLLECTIONS
    func fetchCollections(forGroup: [PFObject]) {
        
    }
    
    // FETCH POSTS
    func fetchFirstPosts(forGroup: [PFObject]) {
//        , completionHandler: @escaping (_ currentUserPost: PFObject) -> ()) {
        let postsClass = PFQuery(className: "Posts")
        postsClass.whereKey("byUser", containedIn: forGroup)
        postsClass.includeKeys(["byUser", "toUser"])
        postsClass.order(byDescending: "createdAt")
        postsClass.limit = 1000000
        postsClass.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.posts.removeAll(keepingCapacity: false)
                self.currentUserPost.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    // Configure time to check for "Ephemeral" content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    
                    // (1) MAP the current array, <posts>
                    let users = self.posts.map {$0.object(forKey: "byUser") as! PFUser}
                    // (2) Check if posts array does NOT contain user's object AND ALSO get savedPosts
                    if !users.contains(where: { $0.objectId! == (object.object(forKey: "byUser") as! PFUser).objectId!})
                        && difference.hour! < 24 {
                        if (object.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                            self.currentUserPost.append(object)
                        } else {
                            self.posts.append(object)
                        }
                        
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    if self.posts.count == 0 {
                        // MARK: - DZNEmptyDataSet
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        self.tableView.reloadEmptyDataSet()
                    } else {
                        self.tableView.reloadData()
                    }
                })

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.posts.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
//            str = "😛 STORIES\n\nPosts shared by people you follow would show up here..."
//            str = "💩 COLLECTIONS\n\nGroups of Posts shared by people you follow would show up here..."
        let font = UIFont(name: "AvenirNext-Demibold", size: 21)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!]
        return NSAttributedString(string: "💩 COLLECTIONS\n\nGroups of Posts shared by people you follow would show up here...", attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find Friends"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Push VC
        let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }

    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Stories"
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure View
        configureView()

        // Define Notification to reload data
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: homeNotification, object: nil)
        
        // Configure UITableView
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = 70
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView.tableFooterView = UIView()
        
        // UIRefreshControl - Pull to refresh
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refresher)
        
        // Fetch Following
        fetchFollowing()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Set UITabBarController Delegate
        self.tabBarController?.delegate = self
        // Configure UIStatusBar
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
    
    
    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if self.navigationController?.tabBarController?.selectedIndex == 0 {
            self.tableView?.setContentOffset(CGPoint.zero, animated: true)
        }
    }
    
    
    // MARK: - UITableView DataSource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        } else {
            return self.posts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        header.font = UIFont(name: "AvenirNext-Demibold", size: 15)
        header.textAlignment = .left
        header.backgroundColor = UIColor.white
        header.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        if section == 0 {
            header.text = "   My Story"
        } else if section == 1 {
            header.text = "   Updated Collections"
        } else {
            header.text = "   Recent Stories"
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44
        } else if section == 1 {
            return 44
        } else {
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
        // MY STORY
            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
            if !self.currentUserPost.isEmpty {
                cell.delegate = self                                                // Set parent UIViewController
                cell.postObject = self.currentUserPost.first!                        // Set PFObject
                cell.updateView(withObject: self.currentUserPost.first!)             // Update UI
                cell.addStoriesTap()                                                // Add storiesTap
            }
            return cell
            
        } else if indexPath.section == 1 {
        // COLLECTIONS
//            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
//            cell.delegate = self                                                // Set parent UIViewController
//            cell.postObject = self.posts[indexPath.row]                         // Set PFObject
//            cell.updateView(withObject: self.posts[indexPath.row])              // Update UI
//            cell.addStoriesTap()                                                // Add storiesTap
//            return cell
            
        } else {
        // RECENT UPDATES
            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
            cell.delegate = self                                                // Set parent UIViewController
            cell.postObject = self.posts[indexPath.row]                         // Set PFObject
            cell.updateView(withObject: self.posts[indexPath.row])              // Update UI
            cell.addStoriesTap()                                                // Add storiesTap
            return cell
        }
        

        let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
        return cell
    }
    
    // MARK: - UITableView Delegate Methods
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor.groupTableViewBackground
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor.white
    }
    
}
