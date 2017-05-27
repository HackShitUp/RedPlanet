//
//  OtherUser.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/31/17.
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
import SDWebImage

// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()

// Define Notification identifier
let otherNotification = Notification.Name("otherUser")

class OtherUser: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TwicketSegmentedControlDelegate {
    
    // App Delegate
    let appDelegate = AppDelegate()
    
    // OtherUser's content: posts, savedPosts, and skipped
    var relativePosts = [PFObject]()
    var skipped = [PFObject]()
    
    // Initialize UIRefreshControl
    var refresher: UIRefreshControl!
    // PFQuery limit --> Pipeline Method
    var page: Int = 50
    
    // Used for DZNEmtpyDataSet
    var dznType: String? = ""
    // MARK: - TwicketSegmentedControl
    let segmentedControl = TwicketSegmentedControl()
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        otherObject.removeLast()
        otherName.removeLast()
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func moreAction(_ sender: Any) {
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)",
                                                      message: "Options")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Image
        dialogController.imageHandler = { (imageView) in
            if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        imageView.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else {
                imageView.image = UIImage(named: "GenderNeutralUser")
            }
            imageView.contentMode = .scaleAspectFill
            return true //must return true, otherwise image won't show.
        }
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        // (1) SPACE POST
        let space = AZDialogAction(title: "Share in Space", handler: { (dialog) -> (Void) in
            // Show Space
            self.createSpace()
            // Dismiss
            dialog.dismiss()
        })
        
        // (2) CHAT
        let chat = AZDialogAction(title: "Chat", handler: { (dialog) -> (Void) in
            // Show Chat
            self.showChat()
            // Dismiss
            dialog.dismiss()
        })
        
        // (3) REPORT
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            // Report User
            self.reportUser(fromVC: dialog)
        })
        
        // (4) BLOCK
        let block = AZDialogAction(title: "Block", handler: { (dialog) -> (Void) in
            // Block User
            self.blockUser(fromVC: dialog)
        })

        // IF FOLLOWING AND FOLLOWER == SPACE
        if currentFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            dialogController.addAction(space)
            dialogController.addAction(chat)
            dialogController.addAction(report)
            dialogController.addAction(block)
            dialogController.show(in: self)
        } else {
            dialogController.addAction(chat)
            dialogController.addAction(report)
            dialogController.addAction(block)
            dialogController.show(in: self)
        }
    }
    
    
    // FUNCTION - Reload data depending on segmentedControl's selectedIndex
    func handleCase() {
        // Update UI by ending UIRefreshControl and configuring UITableView
        self.refresher?.endRefreshing()
        self.tableView.allowsSelection = true
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchToday()
        case 1:
            fetchSaved()
        default:
            break;
        }
    }
    
    // FUNCTION - Fetch today's posts
    func fetchToday() {
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: otherObject.last!)
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: otherObject.last!)
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.limit = self.page
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.relativePosts.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.relativePosts.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                // PRIVATE ACCOUNT
                if otherObject.last!.value(forKey: "private") as! Bool == true {
                    // (1) Follower
                    if currentFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // MARK: - DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // (2) Following
                        if self.relativePosts.count == 0 {
                            // MARK: - DZNEmptyDataSet
                            self.dznType = "💩 No Posts Today"
                            self.tableView.emptyDataSetSource = self
                            self.tableView.emptyDataSetDelegate = self
                        }
                        
                    } else if currentRequestedFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // (3) Follower Requested
                        // MARK: - DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentRequestedFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // (4) Sent Follow Request
                        // MARK : -DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // (5) Follower AND Following (AKA: Friends)
                        if self.relativePosts.count == 0 {
                            // MARK: - DZNEmptyDataSet
                            self.dznType = "💩 No Posts Today"
                            self.tableView.emptyDataSetSource = self
                            self.tableView.emptyDataSetDelegate = self
                        }
                        
                    } else {
                        // (6) Not yet following
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.relativePosts.count == 0 {
                        self.dznType = "💩 No Posts Today"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - Fetch saved posts
    func fetchSaved() {
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: otherObject.last!)
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: otherObject.last!)
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.whereKey("saved", equalTo: true)
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.limit = self.page
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.relativePosts.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.relativePosts.append(object)
                }
                
                // PRIVATE ACCOUNT
                if otherObject.last!.value(forKey: "private") as! Bool == true {
                    // (1) Follower
                    if currentFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // MARK: - DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // (2) Following
                        if self.relativePosts.count == 0 {
                            // MARK: - DZNEmptyDataSet
                            self.dznType = "💩 No Saved Posts"
                            self.tableView.emptyDataSetSource = self
                            self.tableView.emptyDataSetDelegate = self
                        }
                        
                    } else if currentRequestedFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // (3) Follower Requested
                        // MARK: - DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentRequestedFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // (4) Sent Follow Request
                        // MARK : -DZNEmptyDataSet
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                        
                    } else if currentFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // (5) Follower AND Following (AKA: Friends)
                        if self.relativePosts.count == 0 {
                            // MARK: - DZNEmptyDataSet
                            self.dznType = "💩 No Saved Posts"
                            self.tableView.emptyDataSetSource = self
                            self.tableView.emptyDataSetDelegate = self
                        }
                        
                    } else {
                        // (6) Not yet following
                        self.dznType = "🔒 Private Account"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.relativePosts.count == 0 {
                        self.dznType = "💩 No Saved Posts"
                        self.tableView.emptyDataSetSource = self
                        self.tableView.emptyDataSetDelegate = self
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }

    }

    // FUNCTION - Stylize and set title of UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(otherName.last!.lowercased())"
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.view.roundAllCorners(sender: self.navigationController?.view)
        // Show UITabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.dznType != "" {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let font = UIFont(name: "AvenirNext-Medium", size: 15)
        let attributeDictionary: [String: AnyObject]? = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: font!]
        return NSAttributedString(string: self.dznType!, attributes: attributeDictionary)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        print("AI \(self.tableView!.headerView(forSection: 0)!.frame.size.height)")
        print("VL \(self.tableView!.headerView(forSection: 0)!.frame.size.height/2.0)")
        return (self.tableView!.headerView(forSection: 0)!.frame.size.height/2.0)
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30
    }

    // MARK: - TwicketSegmentedControl Delegate Method
    func didSelect(_ segmentIndex: Int) {
        handleCase()
    }
    
    // MARK: - UIView Lifecycle Hierarchy
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title again
        configureView()
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title again
        configureView()
        // Track Who's Profile user lands on
        Heap.track("ViewedProfile", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)",
                "OtherUserID": "\(otherObject.last!.objectId!)",
                "OtherUsername": "\(otherObject.last!.value(forKey: "username") as! String)"
            ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch data
        handleCase()

        // MARK: - TwicketSegmentedControl
        segmentedControl.delegate = self
        segmentedControl.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 16, height: 40)
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["Today", "Saved"])
        segmentedControl.defaultTextColor = UIColor.black
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Demibold", size: 12)!
        
        // Configure UITableView
        tableView?.backgroundColor = UIColor.white
        tableView?.estimatedRowHeight = 75
        tableView?.rowHeight = 75
        tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        tableView?.tableFooterView = UIView()
        // Register NIB
        tableView?.register(UINib(nibName: "OtherUserHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "OtherUserHeader")
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleCase), name: otherNotification, object: nil)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(handleCase), for: .valueChanged)
        tableView.addSubview(refresher)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    
    // MARK: - UITableView Data Source Methods
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // created a constant that stores a registered header
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OtherUserHeader") as! OtherUserHeader
        
        // Query relationships
        _ = appDelegate.queryRelationships()
        
        // Configure UI
        header.delegate = self                                  // Set Parent UIViewController
        header.frame = header.frame                             // Configure frame
        // Add segmentedControl to subView (TwicketSegmentedControl) if posts exist
        if self.relativePosts.count != 0 {
            header.segmentView.addSubview(self.segmentedControl)
        }
        
        // (1) Get user's profile photo
        if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setShowActivityIndicatorView(true)
            header.rpUserProPic.sd_setIndicatorStyle(.gray)
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            // MARK: - RPHelpers extension
            header.rpUserProPic.makeCircular(forView: header.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        }
        
        // (2) Get user's full/real name and bio
        if otherObject.last!.value(forKey: "userBiography") != nil {
            header.fullName.text! = "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)"
            header.userBio.text! = "\(otherObject.last!.value(forKey: "userBiography") as! String)"
        } else {
            header.fullName.text! = "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)"
        }
        
        // (3) Set CurrentUser & OtherUser's relatinship state
        // Hide and show buttons depending on relationship
        // Also set title depending on relationship state
        
        // DEFAULT
        // Not Yet Connected
        // Hide Relation button, and show Follow button: chat and report
        header.relationType.isUserInteractionEnabled = true
        header.relationType.isHidden = true
        header.followButton.isHidden = false
        header.followButton.isUserInteractionEnabled = true
        // Show Chat Button
        header.chatButton.isHidden = false
        header.chatButton.isUserInteractionEnabled = true
        // Show Block Button
        header.blockButton.isHidden = false
        header.blockButton.isUserInteractionEnabled = true
        // Hide Space Button
        header.newSpaceButton.isHidden = true
        header.newSpaceButton.isUserInteractionEnabled = false
        

        if currentFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOWER
            header.relationType.isHidden = false
            header.relationType.setTitle("Follower", for: .normal)
        }
        
        if currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        if currentRequestedFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) || currentRequestedFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOW REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Requested", for: .normal)
        }
        
        if currentFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && currentFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
        // FOLLOWER & FOLLOWING == FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
            
            // Hide Block Button
            header.blockButton.isHidden = true
            header.blockButton.isUserInteractionEnabled = false
            // Show Space Button
            header.newSpaceButton.isHidden = false
            header.newSpaceButton.isUserInteractionEnabled = true
        }
        
        // SELF
        // PFUser.currentUser()'s Profile
        if otherObject.last!.objectId! == PFUser.current()!.objectId! {
            header.followButton.isHidden = true
            header.relationType.isHidden = true
            // Hide all buttons
            header.chatButton.isHidden = true
            header.blockButton.isHidden = true
            header.newSpaceButton.isHidden = true
        }
        
        
        // Add Tap Methods
        let chatTap = UITapGestureRecognizer(target: self, action: #selector(self.showChat))
        chatTap.numberOfTapsRequired = 1
        header.chatButton.addGestureRecognizer(chatTap)
        
        let spaceTap = UITapGestureRecognizer(target: self, action: #selector(self.createSpace))
        spaceTap.numberOfTapsRequired = 1
        header.newSpaceButton.addGestureRecognizer(spaceTap)
        
        let reportBlockTap = UITapGestureRecognizer(target: self, action: #selector(self.reportOrBlock))
        reportBlockTap.numberOfTapsRequired = 1
        header.blockButton.addGestureRecognizer(reportBlockTap)
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let label: UILabel = UILabel(frame: CGRect(x: 8, y: 385, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            // Set fullname AND bio
            let fullName = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            label.text = "\(fullName.uppercased())\n\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            // Set Full name
            label.text = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
        }
        label.sizeToFit()
        
        return CGFloat(475 + label.frame.size.height)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.relativePosts.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("StoryCell", owner: self, options: nil)?.first as! StoryCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
        
        // Set delegate
        cell.delegate = self
        
        // Set PFObject
        cell.postObject = self.relativePosts[indexPath.row]
        
        // (1) Get User's Object
        if let user = self.relativePosts[indexPath.row].value(forKey: "byUser") as? PFUser {
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (2) Set rpUsername
            if let fullName = user.value(forKey: "realNameOfUser") as? String{
                cell.rpUsername.text = fullName
            }
        }
        
        // (3) Set time
        let from = self.relativePosts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set mediaPreview or textPreview
        cell.textPreview.isHidden = true
        cell.mediaPreview.isHidden = true
        
        if self.relativePosts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            cell.textPreview.text = "\(self.relativePosts[indexPath.row].value(forKey: "textPost") as! String)"
            cell.textPreview.isHidden = false
        } else if self.relativePosts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
            cell.mediaPreview.image = UIImage(named: "CSpacePost")
            cell.mediaPreview.isHidden = false
        } else {
            if let photo = self.relativePosts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                cell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
            } else if let video = self.relativePosts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
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
    }
    
    
    // MARK: - UITableView Delegate Method
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.groupTableViewBackground
        }
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if self.page <= self.relativePosts.count + self.skipped.count {
                // Increase page size to load more posts
                page = page + 50
                // Query content
                self.handleCase()
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            handleCase()
        }
    }


}


// MARK: - OtherUser; Interactive Functions Here
extension OtherUser {
    
    // FUNCTION - To Chat
    func showChat() {
        // Append user's object
        chatUserObject.append(otherObject.last!)
        // Append user's username
        chatUsername.append(otherName.last!)
        // Push VC
        let chatRoomVC = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
        self.navigationController?.pushViewController(chatRoomVC, animated: true)
    }
    
    // FUNCTION - Share new Space Post
    func createSpace() {
        // Show NewSpacePostVC
        let newSpaceVC = self.storyboard?.instantiateViewController(withIdentifier: "newSpacePostVC") as! NewSpacePost
        self.navigationController?.pushViewController(newSpaceVC, animated: true)
    }
    
    // FUNCTION - Report User
    func reportUser(fromVC: AZDialogViewController?) {
        let alert = UIAlertController(title: "Report",
                                      message: "Please provide your reason for reporting \(otherName.last!.lowercased())",
            preferredStyle: .alert)
        
        let report = UIAlertAction(title: "Report", style: .destructive) { (action: UIAlertAction!) in
            let answer = alert.textFields![0]
            
            // REPORTED
            let report = PFObject(className: "Reported")
            report["byUsername"] = PFUser.current()!.username!
            report["byUser"] = PFUser.current()!
            report["toUsername"] = otherName.last!
            report["toUser"] = otherObject.last!
            report["forObjectId"] = otherObject.last!.objectId!
            report["reason"] = answer.text!
            report.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved report: \(report)")
                    
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showSuccess(withTitle: "Successfully Reported")
                    
                    // Dismiss
                    fromVC!.dismiss()
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                    // Dismiss
                    fromVC!.dismiss()
                }
            })
        }
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(report)
        alert.addAction(cancel)
        fromVC!.present(alert, animated: true, completion: nil)
    }
    
    // FUNCTION - Block user
    func blockUser(fromVC: AZDialogViewController?) {
        // (1) Block
        let block = PFObject(className: "Blocked")
        block["byUser"] = PFUser.current()!
        block["byUsername"] = PFUser.current()!.username!
        block["toUser"] = otherObject.last!
        block["toUsername"] = otherName.last!.lowercased()
        block.saveInBackground()
        
        // (2) Delete Follower/Following
        let follower = PFQuery(className: "FollowMe")
        follower.whereKey("follower", equalTo: PFUser.current()!)
        follower.whereKey("following", equalTo: otherObject.last!)
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: otherObject.last!)
        following.whereKey("following", equalTo: PFUser.current()!)
        let follow = PFQuery.orQuery(withSubqueries: [follower, following])
        follow.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                PFObject.deleteAll(inBackground: objects!, block: {
                    (success: Bool, error: Error?) in
                    if success {
                        // MARK: - AZDialogViewController
                        let dialogController = AZDialogViewController(title: "💩\nSuccessfully Blocked \(otherName.last!.uppercased())",
                            message: "You can unblock \(otherObject.last!.value(forKey: "realNameOfUser") as! String) in Settings.")
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
                        // Add Skip and verify button
                        dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                            // Dismiss AZDialog
                            dialog.dismiss()
                            // Dismiss and Pop
                            fromVC!.dismiss()
                            _ = self.navigationController?.popViewController(animated: true)
                        }))
                        dialogController.show(in: self)
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error")
                        // Dismiss
                        fromVC!.dismiss()
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
                // Dismiss
                fromVC!.dismiss()
            }
        })
    }
    
    // FUNCTION - Report/Block:
    func reportOrBlock() {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)",
            message: "Options")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        
        dialogController.imageHandler = { (imageView) in
            if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        imageView.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else {
                imageView.image = UIImage(named: "GenderNeutralUser")
            }
            imageView.contentMode = .scaleAspectFill
            return true //must return true, otherwise image won't show.
        }
        
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        // (1) REPORT
        dialogController.addAction(AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            // Report User
            self.reportUser(fromVC: dialog)
        }))
        
        // (2) BLOCK
        dialogController.addAction(AZDialogAction(title: "Block", handler: { (dialog) -> (Void) in
            // Block User
            self.blockUser(fromVC: dialog)
        }))
        
        // Show
        dialogController.show(in: self)
    }
}
