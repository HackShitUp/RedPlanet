//
//  Activity.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

import Parse
import ParseUI
import Bolts

import CoreLocation
import DZNEmptyDataSet
import OneSignal
import SVProgressHUD
import SwipeNavigationController
import SDWebImage

class Activity: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, OSPermissionObserver, OSSubscriptionObserver {
    
    // DISCOVERIES - Array to hold new people to follow
    var discoveries = [PFObject]()
    // NOTIFICATIONS - Array to hold user's notifications < 24 hours
    var activityObjects = [PFObject]()
    // Skipped objects for content that's > 24 hours
    var skipped = [PFObject]()
    // Page size for pipeline method
    var page: Int = 50
    
    // CoreLocationManager
    let manager = CLLocationManager()
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var followRequestsButton: UIBarButtonItem!
    @IBAction func followRequestsAction(_ sender: Any) {
        // Push VC
        let followRequestsVC = self.storyboard?.instantiateViewController(withIdentifier: "followRequestsVC") as! FollowRequests
        self.navigationController?.pushViewController(followRequestsVC, animated: true)
    }

    @IBOutlet weak var contactsButton: UIBarButtonItem!
    @IBAction func contacts(_ sender: Any) {
        // Push VC
        let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }

    // Query Notifications
    func queryNotifications() {
        // Fetch your notifications
        let notifications = PFQuery(className: "Notifications")
        notifications.whereKey("toUser", equalTo: PFUser.current()!)
        notifications.whereKey("fromUser", notEqualTo: PFUser.current()!)
        notifications.includeKeys(["toUser", "fromUser"])
        notifications.order(byDescending: "createdAt")
        notifications.limit = self.page
        notifications.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.activityObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    
                    // Set time configs
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.activityObjects.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                // Fetch Discoveries
                self.fetchDiscoveries()
                
                // Set DZN
                if self.activityObjects.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            
            // Reload Data
            self.tableView!.reloadData()
        })
    }
    
    func fetchDiscoveries() {
        let publicAccounts = PFUser.query()!
        publicAccounts.whereKey("private", equalTo: false)
        
        let discoveries = PFUser.query()!
        discoveries.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
//        let both = PFQuery.orQuery(withSubqueries: [publicAccounts, discoveries])
        discoveries.order(byDescending: "createdAt")
        discoveries.includeKey("byUser")
        discoveries.limit = self.page
        discoveries.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.discoveries.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.discoveries.append(object)
                }
//                print("Counter: \(self.discoveries.count)\n")
                // Reload data
                self.tableView!.reloadData()
            } else {
                print(error?.localizedDescription as Any)
            }
        }
//        let both = PFQuery.orQuery(withSubqueries: [publicAccounts, discoveries])
//        both.order(byDescending: "createdAt")
//        both.includeKey("byUser")
//        both.limit = self.page
//        both.findObjectsInBackground {
//            (objects: [PFObject]?, error: Error?) in
//            if error == nil {
//                // Clear array
//                self.discoveries.removeAll(keepingCapacity: false)
//                for object in objects! {
//                    self.discoveries.append(object)
//                }
//                print("Counter: \(self.discoveries.count)\n")
//                // Reload data
//                self.tableView!.reloadData()
//            } else {
//                print(error?.localizedDescription as Any)
//            }
//        }
    }
    

    // MARK: - UITabBarControllerDelegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Scroll to top
        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    // Status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Activity"
        }
        // MARK: - UINavigationBar Extension
        // Configure UINavigationBar, and show UITabBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        // Show UIstatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // Refresh function
    func refresh() {
        // Query notifications
        queryNotifications()
        // End refresher
        self.refresher.endRefreshing()
        // Reload data
        self.tableView!.reloadData()
    }
    
    // MARK: - OneSignal
    /*
     Called when the user changes Notifications Access from "off" --> "on"
     REQUIRED
     */
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            print("Subscribed for OneSignal push notifications!")
            
            let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
            let userID = status.subscriptionStatus.userId
            print("THE userID = \(String(describing: userID))\n\n\n")
            
            // MARK: - Parse
            // Save user's apnsId to server
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userID
                PFUser.current()!.saveInBackground()
            }
        }
    }
    
    func onOSPermissionChanged(_ stateChanges: OSPermissionStateChanges!) {
        if stateChanges.from.status == .notDetermined || stateChanges.from.status == .denied {
            if stateChanges.to.status == .authorized {
                print("AUTHORIZED")
            }
        }
    }
    /**/

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        
        // Stylize title
        configureView()
        
        // Set initial query
        self.queryNotifications()
        
        // MARK: - OneSignal
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        if status.permissionStatus.status == .denied {
            // Show Alert
            let alert = UIAlertController(title: "Push Notifications Denied",
                                          message: "Please allow Redplanet to send Push Notifications so you can receive updates from the people you love!",
                                          preferredStyle: .alert)
            let settings = UIAlertAction(title: "Settings",
                                         style: .default,
                                         handler: { (alertAction: UIAlertAction!) in
                                            // Show Settings
                                            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            })
            let later = UIAlertAction(title: "Later",
                                      style: .default,
                                      handler: nil)
            alert.addAction(later)
            alert.addAction(settings)
            self.present(alert, animated: true, completion: nil)
            
        } else if CLLocationManager.authorizationStatus() == .denied {
            // Show Alert
            let alert = UIAlertController(title: "Location Access Denied",
                                          message: "Please allow Redplanet to access your Location so you can send cool geo-filters and help us find your friends better!",
                                          preferredStyle: .alert)
            let settings = UIAlertAction(title: "Settings",
                                         style: .default,
                                         handler: { (alertAction: UIAlertAction!) in
                                            // Show Settings
                                            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            })
            let later = UIAlertAction(title: "Later",
                                      style: .default,
                                      handler: nil)
            alert.addAction(later)
            alert.addAction(settings)
            self.present(alert, animated: true, completion: nil)
        }
        
        
        // Clean tableView
        self.tableView!.tableFooterView = UIView()
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Set tabBarController's delegate to self
        // to access menu via tabBar
        self.navigationController?.tabBarController?.delegate = self

        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        tableView!.addSubview(refresher)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Query notifications
        queryNotifications()
        // MARK: - NSBadge
        // Set badge for Relationship Requests...
        if myRequestedFollowers.count != 0 {
            followRequestsButton.badge(text: "\(myRequestedFollowers.count)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: DZNEmptyDataSet Framework
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if activityObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🦄\nYou have no new\nNotifications today."
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
        let str = "Share Something"
        let font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }

    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return activityObjects.count
        } else {
//            print("Count: \(self.discoveries.count)\n")
//            return self.discoveries.count
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        
        // Initialize and set parent vc
        cell.delegate = self
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Give Profile Photo Corner Radius
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        if indexPath.section == 0 {
            
            // Declare content's object
            // in Notifications' <forObjectId>
            cell.contentObject = activityObjects[indexPath.row]
            
            // (1) GET and set user's object
            if let user = self.activityObjects[indexPath.row].value(forKey: "fromUser") as? PFUser {
                
                // (1A) Set user's object
                cell.userObject = user
                
                // (1B) Set user's fullName
                cell.rpUsername.setTitle("\(user.value(forKey: "realNameOfUser") as! String)", for: .normal)
                
                // (1C) Get and user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
            }
            
            // (3) Set title of activity
            // START TITLE *****************************************************************************************************
        
            // -----------------------------------------------------------------------------------------------------------------
            // ==================== R E L A T I O N S H I P S ------------------------------------------------------------------
            // -----------------------------------------------------------------------------------------------------------------
            // (1) Follow Requested
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "follow requested" {
                cell.activity.setTitle("requested to follow you", for: .normal)
            }
            
            // (2) Followed
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "followed" {
                cell.activity.setTitle("started following you", for: .normal)
            }
            
            // -------------------------------------------------------------------------------------------------------------
            // ==================== S P A C E ------------------------------------------------------------------------------
            // -------------------------------------------------------------------------------------------------------------
            
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "space" {
                cell.activity.setTitle("wrote on your Space", for: .normal)
            }
            
            // --------------------------------------------------------------------------------------------------------------
            // ==================== L I K E ---------------------------------------------------------------------------------
            // --------------------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like tp" {
                cell.activity.setTitle("liked your Text Post", for: .normal)
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like ph" {
                cell.activity.setTitle("liked your Photo", for: .normal)
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like pp" {
                cell.activity.setTitle("liked your Profile Photo", for: .normal)
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like sp" {
                cell.activity.setTitle("liked your Space Post", for: .normal)
            }
            
            // (5) Shared
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like sh" {
                cell.activity.setTitle("liked your Shared Post", for: .normal)
            }
            
            // (6) Moment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like itm" {
                cell.activity.setTitle("liked your Moment", for: .normal)
            }
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like vi" {
                cell.activity.setTitle("liked your Video", for: .normal)
            }
            
            // (9)  Liked Comment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like co" {
                cell.activity.setTitle("liked your comment", for: .normal)
            }
            
            // ------------------------------------------------------------------------------------------------
            // ==================== T A G ---------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag tp" {
                cell.activity.setTitle("tagged you in a Text Post", for: .normal)
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag ph" {
                cell.activity.setTitle("tagged you in a Photo", for: .normal)
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag pp" {
                cell.activity.setTitle("tagged you in a Profile Photo", for: .normal)
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag sp" {
                cell.activity.setTitle("tagged you in a Space Post", for: .normal)
            }
            
            // (5) SKIP: Shared Post
            // (6) SKIP: Moment
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag vi" {
                cell.activity.setTitle("tagged you in a Video", for: .normal)
            }
            
            // (8) Comment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag co" {
                cell.activity.setTitle("tagged you in a comment", for: .normal)
            }

            // ------------------------------------------------------------------------------------------------------------
            // ==================== C O M M E N T -------------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------------------
            
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "comment" {
                cell.activity.setTitle("commented on your post", for: .normal)
            }
            
            // ------------------------------------------------------------------------------------------
            // ==================== S H A R E D ---------------------------------------------------------
            // ------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share tp" {
                cell.activity.setTitle("shared your Text Post", for: .normal)
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share ph" {
                cell.activity.setTitle("shared your Photo", for: .normal)
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share pp" {
                cell.activity.setTitle("shared your Profile Photo", for: .normal)
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share sp" {
                cell.activity.setTitle("shared your Space Post", for: .normal)
            }
            
            // (5) Share
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share sh" {
                cell.activity.setTitle("re-shared your Shared Post", for: .normal)
            }
            
            // (6) Moment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share itm" {
                cell.activity.setTitle("shared your Moment", for: .normal)
            }
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share vi" {
                cell.activity.setTitle("shared your Video", for: .normal)
            }
            
            // ===========================================================================================================
            // END TITLE =================================================================================================
            // ===========================================================================================================
            
            // (4) Set time
            let from = activityObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.time.text = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                cell.time.text = "\(difference.second!)s ago"
            } else if difference.minute! > 0 && difference.hour! == 0 {
                cell.time.text = "\(difference.minute!)m ago"
            } else if difference.hour! > 0 && difference.day! == 0 {
                cell.time.text = "\(difference.hour!)h ago"
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                cell.time.text = "\(difference.day!)d ago"
            } else if difference.weekOfMonth! > 0 {
                cell.time.text = "\(difference.weekOfMonth!)w ago"
            }

        } else {
           
            // Declare content's object
            // in Notifications' <forObjectId>
            cell.contentObject = self.discoveries[indexPath.row]
            
            // (1A) Set user's object
            cell.userObject = self.discoveries[indexPath.row]
            
            // (1B) Set user's fullName
            cell.rpUsername.setTitle("\(self.discoveries[indexPath.row].value(forKey: "realNameOfUser") as! String)", for: .normal)
            
            // (1C) Get and user's profile photo
            if let proPic = self.discoveries[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            // (2) Hide time
            cell.time.isHidden = true
            
            // (3) Set bio
            cell.activity.setTitle("\(self.discoveries[indexPath.row].value(forKey: "bio") as! String)", for: .normal)
        }
        
        
        return cell
    }

    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= activityObjects.count + self.skipped.count {
            
            // Increase page size to load more posts
            page = page + 50

            // Fetch Notifications
            queryNotifications()
        }
    }
    
    // ScrollView -- Pull To Pop
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            refresh()
        }
    }

}
