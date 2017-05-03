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
import SwipeNavigationController
import SDWebImage

class Activity: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, OSPermissionObserver, OSSubscriptionObserver {
    
    // DISCOVER - Array to hold new people to follow
    var discoverObjects = [PFObject]()
    
    // ACTIVITY - Array to hold user's notifications < 24 hours
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

    // Fetch Activity
    func fetchActivity() {
        // Fetch Current User's Notifications
        let notifications = PFQuery(className: "Notifications")
        notifications.whereKey("toUser", equalTo: PFUser.current()!)
        notifications.whereKey("fromUser", notEqualTo: PFUser.current()!)
        notifications.includeKeys(["toUser", "fromUser"])
        notifications.order(byDescending: "createdAt")
        notifications.limit = self.page
        notifications.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.activityObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.activityObjects.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                // Set DZN
                if self.activityObjects.count == 0 {
                    // Fetch Discover objects when there are NO notifications!
                    self.fetchDiscover()
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            }
            
            // Reload Data
            self.tableView!.reloadData()
        })
    }
    
    // Discover
    func fetchDiscover() {
        // MARK: - AppDelegate
        appDelegate.queryRelationships()
        let publicAccounts = PFUser.query()!
        publicAccounts.whereKey("proPicExists", equalTo: true)
        publicAccounts.whereKey("private", equalTo: false)
        publicAccounts.order(byAscending: "createdAt")
        publicAccounts.limit = self.page
        publicAccounts.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.discoverObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId! == object.objectId!}) {
                        self.discoverObjects.append(object)
                    }
                }
                
                // Reload data
                self.tableView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
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
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        // Show UIstatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // Refresh function
    func refresh() {
        // Fetch Activity
        fetchActivity()
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
        self.fetchActivity()
        
        // MARK: - OneSignal
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        if status.permissionStatus.status == .denied {

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Push Notifications Denied",
                                                          message: "Please allow Redplanet to send Push Notifications so you can receive updates from the people you love!")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.layer.masksToBounds = true
            }
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // Show Settings
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            
            // Cancel
            dialogController.cancelButtonStyle = { (button,height) in
                button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.setTitle("LATER", for: [])
                return true
            }
            
            dialogController.show(in: self)
            
            
            
        } else if CLLocationManager.authorizationStatus() == .denied {

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Location Access Denied",
                                                          message: "Please allow Redplanet to access your Location so you can send cool geo-filters and help us find your friends better!")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.layer.masksToBounds = true
            }
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // Show Settings
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            
            // Cancel
            dialogController.cancelButtonStyle = { (button,height) in
                button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.setTitle("LATER", for: [])
                return true
            }
            
            dialogController.show(in: self)
        }
    
        
        // Configure UITableView
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        self.tableView!.tableFooterView = UIView()
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.rowHeight = 60.00
        
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
        // MARK: - NSBadge
        // Set badge for Relationship Requests...
        if myRequestedFollowers.count != 0 {
            followRequestsButton.badge(text: "\(myRequestedFollowers.count)")
        }
        // Query notifications
        fetchActivity()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if activityObjects.count == 0 || discoverObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nNo New\nNotifications today."
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "AvenirNext-Bold", size: 12.00)
        label.textColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        label.textAlignment = .left
        if self.activityObjects.count != 0 {
            label.text = "      TODAY'S ACTIVITY"
        } else {
            label.text = "      DISCOVER"
        }
        return label
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.activityObjects.count != 0 {
            return self.activityObjects.count
        } else {
            return self.discoverObjects.count
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        
        // Initialize and set parent vc
        cell.delegate = self

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        if self.activityObjects.count != 0 {
            
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
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
            }
            
            // (2) Show time
            cell.time.isHidden = false
            
            // (3) Set title of activity
            // START TITLE *****************************************************************************************************
        
            // -----------------------------------------------------------------------------------------------------------------
            // ==================== R E L A T I O N S H I P S ------------------------------------------------------------------
            // -----------------------------------------------------------------------------------------------------------------
            // (1) Follow Requested
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "follow requested" {
                cell.activity.text = "requested to follow you"
            }
            
            // (2) Followed
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "followed" {
                cell.activity.text = "started following you"
            }
            
            // -------------------------------------------------------------------------------------------------------------
            // ==================== S P A C E ------------------------------------------------------------------------------
            // -------------------------------------------------------------------------------------------------------------
            
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "space" {
                cell.activity.text = "wrote on your Space"
            }
            
            // --------------------------------------------------------------------------------------------------------------
            // ==================== L I K E ---------------------------------------------------------------------------------
            // --------------------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like tp" {
                cell.activity.text = "liked your Text Post"
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like ph" {
                cell.activity.text = "liked your Photo"
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like pp" {
                cell.activity.text = "liked your Profile Photo"
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like sp" {
                cell.activity.text = "liked your Space Post"
            }
            
            // (5) Shared
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like sh" {
                cell.activity.text = "liked your Shared Post"
            }
            
            // (6) Moment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like itm" {
                cell.activity.text = "liked your Moment"
            }
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like vi" {
                cell.activity.text = "liked your Video"
            }
            
            // (9)  Liked Comment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "like co" {
                cell.activity.text = "liked your comment"
            }
            
            // ------------------------------------------------------------------------------------------------
            // ==================== T A G ---------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag tp" {
                cell.activity.text = "tagged you in a Text Post"
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag ph" {
                cell.activity.text = "tagged you in a Photo"
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag pp" {
                cell.activity.text = "tagged you in a Profile Photo"
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag sp" {
                cell.activity.text = "tagged you in a Space Post"
            }
            
            // (5) SKIP: Shared Post
            // (6) SKIP: Moment
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag vi" {
                cell.activity.text = "tagged you in a Video"
            }
            
            // (8) Comment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "tag co" {
                cell.activity.text = "tagged you in a comment"
            }

            // ------------------------------------------------------------------------------------------------------------
            // ==================== C O M M E N T -------------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------------------
            
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "comment" {
                cell.activity.text = "commented on your post"
            }
            
            // ------------------------------------------------------------------------------------------
            // ==================== S H A R E D ---------------------------------------------------------
            // ------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share tp" {
                cell.activity.text = "shared your Text Post"
            }
            
            // (2) Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share ph" {
                cell.activity.text = "shared your Photo"
            }
            
            // (3) Profile Photo
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share pp" {
                cell.activity.text = "shared your Profile Photo"
            }
            
            // (4) Space Post
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share sp" {
                cell.activity.text = "shared your Space Post"
            }
            
            // (5) Share
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share sh" {
                cell.activity.text = "re-shared your Shared Post"
            }
            
            // (6) Moment
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share itm" {
                cell.activity.text = "shared your Moment"
            }
            
            // (7) Video
            if activityObjects[indexPath.row].value(forKey: "type") as! String == "share vi" {
                cell.activity.text = "shared your Video"
            }
            
            // ===========================================================================================================
            // END TITLE =================================================================================================
            // ===========================================================================================================
            
            // (4) Set time
            let from = activityObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPHelpers
            cell.time.text = difference.getShortTime(difference: difference, date: from)

        } else {
           
            // Declare content's object
            // in Notifications' <forObjectId>
            cell.contentObject = self.discoverObjects[indexPath.row]
            
            // (1A) Set user's object
            cell.userObject = self.discoverObjects[indexPath.row]
            
            // (1B) Set user's fullName
            cell.rpUsername.setTitle("\(self.discoverObjects[indexPath.row].value(forKey: "realNameOfUser") as! String)", for: .normal)
            
            // (1C) Get and user's profile photo
            if let proPic = self.discoverObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (2) Hide time
            cell.time.isHidden = true
            
            // (3) Set username
            cell.activity.text = "\(self.discoverObjects[indexPath.row].value(forKey: "username") as! String)"
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            // Append objects
            otherObject.append(self.discoverObjects[indexPath.row])
            otherName.append(self.discoverObjects[indexPath.row].value(forKey: "username") as! String)
            // Push VC
            let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherVC, animated: true)
        }
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

            // Fetch Activity
            fetchActivity()
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
