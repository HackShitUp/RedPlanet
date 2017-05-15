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
    var page: Int = 50
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
        
        // MARK: - MasterUI; reset UITabBar badge value and peopleButton badge
        let masterUI = MasterUI()
        masterUI.getNewRequests()
    }

    // Handle segmentedControl query
    func handleCase() {
        // Update UI by ending UIRefreshControl
        self.refresher?.endRefreshing()
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchActivity()
        case 1:
            fetchToday()
        case 2:
            fetchSaved()
        default:
            break;
        }
    }
    
    // Function to fetch my content
    func fetchToday() {
        // User's Posts
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: PFUser.current()!)
        // User's Space Posts
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: PFUser.current()!)
        // Both
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.limit = self.page
        newsfeeds.findObjectsInBackground {
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
                
                // MARK: - DZNEmptyDataSet
                if self.relativeObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    // Function to fetch saved posts
    func fetchSaved() {
        let saved = PFQuery(className: "Newsfeeds")
        saved.whereKey("byUser", equalTo: PFUser.current()!)
        saved.whereKey("saved", equalTo: true)
        saved.includeKeys(["byUser", "toUser", "pointObject"])
        saved.order(byDescending: "createdAt")
        saved.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // clear array
                self.relativeObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.relativeObjects.append(object)
                }
                
                // MARK: - DZNEmptyDataSet
                if self.relativeObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // Function to fetch notifications
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
                
                // MARK: - DZNEmptyDataSet
                if self.relativeObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
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
            str = "No Saved Posts."
        }
        let font = UIFont(name: "AvenirNext-Medium", size: 15)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Launch Camera"
        let font = UIFont(name: "AvenirNext-Bold", size: 12)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
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
        // MARK: - RPHelpers; hide rpButton
        rpButton.isHidden = false
        // Set UITabBar isTranslucent boolean
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
        segmentedControl.setSegmentItems(["Actvitiy", "Today", "Saved"])
        segmentedControl.defaultTextColor = UIColor.black
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Demibold", size: 13.5)!
        
        // Configure UITableview
        tableView.backgroundColor = UIColor.white
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = 75
        tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        tableView.tableFooterView = UIView()
        // Register NIB
        tableView.register(UINib(nibName: "CurrentUserHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "CurrentUserHeader")
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
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
        
        // (2) Set user's bio and information
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            header.fullName.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            header.fullName.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
        }
        // Underline fullname
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "\(header.fullName.text!)", attributes: underlineAttribute)
        header.fullName.attributedText = underlineAttributedString
        
        // (3) Set count for posts, followers, and following
        let posts = PFQuery(className: "Newsfeeds")
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
        let label: UILabel = UILabel(frame: CGRect(x: 8, y: 313, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if let bio = PFUser.current()!.value(forKey: "userBiography") as? String {
            // Set fullname and bio
            label.text = "\((PFUser.current()!.value(forKey: "realNameOfUser") as! String).uppercased())\n\(bio)"
        } else {
            // set fullName
            label.text = (PFUser.current()!.value(forKey: "realNameOfUser") as! String)
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
        
        // TODAY'S POST
        if self.segmentedControl.selectedSegmentIndex == 1 || self.segmentedControl.selectedSegmentIndex == 2 {
            let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
            
            // Set delegate
            cell.delegate = self
            // Set PFObject
            cell.postObject = self.relativeObjects[indexPath.row]
            
            // (1) Get User's Object
            if let user = self.relativeObjects[indexPath.row].value(forKey: "byUser") as? PFUser {
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - RPHelpers extension
                    cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (2) Set rpUsername
                if let fullName = user.value(forKey: "realNameOfUser") as? String{
                    cell.rpUsername.text = fullName
                }
            }
            
            // (3) Set time
            let from = self.relativeObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPExtensions
            cell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (4) Set mediaPreview or textPreview
            cell.textPreview.isHidden = true
            cell.mediaPreview.isHidden = true
            
            if self.relativeObjects[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                cell.textPreview.text = "\(self.relativeObjects[indexPath.row].value(forKey: "textPost") as! String)"
                cell.textPreview.isHidden = false
            } else if self.relativeObjects[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                cell.mediaPreview.image = UIImage(named: "CSpacePost")
                cell.mediaPreview.isHidden = false
            } else {
                if let photo = self.relativeObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // MARK: - SDWebImage
                    cell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
                } else if let video = self.relativeObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // MARK: - AVPlayer
                    let player = AVPlayer(url: URL(string: video.url!)!)
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.frame = cell.mediaPreview.bounds
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    cell.mediaPreview.contentMode = .scaleAspectFit
                    cell.mediaPreview.layer.addSublayer(playerLayer)
                    player.isMuted = true
                    player.play()
                }
                cell.mediaPreview.isHidden = false
            }
            // MARK: - RPHelpers
            cell.textPreview.roundAllCorners(sender: cell.textPreview)
            cell.mediaPreview.roundAllCorners(sender: cell.mediaPreview)
            
            return cell
            
        } else {
        // ACTIVITY
            let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
            
            // Initialize and set parent vc
            cell.delegate = self
            
            // MARK: - RPHelpers extension
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
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
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "follow requested" {
                cell.activity.text = "requested to follow you"
            }
            
            // (2) Followed
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "followed" {
                cell.activity.text = "started following you"
            }
            
            // -------------------------------------------------------------------------------------------------------------
            // ==================== S P A C E ------------------------------------------------------------------------------
            // -------------------------------------------------------------------------------------------------------------
            
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "space" {
                cell.activity.text = "wrote on your Space"
            }
            
            // --------------------------------------------------------------------------------------------------------------
            // ==================== L I K E ---------------------------------------------------------------------------------
            // --------------------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like tp" {
                cell.activity.text = "liked your Text Post"
            }
            
            // (2) Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like ph" {
                cell.activity.text = "liked your Photo"
            }
            
            // (3) Profile Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like pp" {
                cell.activity.text = "liked your Profile Photo"
            }
            
            // (4) Space Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like sp" {
                cell.activity.text = "liked your Space Post"
            }
            
            // (5) Shared
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like sh" {
                cell.activity.text = "liked your Shared Post"
            }
            
            // (6) Moment
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like itm" {
                cell.activity.text = "liked your Moment"
            }
            
            // (7) Video
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like vi" {
                cell.activity.text = "liked your Video"
            }
            
            // (9)  Liked Comment
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "like co" {
                cell.activity.text = "liked your comment"
            }
            
            // ------------------------------------------------------------------------------------------------
            // ==================== T A G ---------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag tp" {
                cell.activity.text = "tagged you in a Text Post"
            }
            
            // (2) Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag ph" {
                cell.activity.text = "tagged you in a Photo"
            }
            
            // (3) Profile Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag pp" {
                cell.activity.text = "tagged you in a Profile Photo"
            }
            
            // (4) Space Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag sp" {
                cell.activity.text = "tagged you in a Space Post"
            }
            
            // (5) SKIP: Shared Post
            // (6) SKIP: Moment
            
            // (7) Video
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag vi" {
                cell.activity.text = "tagged you in a Video"
            }
            
            // (8) Comment
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "tag co" {
                cell.activity.text = "tagged you in a comment"
            }
            
            // -------------------------------------------------------------------------------------------
            // ==================== C O M M E N T --------------------------------------------------------
            // -------------------------------------------------------------------------------------------
            
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "comment" {
                cell.activity.text = "commented on your post"
            }
            
            // ------------------------------------------------------------------------------------------
            // ==================== S H A R E D ---------------------------------------------------------
            // ------------------------------------------------------------------------------------------
            
            // (1) Text Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share tp" {
                cell.activity.text = "shared your Text Post"
            }
            
            // (2) Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share ph" {
                cell.activity.text = "shared your Photo"
            }
            
            // (3) Profile Photo
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share pp" {
                cell.activity.text = "shared your Profile Photo"
            }
            
            // (4) Space Post
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share sp" {
                cell.activity.text = "shared your Space Post"
            }
            
            // (5) Moment
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share itm" {
                cell.activity.text = "shared your Moment"
            }
            
            // (6) Video
            if relativeObjects[indexPath.row].value(forKey: "type") as! String == "share vi" {
                cell.activity.text = "shared your Video"
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
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.relativeObjects.count + self.skipped.count {
                // Increase page size to load more posts
                page = page + 50
                // Query content
                handleCase()
            }
        }
    }

}
