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

class Home: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, TwicketSegmentedControlDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate Constant
    let appDelegate = AppDelegate()
    
    // Array to hold friends (MUTUAL FOLLOWING)
    var friends = [PFObject]()
    // Array to hold following
    var following = [PFObject]()
    // Array to hold posts/skipped
    var posts = [PFObject]()
    var skipped = [PFObject]()
    
    // PFQuery Limit - Pipeline method
    var page: Int = 50
    
    // UIRefreshControl
    var refresher: UIRefreshControl!
    
    // MARK: - TwicketSegmentedControl
    var segmentedControl: TwicketSegmentedControl!
    
    // Function to refresh data
    func refresh() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchFriends()
        case 1:
            fetchFollowing()
        default:
            break
        }
        self.refresher.endRefreshing()
    }
    
    // QUERY: FRIENDS (MUTUAL)
    func fetchFriends() {
        // MARK: - AppDelegate
        _ = appDelegate.queryRelationships()
        
        // Fetch Friends
        let mutuals = PFQuery(className: "FollowMe")
        mutuals.includeKeys(["follower", "following"])
        mutuals.whereKey("following", equalTo: PFUser.current()!)
        mutuals.whereKey("isFollowing", equalTo: true)
        mutuals.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.friends.removeAll(keepingCapacity: false)
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if currentFollowing.contains(where: {$0.objectId! == (object.object(forKey: "follower") as! PFUser).objectId!}) {
                        self.friends.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
                self.fetchFirstPosts(forGroup: self.friends)
                
            } else {
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    // QUERY: FOLLOWING
    func fetchFollowing() {
        // MARK: - AppDelegate
        _ = appDelegate.queryRelationships()
        
        let following = PFQuery(className: "FollowMe")
        following.includeKeys(["follower", "following"])
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !currentFollowers.contains(where: {$0.objectId! == (object.object(forKey: "following") as! PFUser).objectId!}) {
                        self.following.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
                self.fetchFirstPosts(forGroup: self.following)
                
            } else {
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FETCH POSTS
    func fetchFirstPosts(forGroup: [PFObject]) {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: forGroup)
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.posts.removeAll(keepingCapacity: false)
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
                        self.posts.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                
                if self.posts.count == 0 {
                    // MARK: - DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                } else {
                    // Reload data in main thread
                    DispatchQueue.main.async {
                        self.tableView?.reloadData()
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    
    
    // MARK: - TwicketSegmentedControl
    func didSelect(_ segmentIndex: Int) {
        if segmentIndex == 0 {
            fetchFriends() // Fetch Friends' Stories
        } else if segmentIndex == 1 {
            fetchFollowing() // Fetch Following's Stories
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
        var str: String?
        if self.segmentedControl.selectedSegmentIndex == 0 {
            str = "💩\nYour Friends'\nFeed Is Empty Today."
        } else {
            str = "💩\nYour Following\nFeed Is Empty Today."
        }
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find Friends"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Push VC
        let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }

    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch Friends' or Following's Stories depending on index
        if segmentedControl.selectedSegmentIndex == 0 {
            fetchFriends()
        } else {
            fetchFollowing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - TwicketSegmentedControl
        let frame = CGRect(x: 5, y: view.frame.height / 2 - 20, width: view.frame.width - 10, height: 40)
        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.delegate = self
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["FRIENDS", "FOLLOWING"])
        segmentedControl.defaultTextColor = UIColor.black
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0.00, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Bold", size: 12)!
        self.navigationController?.navigationBar.topItem?.titleView = segmentedControl
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Define Notification to reload data
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: homeNotification, object: nil)
        
        // Set UITabBarController Delegate
        self.tabBarController?.delegate = self
        
        // Configure UITableView
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = 70
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView.tableFooterView = UIView()
        
        // UIRefreshControl - Pull to refresh
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refresher)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            DispatchQueue.main.async {
                self.tableView!.setContentOffset(CGPoint.zero, animated: true)
            }
        }
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
        
        cell.delegate = self                                                // Set parent UIViewController
        cell.postObject = self.posts[indexPath.row]                         // Set PFObject
        cell.updateView(withObject: self.posts[indexPath.row])              // Update UI
        cell.addStoriesTap()                                                // Add storiesTap
        
        return cell
    }
    
    // MARK: - UITableView Delegate Methods
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.95, alpha: 1)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor.white
    }
    
}
