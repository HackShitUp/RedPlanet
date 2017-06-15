//
//  CurrentUser.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import OneSignal
import SDWebImage
import SwipeNavigationController

// Define identifier
let myProfileNotification = Notification.Name("myProfile")

/*
 UITableViewController class that presents the current user's profile. Used with "CurrentUserHeader.swift"
 The UITableViewCells in this class, are referenced to "StoryCell.swift" in the NIBS/XIBS folder and "ActivityCell.swift" and 
 its respective UITableViewCell in Storyboard.
 
 The following is presented in the user's profile:
 • Notifications - Activity.
 • Today - Today's posts.
 • Saved - Saved posts.
 
 This class presents "Story.swift" if a UITableViewCell in "Saved Posts" were tapped. This class also presents "Stories.swift" if a
 UITableViewCell was tapped for "Today". If a UITableViewCell in "Notifications" was tapped, the it might show "Story.swift", 
 "FollowRequests.swift" or "OtherUser.swift"

 Works with "RPPopUpVC.swift" to present any of the other classes necesary.
 */

class CurrentUser: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate, TwicketSegmentedControlDelegate, OSPermissionObserver, OSSubscriptionObserver, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Variable to hold my content
    var relativeObjects = [PFObject]()
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    // MARK: - TwicketSegmentedControl
    let segmentedControl = TwicketSegmentedControl()
    // Initialize limit; Pipeline method
    var page: Int = 100
    // Initialize UIRefreshControl
    var refresher: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var peopleButton: UIBarButtonItem!
    @IBAction func showRequests(_ sender: Any) {
        let followRequestsVC = self.storyboard?.instantiateViewController(withIdentifier: "followRequestsVC") as! FollowRequests
        self.navigationController?.pushViewController(followRequestsVC, animated: true)
    }
    
    @IBAction func settings(_ sender: Any) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! UserSettings
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    
    // Function to handle new follow requests
    func handleRequests() {
        // Query Relationships
        _ = appDelegate.queryRelationships()
        
        // MARK: - NSBadge; set badge for follow requests
        if currentRequestedFollowers.count != 0 {
            peopleButton.badge(text: "\(currentRequestedFollowers.count)")
        }
        
        // MARK: - MasterUI; reset UITabBar badge value and peopleButton badge with new follow requests
        let masterUI = MasterUI()
        masterUI.getNewRequests { (count) in
            // Set UITabBar badge icon
            if count != 0 {
                if #available(iOS 10.0, *) {
                    self.navigationController?.tabBarController?.tabBar.items?[4].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                }
                self.navigationController?.tabBarController?.tabBar.items?[4].badgeValue = "\(count)"
            } else {
                self.navigationController?.tabBarController?.tabBar.items?[4].badgeValue = nil
            }
        }
    }

    // Handle segmentedControl query
    func handleCase() {
        // Update UI by ending UIRefreshControl and configuring UITableView
        self.refresher?.endRefreshing()
        self.tableView.allowsSelection = true
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchNotifications()
            self.tableView.allowsSelection = false
        case 1:
            fetchToday()
            self.tableView.allowsSelection = false
        case 2:
            fetchSaved()
            self.tableView.allowsSelection = true
        default:
            break;
        }
    }
    
    // FUNCTION - Fetch today's posts
    func fetchToday() {
        // User's Posts
        let byUser = PFQuery(className: "Posts")
        byUser.whereKey("byUser", equalTo: PFUser.current()!)
        // User's Space Posts
        let toUser = PFQuery(className:  "Posts")
        toUser.whereKey("toUser", equalTo: PFUser.current()!)
        // Both
        let postsClass = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        postsClass.includeKeys(["byUser", "toUser"])
        postsClass.order(byDescending: "createdAt")
        postsClass.limit = self.page
        postsClass.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.relativeObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.relativeObjects.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }

                // Reload data in main thread
                DispatchQueue.main.async {
                    if self.relativeObjects.count == 0 {
                        // MARK: - DZNEmptyDataSet
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        self.tableView.reloadEmptyDataSet()
                    }
                    self.tableView?.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    
    // FUNCTION: Fetch saved posts
    func fetchSaved() {
        let saved = PFQuery(className: "Posts")
        saved.whereKey("byUser", equalTo: PFUser.current()!)
        saved.whereKey("saved", equalTo: true)
        saved.includeKeys(["byUser", "toUser"])
        saved.order(byDescending: "createdAt")
        saved.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // clear array
                self.relativeObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.relativeObjects.append(object)
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    if self.relativeObjects.count == 0 {
                        // MARK: - DZNEmptyDataSet
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        self.tableView.reloadEmptyDataSet()
                    }
                    self.tableView?.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FUNCTION: Fetch Notifications
    func fetchNotifications() {
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
                // Clear arrays
                self.relativeObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                // Append objects
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.relativeObjects.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    if self.relativeObjects.count == 0 {
                        // MARK: - DZNEmptyDataSet
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        self.tableView.reloadEmptyDataSet()
                    }
                    self.tableView?.reloadData()
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            }
        })
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = PFUser.current()!.username!.lowercased()
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // Function to check for permissions
    func checkPermissions() {
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
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
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
                button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.setTitle("LATER", for: [])
                return true
            }
            
            dialogController.show(in: self)
            
            
            
        } else if CLLocationManager.authorizationStatus() == .denied {
            
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Location Access Denied",
                                                          message: "Please enable Location access so you can share Moments with geo-filters and help us find your friends better!")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
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
                button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.setTitle("LATER", for: [])
                return true
            }
            dialogController.show(in: self)
        }
    }
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.relativeObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        if self.segmentedControl.selectedSegmentIndex == 0 {
            str = "💩 No Activity Today."
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            str = "💩 No Posts Today."
        } else {
            str = "💩 No Saved Posts."
        }
        let font = UIFont(name: "AvenirNext-Demibold", size: 12)
        let attributeDictionary: [String: AnyObject]? = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: font!]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Launch Camera"
        let font = UIFont(name: "AvenirNext-Bold", size: 12)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        /*
         THE UITableView SHOULD ONLY RELOAD ONCE OR ELSE THIS WILL CAUSE THE APP TO CRASH
         THIS IS BECAUSE RELOADING THE UITableView resets the frame of the views...
         */
        return self.tableView!.headerView(forSection: 0)!.frame.size.height/2
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 3
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    
    // MARK: - TwicketSegmentedControl Delegate Method
    func didSelect(_ segmentIndex: Int) {
        handleCase()
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
    

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize bar
        configureView()
        // Handle Follow Requests
        handleRequests()
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title
        configureView()
        // Show UITaBBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isTranslucent = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch data
        handleCase()
        // Stylize and set title
        configureView()
        // Check for permissions
        checkPermissions()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(fetchToday), name: myProfileNotification, object: nil)
        
        // MARK: - TwicketSegmentedControl
        segmentedControl.delegate = self
        segmentedControl.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 16, height: 40)
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["Notifications", "Today", "Saved"])
        segmentedControl.defaultTextColor = UIColor.black
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Demibold", size: 12)!
        
        // Configure UITableview
        tableView.backgroundColor = UIColor.white
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = 75
        tableView.separatorColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        tableView.estimatedSectionHeaderHeight = 425
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        // Register NIB
        tableView.register(UINib(nibName: "CurrentUserHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "CurrentUserHeader")
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(handleCase), for: .valueChanged)
        tableView.addSubview(refresher)
        
        // Set UITabBarController Delegate
        self.navigationController?.tabBarController?.delegate = self
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
        self.tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    // MARK: - UITableView Data Source Methods
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CurrentUserHeader") as! CurrentUserHeader
        
        // MARK: - TwicketSegmentedControl; Add segmentedControl to header's segmentView
        header.segmentView.addSubview(self.segmentedControl)
        
        // QueryRelationships via AppDelegate
        appDelegate.queryRelationships()
        
        // Set delegate
        header.delegate = self
        // Configure frame
        header.frame = header.frame
        
        // (1) Get User's Profile Photo
        if let myProfilePhoto = PFUser.current()!["userProfilePicture"] as? PFFile {
            // MARK: - SDWebImage
            header.myProPic.sd_setImage(with: URL(string: myProfilePhoto.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            // MARK: - RPExtensions
            header.myProPic.makeCircular(forView: header.myProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        }
        // (2) Set current user's realNameOfUser
        if let realNameOfUser = PFUser.current()!.value(forKey: "realNameOfUser") as? String {
            header.fullName.text = realNameOfUser
            // Underline fullname
            let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
            let underlineAttributedString = NSAttributedString(string: "\(header.fullName.text!)", attributes: underlineAttribute)
            header.fullName.attributedText = underlineAttributedString
        }
        
        // (3) Set current user's biography
        if let userBiography = PFUser.current()!.value(forKey: "userBiography") as? String {
            header.userBio.text = userBiography
        }
        
        // (4) Set count for posts, followers, and following
        let posts = PFQuery(className: "Posts")
        posts.whereKey("byUser", equalTo: PFUser.current()!)
        posts.countObjectsInBackground {
            (count: Int32, error: Error?) in
            if error == nil {
                if count == 1 {
                    header.numberOfPosts.setTitle("1\npost", for: .normal)
                } else {
                    header.numberOfPosts.setTitle("\(count)\nposts", for: .normal)
                }
            } else {
                print(error?.localizedDescription as Any)
                header.numberOfPosts.setTitle("posts", for: .normal)
            }
        }
        // Count Followers
        if currentFollowers.count == 0 {
            header.numberOfFollowers.setTitle("\nfollowers", for: .normal)
        } else if currentFollowers.count == 0 {
            header.numberOfFollowers.setTitle("1\nfollower", for: .normal)
        } else {
            header.numberOfFollowers.setTitle("\(currentFollowers.count)\nfollowers", for: .normal)
        }
        
        // Count Following
        if currentFollowing.count == 0 {
            header.numberOfFollowing.setTitle("\nfollowing", for: .normal)
        } else if currentFollowing.count == 1 {
            header.numberOfFollowing.setTitle("1\nfollowing", for: .normal)
        } else {
            header.numberOfFollowing.setTitle("\(currentFollowing.count)\nfollowing", for: .normal)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let label: UILabel = UILabel(frame: CGRect(x: 8, y: 334, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17)
        if let userBiography = PFUser.current()!.value(forKey: "userBiography") as? String {
            label.text = userBiography
        }
        label.sizeToFit()
        return CGFloat(425 + label.frame.size.height)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.relativeObjects.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // TODAY'S POSTS
        if self.segmentedControl.selectedSegmentIndex == 2 {
            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
            
            cell.delegate = self                                                // Set parent UIViewController
            cell.postObject = self.relativeObjects[indexPath.row]               // Set PFObject
            cell.updateView(withObject: self.relativeObjects[indexPath.row])    // Update UI
            cell.addStoryTap()                                                  // Add storyTap
            
            return cell
            
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
        // SAVED POSTS

            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
            
            cell.delegate = self                                                // Set parent UIViewController
            cell.postObject = self.relativeObjects[indexPath.row]               // Set PFObject
            cell.updateView(withObject: self.relativeObjects[indexPath.row])    // Update UI
            cell.addStoriesTap()                                                // Add storiesTap
            
            return cell
            
            
        } else {
        // ACTIVITY
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
            
            // Initialize and set parent vc
            cell.delegate = self
            
            // Declare content's object
            // in Notifications' <forObjectId>
            cell.contentObject = relativeObjects[indexPath.row]
            
            // (1) GET and set user's object
            if let user = self.relativeObjects[indexPath.row].value(forKey: "fromUser") as? PFUser {
                // (1A) Set user's object
                cell.userObject = user
                // (1B) Set user's fullName
                cell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // (1C) Get and user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPHelpers extension
                    cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (2) Show time
            cell.time.isHidden = false
            
            // (3) Set title of activity
            // START TITLE *****************************************************************************************************
            if let type = relativeObjects[indexPath.row].value(forKey: "type") as? String {
                switch type {
                    // -------------------------------------------------------------------------------------------
                    // =======F O L L O W    R E Q U E S T S -----------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "follow requested":
                    cell.activity.text = "requested to follow you"
                    case "followed":
                    cell.activity.text = "started following you"
                    // -------------------------------------------------------------------------------------------
                    // ==================== S P A C E ------------------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "space":
                    cell.activity.text = "wrote on your Space"
                    // -------------------------------------------------------------------------------------------
                    // ==================== L I K E --------------------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "like tp":
                    cell.activity.text = "liked your Text Post"
                    case "like ph":
                    cell.activity.text = "liked your Photo"
                    case "like pp":
                    cell.activity.text = "liked your Profile Photo"
                    case "like sp":
                    cell.activity.text = "liked your Space Post"
                    case "like vi":
                    cell.activity.text = "liked your Video"
                    case "like itm":
                    cell.activity.text = "liked your Moment"
                    case "like co":
                    cell.activity.text = "liked your comment"
                    // -------------------------------------------------------------------------------------------
                    // ==================== T A G ----------------------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "tag tp":
                    cell.activity.text = "tagged you in a Text Post"
                    case "tag ph":
                    cell.activity.text = "tagged you in a Photo"
                    case "tag pp":
                    cell.activity.text = "tagged you in a Profile Photo"
                    case "tag sp":
                    cell.activity.text = "tagged you in a Space Post"
                    case "tag vi":
                    cell.activity.text = "tagged you in a Video"
                    case "tag itm":
                    cell.activity.text = "tagged you in a Moment"
                    case "tag co":
                    cell.activity.text = "tagged you in a comment"
                    // -------------------------------------------------------------------------------------------
                    // ==================== C O M M E N T --------------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "comment":
                    cell.activity.text = "commented on your post"
                    // -------------------------------------------------------------------------------------------
                    // ================= S C R E E N S H O T -----------------------------------------------------
                    // -------------------------------------------------------------------------------------------
                    case "screenshot":
                    cell.activity.text = "screenshot your post"
                default:
                    break;
                }
            }
            // ===========================================================================================================
            // END TITLE =================================================================================================
            // ===========================================================================================================
            
            // (4) Set time
            let from = relativeObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPHelpers
            cell.time.text = difference.getShortTime(difference: difference, date: from)
            
            
            return cell
        }
    }
 
    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView!.cellForRow(at: indexPath)?.backgroundColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
    }

    
    // MARK: - UIScrollView Delegate Method
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.relativeObjects.count + self.skipped.count {
                // Increase page size to load more posts
                page = page + 50
                // Query content
                handleCase()
            }
        }
        */
    }
}
