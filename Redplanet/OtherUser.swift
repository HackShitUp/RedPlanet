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

import SDWebImage

// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()


// Define identifier
let otherNotification = Notification.Name("otherUser")

class OtherUser: UITableViewController {
    
    // App Delegate
    let appDelegate = AppDelegate()
    
    // Array to hold other user's content
    var stories = [PFObject]()
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Page size
    var page: Int = 50
    
    // View to cover tableView when hidden swift
    let cover = UIButton()
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        otherObject.removeLast()
        otherName.removeLast()
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Function to show Chat
    func showChat() {
        // Append user's object
        chatUserObject.append(otherObject.last!)
        // Append user's username
        chatUsername.append(otherName.last!)
        // Push VC
        let chatRoomVC = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
        self.navigationController?.pushViewController(chatRoomVC, animated: true)
    }
    
    // Function to create new Space Post
    func createSpace() {
        // Append to otherObject
        otherObject.append(otherObject.last!)
        // Append to otherName
        otherName.append(otherName.last!)
        // Push VC
        let newSpaceVC = self.storyboard?.instantiateViewController(withIdentifier: "newSpacePostVC") as! NewSpacePost
        self.navigationController?.pushViewController(newSpaceVC, animated: true)
    }
    
    // Function to Report User
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
    
    // Function to Block user
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
    
    // Function to Report/Block:
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
    
    @IBAction func moreAction(_ sender: Any) {

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
        if myFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
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
    
    // Function to refresh
    func refresh() {
        // Query Content
        queryContent()
        // End refresher
        self.refresher.endRefreshing()
        // Reload data
        self.tableView!.reloadData()
    }

    // Function to query other user's content
    func queryContent() {
        // User's Posts
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: otherObject.last!)
        // User's Space Posts
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: otherObject.last!)
        // Both
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.limit = self.page
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // clear array
                self.stories.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.stories.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                
                // Check Privacy; add cover relatively
                if otherObject.last!.value(forKey: "private") as! Bool == true {
                    // PRIVATE ACCOUNT
                    // Any logic that contains a print statement DOES NOT place a cover
                    
                    if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                    // FOLLOWER ONLY
                        self.cover.setTitle("🔒 Private Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myRequestedFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                    // CONFIRM FOLLOW REQUEST
                        self.cover.setTitle("🔒 Private Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                    // FOLLOWING
                        if self.stories.count == 0 {
                            self.cover.setTitle("💩 No Posts Today", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else if myRequestedFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                    // FOLLOW REQUESTED
                        self.cover.setTitle("🔒 Private Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                    // FOLLOWER & FOLLOWING == FOLLOWING
                        if self.stories.count == 0 {
                            self.cover.setTitle("💩 No Posts Today", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else {
                    // NOT CONNECTED
                        self.cover.setTitle("🔒 Private Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.stories.count == 0 {
                        self.cover.setTitle("💩 No Posts Today", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = true
                    }
                    
                    self.tableView!.isScrollEnabled = true
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }

    // Function to stylize and set title of navigation bar
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
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    // MARK: - UIView Lifecycle Hierarchy
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title again
        configureView()
        // Fetch data
        queryContent()
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Stylize and set title
        configureView()

        // Track Who's Profile user lands on
        Heap.track("ViewedProfile", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)",
                "OtherUserID": "\(otherObject.last!.objectId!)",
                "OtherUsername": "\(otherObject.last!.value(forKey: "username") as! String)"
            ])
 
        
        // Configure table view
        self.tableView?.backgroundColor = UIColor.white
        self.tableView?.estimatedRowHeight = 65.00
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView?.tableFooterView = UIView()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: otherNotification, object: nil)
        
        // Register NIB
        let nib = UINib(nibName: "OtherUserHeader", bundle: nil)
        tableView?.register(nib, forHeaderFooterViewReuseIdentifier: "OtherUserHeader")
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
//        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title again
        configureView()
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
        
        // Declare parent VC
        header.delegate = self
        
        //set contentView frame and autoresizingMask
        header.frame = header.frame
        
        // MARK: - RPHelpers extension
        header.rpUserProPic.makeCircular(imageView: header.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Get user's profile photo
        if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setShowActivityIndicatorView(true)
            header.rpUserProPic.sd_setIndicatorStyle(.gray)
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
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
        

        if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOWER
            header.relationType.isHidden = false
            header.relationType.setTitle("Follower", for: .normal)
        }
        
        if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        if myRequestedFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) || myRequestedFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
        // FOLLOW REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Requested", for: .normal)
        }
        
        if myFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
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
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 356, width: 359, height: CGFloat.greatestFiniteMagnitude))
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
        
        // Add cover
        self.cover.frame = CGRect(x: 0, y: CGFloat(425 + label.frame.size.height), width: self.tableView!.frame.size.width, height: self.tableView!.frame.size.height+425+label.frame.size.height)
        self.cover.isUserInteractionEnabled = false
        self.cover.isEnabled = false
        self.cover.titleLabel!.lineBreakMode = .byWordWrapping
        self.cover.contentVerticalAlignment = .top
        self.cover.contentHorizontalAlignment = .center
        self.cover.titleLabel!.textAlignment = .center
        self.cover.titleLabel!.font = UIFont(name: "AvenirNext-Demibold", size: 15)
        self.cover.setTitleColor(UIColor.darkGray, for: .normal)
        self.cover.backgroundColor = UIColor.white
        
        return CGFloat(425 + label.frame.size.height)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("NewsFeedCell", owner: self, options: nil)?.first as! NewsFeedCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
        
        // Set delegate
        cell.delegate = self
        
        // Set PFObject
        cell.postObject = self.stories[indexPath.row]
        
        // (1) Get User's Object
        if let user = self.stories[indexPath.row].value(forKey: "byUser") as? PFUser {
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
        let from = self.stories[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set mediaPreview or textPreview
        cell.textPreview.isHidden = true
        cell.mediaPreview.isHidden = true
        
        if self.stories[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            cell.textPreview.text = "\(self.stories[indexPath.row].value(forKey: "textPost") as! String)"
            cell.textPreview.isHidden = false
        } else if self.stories[indexPath.row].value(forKey: "contentType") as! String == "sh" {
            cell.mediaPreview.image = UIImage(named: "SharedPostIcon")
            cell.mediaPreview.isHidden = false
        } else if self.stories[indexPath.row].value(forKey: "contentType") as! String == "sp" {
            cell.mediaPreview.image = UIImage(named: "CSpacePost")
            cell.mediaPreview.isHidden = false
        } else {
            if let photo = self.stories[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                cell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
            } else if let video = self.stories[indexPath.row].value(forKey: "videoAsset") as? PFFile {
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
        self.tableView!.cellForRow(at: indexPath)?.backgroundColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if self.page <= self.stories.count + self.skipped.count {
                // Increase page size to load more posts
                page = page + 50
                // Query content
                self.queryContent()
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            self.refresher.endRefreshing()
        }
    }


}
