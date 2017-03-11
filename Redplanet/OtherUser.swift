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

import SVProgressHUD
import SDWebImage
import SimpleAlert

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
    var posts = [PFObject]()
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    // Hold likers
    var likes = [PFObject]()
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
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
        _ = _ = self.navigationController?.popViewController(animated: true)
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
    func reportUser() {
        let alert = UIAlertController(title: "Report",
                                      message: "Please provide your reason for reporting \(otherName.last!.uppercased())",
            preferredStyle: .alert)
        
        let report = UIAlertAction(title: "Report", style: .destructive) {
            [unowned self, alert] (action: UIAlertAction!) in
            
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
                    
                    let alert = UIAlertController(title: "Successfully Reported",
                                                  message: "\(otherName.last!.uppercased())",
                        preferredStyle: .alert)
                    
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: nil)
                    
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - SVProgressHUD
                    SVProgressHUD.showError(withStatus: "Error")
                }
            })
        }
        
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(report)
        alert.addAction(cancel)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    // Function to Block user
    func blockUser() {
        // (1) Block
        let block = PFObject(className: "Blocked")
        block["byUser"] = PFUser.current()!
        block["byUsername"] = PFUser.current()!.username!
        block["toUser"] = otherObject.last!
        block["toUsername"] = otherName.last!.uppercased()
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
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                        
                        // Dismiss
                        let alert = UIAlertController(title: "Successfully Blocked",
                                                      message: "\(otherName.last!.uppercased()). You can unblock \(otherObject.last!.value(forKey: "realNameOfUser") as! String) in Settings.",
                            preferredStyle: .alert)
                        
                        let ok = UIAlertAction(title: "ok",
                                               style: .default,
                                               handler: { (alertAction: UIAlertAction!) in
                                                _ = self.navigationController?.popViewController(animated: true)
                        })
                        
                        alert.view.tintColor = UIColor.black
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - SVProgressHUD
                        SVProgressHUD.showError(withStatus: "Error")
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.showError(withStatus: "Error")
            }
        })
    }
    
    
    // Function to Report/Block:
    func reportOrBlock() {
        // MARK: - SimpleAlert
        let options = AlertController(title: "Options",
                                    message: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)",
            style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15.00)
            }
        }
        
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        
        // (1) Report
        let report = AlertAction(title: "Report",
                                        style: .destructive,
                                        handler: { (AlertAction) in
                                            // Report User
                                            self.reportUser()
        })

        
        // (2) Block
        let block = AlertAction(title: "Block",
                                        style: .destructive,
                                        handler: { (AlertAction) in
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.show()
                                            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                            // Block User
                                            self.blockUser()
        })
        
        // (3) Cancel
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        

        options.addAction(report)
        options.addAction(block)
        options.addAction(cancel)
        report.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        report.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        block.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        block.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.present(options, animated: true, completion: nil)
    }
    
    

    @IBAction func moreAction(_ sender: Any) {
        // MARK: - SimpleAlert
        let alert = AlertController(title: "Options",
                                    message: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)",
                                    style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15.00)
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        
        // (1) Write in space
        let space = AlertAction(title: "Write on Space",
                                style: .default,
                                handler: { (AlertAction) in
                                    // Show Space
                                    self.createSpace()
        })
        
        // (2) Chat
        let chat = AlertAction(title: "Chat",
                               style: .default,
                               handler: { (AlertAction) in
                                // Show Chat
                                self.showChat()
        })
        
        
        // (3) Report or block
        let reportOrBlock = AlertAction(title: "Report/Block",
                                        style: .destructive,
                                        handler: { (AlertAction) in
                                            
                                            let alert = UIAlertController(title: nil,
                                                                          message: nil,
                                                                          preferredStyle: .actionSheet)
                                            
                                            let report = UIAlertAction(title: "Report",
                                                                       style: .default,
                                                                       handler: {(alertAction: UIAlertAction!) in
                                                                        // Report User
                                                                        self.reportUser()
                                                                        
                                            })
                                            
                                            let block = UIAlertAction(title: "Block",
                                                                      style: .default,
                                                                      handler: {(alertAction: UIAlertAction!) in
                                                                        // MARK: - SVProgressHUD
                                                                        SVProgressHUD.show()
                                                                        SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                                                        // Block User
                                                                        self.blockUser()
                                            })
                                            
                                            
                                            let cancel = UIAlertAction(title: "Cancel",
                                                                       style: .cancel,
                                                                       handler: nil)
                                            
                                            alert.addAction(report)
                                            alert.addAction(block)
                                            alert.addAction(cancel)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
        })
        
        // (5) Cancel
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        // IF FOLLOWING AND FOLLOWER == SPACE
        if myFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            alert.addAction(space)
            alert.addAction(chat)
            alert.addAction(reportOrBlock)
            alert.addAction(cancel)
            space.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            space.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            chat.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            chat.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            reportOrBlock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            reportOrBlock.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
            self.present(alert, animated: true, completion: nil)
        } else {
            alert.addAction(chat)
            alert.addAction(reportOrBlock)
            alert.addAction(cancel)
            chat.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            chat.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            reportOrBlock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            reportOrBlock.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
            self.present(alert, animated: true, completion: nil)
        }
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
                self.posts.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time configs
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.posts.append(object)
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
                        self.cover.setTitle("🔒\nPrivate Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myRequestedFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                    // CONFIRM FOLLOW REQUEST
                        self.cover.setTitle("🔒\nPrivate Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                    // FOLLOWING
                        if self.posts.count == 0 {
                            self.cover.setTitle("🤔\nNo Posts Today", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else if myRequestedFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                    // FOLLOW REQUESTED
                        self.cover.setTitle("🔒\nPrivate Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                    // FOLLOWER & FOLLOWING == FOLLOWING
                        if self.posts.count == 0 {
                            self.cover.setTitle("🤔\nNo Posts Today", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else {
                    // NOT CONNECTED
                        self.cover.setTitle("🔒\nPrivate Account", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.posts.count == 0 {
                        self.cover.setTitle("🤔\nNo Posts Today", for: .normal)
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
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(otherName.last!.uppercased())"
        }
        
        // Configure nav bar && hide tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
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
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize and set title
        configureView()
        
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
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title again
        configureView()
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
    
    // MARK: - UITableViewHeader Section View
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // created a constant that stores a registered header
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OtherUserHeader") as! OtherUserHeader
        
        // Query relationships
        _ = appDelegate.queryRelationships()
        
        // Declare parent VC
        header.delegate = self
        
        //set contentView frame and autoresizingMask
        header.frame = header.frame
        
        // Layout views
        header.rpUserProPic.layoutIfNeeded()
        header.rpUserProPic.layoutSubviews()
        header.rpUserProPic.setNeedsLayout()
        
        // Set header
        header.rpUserProPic.layer.cornerRadius = header.rpUserProPic.frame.size.width/2.0
        header.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        header.rpUserProPic.layer.borderWidth = 0.5
        header.rpUserProPic.clipsToBounds = true
        
        // (1) Get user's profile photo
        if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setShowActivityIndicatorView(true)
            header.rpUserProPic.sd_setIndicatorStyle(.gray)
            // MARK: - SDWebImage
            header.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
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
    
    
    // header height
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
        self.cover.setTitleColor(UIColor.lightGray, for: .normal)
        self.cover.backgroundColor = UIColor.white
        
        return CGFloat(425 + label.frame.size.height)
    }
    
    
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure initial setup for time
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        if self.posts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            // ****************************************************************************************************************
            // TEXT POST ******************************************************************************************************
            // ****************************************************************************************************************
            let tpCell = Bundle.main.loadNibNamed("TimeTextPostCell", owner: self, options: nil)?.first as! TimeTextPostCell
            
            // (1) SET USER DATA
            // (1A) Set rpUserProPic
            tpCell.rpUserProPic.layoutIfNeeded()
            tpCell.rpUserProPic.layoutSubviews()
            tpCell.rpUserProPic.setNeedsLayout()
            // Make Profile Photo Circular
            tpCell.rpUserProPic.layer.cornerRadius = tpCell.rpUserProPic.frame.size.width/2
            tpCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            tpCell.rpUserProPic.layer.borderWidth = 0.5
            if let proPic = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                tpCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
            tpCell.rpUsername.text! = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
            // (1C) User's Object
            tpCell.userObject = self.posts[indexPath.row].object(forKey: "byUser") as! PFUser
            // (2) SET POST OBJECT
            tpCell.postObject = self.posts[indexPath.row]
            // (3) SET CELL'S DELEGATE
            tpCell.delegate = self.navigationController
            
            // (4) SET TEXT POST
            tpCell.textPost.text! = self.posts[indexPath.row].value(forKey: "textPost") as! String
            
            // (5) SET TIME
            if difference.second! <= 0 {
                tpCell.time.text! = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    tpCell.time.text! = "1 second ago"
                } else {
                    tpCell.time.text! = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    tpCell.time.text! = "1 minute ago"
                } else {
                    tpCell.time.text! = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    tpCell.time.text! = "1 hour ago"
                } else {
                    tpCell.time.text! = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    tpCell.time.text! = "1 day ago"
                } else {
                    tpCell.time.text! = "\(difference.day!) days ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                tpCell.time.text! = createdDate.string(from: self.posts[indexPath.row].createdAt!)
            }
            
            // (6) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        tpCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        tpCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        tpCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        tpCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        tpCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        tpCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        tpCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        tpCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.posts[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        tpCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        tpCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        tpCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
            return tpCell   // return TimeTextPostCell.swift
            
            
        } else if self.ephemeralTypes.contains(self.posts[indexPath.row].value(forKeyPath: "contentType") as! String) {
            // ****************************************************************************************************************
            // MOMENTS, SPACE POSTS, SHARED POSTS *****************************************************************************
            // ****************************************************************************************************************
            let eCell = Bundle.main.loadNibNamed("EphemeralCell", owner: self, options: nil)?.first as! EphemeralCell
            
            // (1) SET USER DATA
            // (1A) Set rpUserProPic
            eCell.rpUserProPic.layoutIfNeeded()
            eCell.rpUserProPic.layoutSubviews()
            eCell.rpUserProPic.setNeedsLayout()
            // Make Profile Photo Circular
            eCell.rpUserProPic.layer.cornerRadius = eCell.rpUserProPic.frame.size.width/2
            eCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            eCell.rpUserProPic.layer.borderWidth = 0.5
            if let proPic = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                eCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
            eCell.rpUsername.text! = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
            // (1C) User's Object
            eCell.userObject = self.posts[indexPath.row].object(forKey: "byUser") as! PFUser
            // (2) SET POST OBJECT
            eCell.postObject = self.posts[indexPath.row]
            // (3) SET CELL'S DELEGATE
            eCell.delegate = self.navigationController
            
            // (4) SET TIME
            if difference.second! <= 0 {
                eCell.time.text! = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    eCell.time.text! = "1 second ago"
                } else {
                    eCell.time.text! = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    eCell.time.text! = "1 minute ago"
                } else {
                    eCell.time.text! = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    eCell.time.text! = "1 hour ago"
                } else {
                    eCell.time.text! = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    eCell.time.text! = "yesterday"
                } else {
                    eCell.time.text! = "\(difference.day!) days ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                eCell.time.text! = createdDate.string(from: self.posts[indexPath.row].createdAt!)
            }
            
            // (5) Layout content
            // High level configurations
            // Configure IconicPreview by laying out views
            eCell.iconicPreview.layoutIfNeeded()
            eCell.iconicPreview.layoutSubviews()
            eCell.iconicPreview.setNeedsLayout()
            eCell.iconicPreview.layer.cornerRadius = eCell.iconicPreview.frame.size.width/2
            eCell.iconicPreview.layer.borderColor = UIColor.clear.cgColor
            eCell.iconicPreview.layer.borderWidth = 0.00
            eCell.iconicPreview.contentMode = .scaleAspectFill
            // (5A) MOMENT
            if self.posts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                
                // Make iconicPreview circular with red border color
                eCell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                eCell.iconicPreview.layer.borderWidth = 3.50
                
                if let still = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // STILL PHOTO
                    // MARK: - SDWebImage
                    let fileURL = URL(string: still.url!)
                    eCell.iconicPreview.sd_setImage(with: fileURL, placeholderImage: eCell.iconicPreview.image)
                    
                } else if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // VIDEO MOMENT
                    let player = AVPlayer(url: URL(string: videoFile.url!)!)
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.frame = eCell.iconicPreview.bounds
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    eCell.iconicPreview.contentMode = .scaleAspectFit
                    eCell.iconicPreview.layer.addSublayer(playerLayer)
                }
                
                // (5B) SPACE POST
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "CSpacePost")
                
                // (5C) SHARED POSTS
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "SharedPostIcon")
            }
            
            return eCell // return EphemeralCell.swift
            
        } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "ph" {
            // ****************************************************************************************************************
            // PHOTOS *********************************************************************************************************
            // ****************************************************************************************************************
            let mCell = Bundle.main.loadNibNamed("TimeMediaCell", owner: self, options: nil)?.first as! TimeMediaCell
            
            // (1) SET USER DATA
            // (1A) Set rpUserProPic
            mCell.rpUserProPic.layoutIfNeeded()
            mCell.rpUserProPic.layoutSubviews()
            mCell.rpUserProPic.setNeedsLayout()
            // Make Profile Photo Circular
            mCell.rpUserProPic.layer.cornerRadius = mCell.rpUserProPic.frame.size.width/2
            mCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            mCell.rpUserProPic.layer.borderWidth = 0.5
            if let proPic = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                mCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
            mCell.rpUsername.text! = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
            // (1C) User's Object
            mCell.userObject = self.posts[indexPath.row].object(forKey: "byUser") as! PFUser
            // (2) SET POST OBJECT
            mCell.postObject = self.posts[indexPath.row]
            // (3) SET CELL'S DELEGATE
            mCell.delegate = self.navigationController
            
            // (4) FETCH PHOTO
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mCell.mediaAsset.sd_setShowActivityIndicatorView(true)
                mCell.mediaAsset.sd_setIndicatorStyle(.gray)
                
                // MARK: - SDWebImage
                let fileURL = URL(string: photo.url!)
                mCell.mediaAsset.sd_setImage(with: fileURL, placeholderImage: mCell.mediaAsset.image)
            }
            
            // (5) HANDLE CAPTION IF IT EXISTS
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                mCell.textPost.text! = caption
            } else {
                mCell.textPost.isHidden = true
            }
            
            // (6) SET TIME
            if difference.second! <= 0 {
                mCell.time.text! = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    mCell.time.text! = "1 second ago"
                } else {
                    mCell.time.text! = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    mCell.time.text! = "1 minute ago"
                } else {
                    mCell.time.text! = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    mCell.time.text! = "1 hour ago"
                } else {
                    mCell.time.text! = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    mCell.time.text! = "1 day ago"
                } else {
                    mCell.time.text! = "\(difference.day!) days ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                mCell.time.text! = createdDate.string(from: self.posts[indexPath.row].createdAt!)
            }
            
            // (7) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        mCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        mCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        mCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        mCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        mCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        mCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        mCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        mCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.posts[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        mCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        mCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        mCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            return mCell // return TimeMediaCell.swift
            
            
        } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "pp" {
            // ****************************************************************************************************************
            // PROFILE PHOTO **************************************************************************************************
            // ****************************************************************************************************************
            let ppCell = Bundle.main.loadNibNamed("ProPicCell", owner: self, options: nil)?.first as! ProPicCell
            
            // (1) SET USER DATA
            // (1A) Set rpUserProPic
            ppCell.smallProPic.layoutIfNeeded()
            ppCell.smallProPic.layoutSubviews()
            ppCell.smallProPic.setNeedsLayout()
            // Make Profile Photo Circular
            ppCell.smallProPic.layer.cornerRadius = ppCell.smallProPic.frame.size.width/2
            ppCell.smallProPic.layer.borderColor = UIColor.lightGray.cgColor
            ppCell.smallProPic.layer.borderWidth = 0.5
            if let proPic = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                ppCell.smallProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
            ppCell.rpUsername.text! = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
            // (1C) User's Object
            ppCell.userObject = self.posts[indexPath.row].object(forKey: "byUser") as! PFUser
            otherObject.append(self.posts[indexPath.row].value(forKey: "byUser") as! PFUser)
            otherName.append((self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).username!)
            // (2) SET POST OBJECT
            ppCell.postObject = self.posts[indexPath.row]
            // (3) SET CELL'S DELEGATE
            ppCell.delegate = self.navigationController
            
            // (4) FETCH PROFILE PHOTO
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                ppCell.rpUserProPic.sd_setShowActivityIndicatorView(true)
                ppCell.rpUserProPic.sd_setIndicatorStyle(.gray)
                // MARK: - SDWebImage
                let fileURL = URL(string: photo.url!)
                ppCell.rpUserProPic.sd_setImage(with: fileURL, placeholderImage: ppCell.rpUserProPic.image)
            }
            
            // (5) HANDLE CAPTION (TEXT POST) IF IT EXTS
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                ppCell.textPost.text! = caption
            } else {
                ppCell.textPost.isHidden = true
            }
            
            // (6) SET TIME
            if difference.second! <= 0 {
                ppCell.time.text! = "updated their Profile Photo now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    ppCell.time.text! = "updated their Profile Photo 1s ago"
                } else {
                    ppCell.time.text! = "updated their Profile Photo \(difference.second!)s ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    ppCell.time.text! = " updated their Profile Photo 1m ago"
                } else {
                    ppCell.time.text! = "updated their Profile Photo \(difference.minute!)m ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    ppCell.time.text! = "updated their Profile Photo 1h ago"
                } else {
                    ppCell.time.text! = "updated their Profile Photo \(difference.hour!)h ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    ppCell.time.text! = "updated their Profile Photo yesterday"
                } else {
                    ppCell.time.text! = "updated their Profile Photo \(difference.day!)d ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                ppCell.time.text! = "updated their Profile Photo on \(createdDate.string(from: self.posts[indexPath.row].createdAt!))"
            }
            
            // (7) FETCH LIKES, COMMENTS, AND SHARES
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        ppCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        ppCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        ppCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        ppCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        ppCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        ppCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        ppCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        ppCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.posts[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        ppCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        ppCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        ppCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            return ppCell // return ProPicCell.swift
            
        } else {
            // ****************************************************************************************************************
            // VIDEOS *********************************************************************************************************
            // ****************************************************************************************************************
            let vCell = Bundle.main.loadNibNamed("TimeVideoCell", owner: self, options: nil)?.first as! TimeVideoCell
            
            // (1) SET USER DATA
            // (1A) Set rpUserProPic
            vCell.rpUserProPic.layoutIfNeeded()
            vCell.rpUserProPic.layoutSubviews()
            vCell.rpUserProPic.setNeedsLayout()
            // Make Profile Photo Circular
            vCell.rpUserProPic.layer.cornerRadius = vCell.rpUserProPic.frame.size.width/2
            vCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            vCell.rpUserProPic.layer.borderWidth = 0.5
            if let proPic = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                vCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
            vCell.rpUsername.text! = (self.posts[indexPath.row].object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
            // (1C) User's Object
            vCell.userObject = self.posts[indexPath.row].object(forKey: "byUser") as! PFUser
            // (2) SET POST OBJECT
            vCell.postObject = self.posts[indexPath.row]
            // (3) SET CELL'S DELEGATE
            vCell.delegate = self.navigationController
            
            // (4) Fetch Video Thumbnail
            if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // VIDEO
                // MARK: - SDWebImage
                vCell.videoPreview.sd_setShowActivityIndicatorView(true)
                vCell.videoPreview.sd_setIndicatorStyle(.gray)
                
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = vCell.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                vCell.videoPreview.contentMode = .scaleToFill
                vCell.videoPreview.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            
            // (5) Handle caption (text post) if it exists
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                vCell.textPost.text! = caption
            } else {
                vCell.textPost.isHidden = true
            }
            
            // (6) SET TIME
            if difference.second! <= 0 {
                vCell.time.text! = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    vCell.time.text! = "1 second ago"
                } else {
                    vCell.time.text! = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    vCell.time.text! = "1 minute ago"
                } else {
                    vCell.time.text! = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    vCell.time.text! = "1 hour ago"
                } else {
                    vCell.time.text! = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    vCell.time.text! = "1 day ago"
                } else {
                    vCell.time.text! = "\(difference.day!) days ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                vCell.time.text! = createdDate.string(from: self.posts[indexPath.row].createdAt!)
            }
            
            // (7) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        vCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        vCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        vCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        vCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        vCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.posts[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        vCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        vCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        vCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.posts[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        vCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        vCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        vCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            return vCell // return TimeVideoCell.swift
        }
    } // end cellForRowAt
    
    
    // MARK: - UIScrollViewDelegate method
    // MARK: - RP Pipeline method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    
    func loadMore() {
        // If posts on server are > than shown
        if self.page <= self.posts.count + self.skipped.count {
            // Increase page size to load more posts
            page = page + 50
            // Query content
            self.queryContent()
        }
    }
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            self.refresher.endRefreshing()
        }
    }


}
