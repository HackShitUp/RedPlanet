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
import SimpleAlert

// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()


// Define identifier
let otherNotification = Notification.Name("otherUser")

class OtherUser: UITableViewController {
    
    // Query Relationships
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Other User's Friends
    var oFriends = [PFObject]()
    
    // Other User's Followers
    var oFollowers = [PFObject]()
    
    // Other User's Following
    var oFollowing = [PFObject]()
    
    // Array to hold other user's content
    var contentObjects = [PFObject]()
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Page size
    var page: Int = 50
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // View to cover tableView when hidden swift
    let cover = UIButton()
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        otherObject.removeLast()
        otherName.removeLast()
        
        // Pop view controller
        _ = _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func moreAction(_ sender: Any) {
        // MARK: - SimpleAlert
        let alert = AlertController(title: "Options",
                                    message: nil,
                                    style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        
        // (1) Write in space
        let space = AlertAction(title: "Write on Space ☄️",
                                style: .default,
                                handler: { (AlertAction) in
                                    // Append to otherObject
                                    otherObject.append(otherObject.last!)
                                    // Append to otherName
                                    otherName.append(otherName.last!)
                                    
                                    // Push VC
                                    let newSpaceVC = self.storyboard?.instantiateViewController(withIdentifier: "newSpacePostVC") as! NewSpacePost
                                    self.navigationController?.pushViewController(newSpaceVC, animated: true)
        })
        
        // (2) Chat
        let chat = AlertAction(title: "Chat 💬",
                               style: .default,
                               handler: { (AlertAction) in
                                
                                // Append user's object
                                chatUserObject.append(otherObject.last!)
                                // Append user's username
                                chatUsername.append(otherName.last!)
                                
                                // Push VC
                                let chatRoomVC = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
                                self.navigationController?.pushViewController(chatRoomVC, animated: true)
                                
        })
        
        
        // (3) Report or block
        let reportOrBlock = AlertAction(title: "Report or Block",
                                        style: .destructive,
                                        handler: { (AlertAction) in
                                            
                                            let alert = UIAlertController(title: nil,
                                                                          message: nil,
                                                                          preferredStyle: .actionSheet)
                                            
                                            let report = UIAlertAction(title: "Report ✋",
                                                                       style: .default,
                                                                       handler: {(alertAction: UIAlertAction!) in
                                                                        let alert = UIAlertController(title: "Report",
                                                                                                      message: "Please provide your reason for reporting \(otherName.last!.uppercased())",
                                                                            preferredStyle: .alert)
                                                                        
                                                                        let report = UIAlertAction(title: "Report", style: .destructive) {
                                                                            [unowned self, alert] (action: UIAlertAction!) in
                                                                            
                                                                            let answer = alert.textFields![0]
                                                                            
                                                                            // Save to <Block_Reported>
                                                                            let report = PFObject(className: "Block_Reported")
                                                                            report["from"] = PFUser.current()!.username!
                                                                            report["fromUser"] = PFUser.current()!
                                                                            report["to"] = otherName.last!
                                                                            report["toUser"] = otherObject.last!
                                                                            report["forObjectId"] = otherObject.last!.objectId!
                                                                            report["type"] = answer.text!
                                                                            report.saveInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("Successfully saved report: \(report)")
                                                                                    
                                                                                    // Dismiss
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
                                                                        
                                            })
                                            
                                            let block = UIAlertAction(title: "Block 🚫",
                                                                      style: .default,
                                                                      handler: {(alertAction: UIAlertAction!) in
                                                                        // Save to <Block_Reported>
                                                                        let report = PFObject(className: "Block_Reported")
                                                                        report["from"] = PFUser.current()!.username!
                                                                        report["fromUser"] = PFUser.current()!
                                                                        report["to"] = otherName.last!
                                                                        report["toUser"] = otherObject.last!
                                                                        report["forObjectId"] = otherObject.last!.objectId!
                                                                        report["type"] = "BLOCK"
                                                                        report.saveInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully saved report: \(report)")
                                                                                
                                                                                // Dismiss
                                                                                let alert = UIAlertController(title: "Successfully Blocked",
                                                                                                              message: "\(otherName.last!.uppercased()). You will receive a message from us if the issue is serious.",
                                                                                    preferredStyle: .alert)
                                                                                
                                                                                let ok = UIAlertAction(title: "ok",
                                                                                                       style: .default,
                                                                                                       handler: nil)
                                                                                
                                                                                alert.addAction(ok)
                                                                                alert.view.tintColor = UIColor.black
                                                                                self.present(alert, animated: true, completion: nil)
                                                                                
                                                                            } else {
                                                                                print(error?.localizedDescription as Any)
                                                                            }
                                                                        })
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
        
        // Show options
        if myFriends.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            alert.addAction(space)
            alert.addAction(chat)
            alert.addAction(reportOrBlock)
            alert.addAction(cancel)
            space.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            space.button.setTitleColor(UIColor.black, for: .normal)
            chat.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            chat.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            reportOrBlock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            reportOrBlock.button.setTitleColor(UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0), for: .normal)
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
            reportOrBlock.button.setTitleColor(UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0), for: .normal)
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
                self.contentObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time configs
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if object.value(forKey: "contentType") as! String == "itm" || object.value(forKey: "contentType") as! String == "sh" {
                        if difference.hour! < 24 {
                            self.contentObjects.append(object)
                        } else {
                            self.skipped.append(object)
                        }
                    } else {
                        self.contentObjects.append(object)
                    }
                }
                
                
                // Check Privacy; add cover relatively
                if otherObject.last!.value(forKey: "private") as! Bool == true {
                    // PRIVATE ACCOUNT
                    // Any logic that contains a print statement DOES NOT place a cover
                    
                    if myFriends.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // FRIENDS
                        print("Don't hide because FRIENDS")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNothing Here.\n", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else if myRequestedFriends.contains(where: {$0.objectId == otherObject.last!.objectId!} ) || requestedToFriendMe.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        
                        // FRIEND REQUESTED
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        
                        // FOLLOWER ONLY
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myRequestedFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // CONFIRM FOLLOW REQUEST
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // FOLLOWING
                        print("Don't hide because FOLLOWING")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNothing Here.\n", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else if myRequestedFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
                        // FOLLOW REQUESTED
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                        
                    } else if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                        // FOLLOWER & FOLLOWING
                        print("Don't hide because FOLLOWING")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNothing Here.\n", for: .normal)
                            self.tableView!.addSubview(self.cover)
                            self.tableView!.allowsSelection = false
                            self.tableView!.isScrollEnabled = true
                        }
                        
                    } else {
                        // Not yet connected
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.tableView!.addSubview(self.cover)
                        self.tableView!.allowsSelection = false
                        self.tableView!.isScrollEnabled = false
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.contentObjects.count == 0 {
                        self.cover.setTitle("🤔\nNothing Here.\n", for: .normal)
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
        // Run relationships
        _ = appDelegate.queryRelationships()
        
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
        
        // Query content
        queryContent()
        
        // Configure table view
        self.tableView?.estimatedRowHeight = 658
        self.tableView?.rowHeight = UITableViewAutomaticDimension
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
        
        // TODO::
        // Show which button to tap!
        let openedProfile = UserDefaults.standard.bool(forKey: "DidOpenOtherUserProfile")
        if openedProfile == false && otherObject.last! != PFUser.current()! {
            
            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenOtherUserProfile")
            
            let alert = AlertController(title: "🤗\nFriend or Follow",
                                        message: "Friends and Following are NOT the same thing on Redplanet. Friend people you know for the cool features only friends can interact with.",
                                        style: .alert)
            
            // Design content view
            alert.configContentView = { view in
                if let view = view as? AlertContentView {
                    view.backgroundColor = UIColor.white
                    view.titleLabel.textColor = UIColor.black
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 17)
                    view.messageLabel.textColor = UIColor.black
                    view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                    view.textBackgroundView.layer.cornerRadius = 3.00
                    view.textBackgroundView.clipsToBounds = true
                }
            }
            // Design corner radius
            alert.configContainerCornerRadius = {
                return 14.00
            }
            
            
            
            let learnMore = AlertAction(title: "I'm Confused",
                                        style: .destructive,
                                        handler: { (AlertAction) in
                                            // Push VC
                                            let faqVC = self.storyboard?.instantiateViewController(withIdentifier: "faqVC") as! FAQ
                                            self.navigationController?.pushViewController(faqVC, animated: true)
            })
            
            let ok = AlertAction(title: "ok",
                                 style: .default,
                                 handler: nil)
            
            alert.addAction(learnMore)
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        

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
        
        // (1) Get user's object
        otherObject.last!.fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (A) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            header.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            header.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        
        // (2) Get user's full/real name and bio
        // Set fullname
        let fullName = otherObject.last!.value(forKey: "realNameOfUser") as! String
        if otherObject.last!.value(forKey: "userBiography") != nil {
            header.userBio.text = "\(fullName.uppercased())\n\(otherObject.last!.value(forKey: "userBiography") as! String)"
        } else {
            header.userBio.text = "\(fullName.uppercased())"
        }
        
        
        // (3) Set CurrentUser & OtherUser's relatinship state
        // Hide and show buttons depending on relationship
        // Also set title depending on relationship state
        
        // DEFAULT
        // Not yet connected
        header.relationType.isUserInteractionEnabled = true
        header.relationType.isHidden = true
        
        header.friendButton.isHidden = false
        header.friendButton.isEnabled = true
        
        header.followButton.isHidden = false
        header.followButton.isEnabled = true
        
        if myFriends.contains(where: { $0.objectId! == otherObject.last!.objectId!} ) {
            // FRIENDS
            header.relationType.isHidden = false
            header.relationType.setTitle("Friends", for: .normal)
        }
        
        if myRequestedFriends.contains(where: {$0.objectId == otherObject.last!.objectId!} ) || requestedToFriendMe.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            // FRIEND REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Friend Requested", for: .normal)
        }
        
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
            header.relationType.setTitle("Follow Requested", for: .normal)
        }
        
        if myFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && myFollowing.contains(where: {$0.objectId == otherObject.last!.objectId!}) {
            // FOLLOWER & FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        // PFUser.currentUser()'s Profile
        if otherObject.last!.objectId! == PFUser.current()!.objectId! {
            header.friendButton.isHidden = true
            header.followButton.isHidden = true
            header.relationType.isHidden = true
        }
        
        return header
        
    }
    
    
    // header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 304, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            // Set fullname
            let fullName = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            
            label.text = "\(fullName.uppercased())\n\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            label.text = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)"
        }
        
        label.sizeToFit()
        
        return CGFloat(425 + label.frame.size.height)
    }
    
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.contentObjects.count
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.ephemeralTypes.contains(self.contentObjects[indexPath.row].value(forKeyPath: "contentType") as! String) {
            return 65
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Intialize UITableViewCells
        let eCell = Bundle.main.loadNibNamed("EphemeralCell", owner: self, options: nil)?.first as! EphemeralCell
        let tpCell = Bundle.main.loadNibNamed("TimeTextPostCell", owner: self, options: nil)?.first as! TimeTextPostCell
        let mCell = Bundle.main.loadNibNamed("TimeMediaCell", owner: self, options: nil)?.first as! TimeMediaCell
        
        // Declare delegates
        eCell.delegate = self.navigationController
        tpCell.delegate = self.navigationController
        mCell.delegate = self.navigationController
        
        // Initialize all level configurations: rpUserProPic && rpUsername
        let proPics = [eCell.rpUserProPic, tpCell.rpUserProPic, mCell.rpUserProPic]
        let usernames = [eCell.rpUsername, tpCell.rpUsername, mCell.rpUsername]
        
        // Initialize text for time
        var rpTime: String?
        
        // (I) Fetch user's data and unload them
        self.contentObjects[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if let user = object!["byUser"] as? PFUser {
                    // (A) User's Full Name
                    for u in usernames {
                        u?.text! = user["realNameOfUser"] as! String
                    }
                    
                    // (B) Profile Photo
                    for p in proPics {
                        // LayoutViews for rpUserProPic
                        p?.layoutIfNeeded()
                        p?.layoutSubviews()
                        p?.setNeedsLayout()
                        // Make Profile Photo Circular
                        p?.layer.cornerRadius = (p?.frame.size.width)!/2
                        p?.layer.borderColor = UIColor.lightGray.cgColor
                        p?.layer.borderWidth = 0.5
                        p?.clipsToBounds = true
                        // Fetch profile photo
                        if let proPic = user["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    p?.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                    p?.image = UIImage(named: "Gender Neutral User-100")
                                }
                            })
                            
                            // MARK: - SDWebImage
                            p?.sd_setImage(with: URL(string: proPic.url!), placeholderImage: p?.image)
                        }
                    }
                    
                    // SET user's objects
                    eCell.userObject = user
                    tpCell.userObject = user
                    mCell.userObject = user
                } // end fetching PFUser object
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // (II) Configure time for Photos, Profile Photos, Text Posts, and Videos
        let from = self.contentObjects[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            rpTime = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                rpTime = "1 second ago"
            } else {
                rpTime = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                rpTime = "1 minute ago"
            } else {
                rpTime = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                rpTime = "1 hour ago"
            } else {
                rpTime = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                rpTime = "1 day ago"
            } else {
                rpTime = "\(difference.day!) days ago"
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            rpTime = createdDate.string(from: self.contentObjects[indexPath.row].createdAt!)
        }
        
        // (II) Layout content
        if self.ephemeralTypes.contains(self.contentObjects[indexPath.row].value(forKeyPath: "contentType") as! String) {
            // ****************************************************************************************************************
            // MOMENTS, SPACE POSTS, SHARED POSTS *****************************************************************************
            // ****************************************************************************************************************
            
            // High level configurations
            // Configure IconicPreview by laying out views
            eCell.iconicPreview.layoutIfNeeded()
            eCell.iconicPreview.layoutSubviews()
            eCell.iconicPreview.setNeedsLayout()
            eCell.iconicPreview.layer.cornerRadius = eCell.iconicPreview.frame.size.width/2
            eCell.iconicPreview.layer.borderColor = UIColor.clear.cgColor
            eCell.iconicPreview.layer.borderWidth = 0.00
            eCell.iconicPreview.contentMode = .scaleAspectFill
            eCell.iconicPreview.clipsToBounds = true
            
            // (1) Set contentObject and user's object
            eCell.postObject = self.contentObjects[indexPath.row]
            
            // (2) Configure time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            eCell.time.text! = "\(timeFormatter.string(from: self.contentObjects[indexPath.row].createdAt!))"
            
            // (3) Layout content
            // (3A) MOMENT
            if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                
                // Make iconicPreview circular with red border color
                eCell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                eCell.iconicPreview.layer.borderWidth = 3.50
                
                if let still = self.contentObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // STILL PHOTO
                    still.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            eCell.iconicPreview.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else if let videoFile = self.contentObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // VIDEO
                    let videoUrl = NSURL(string: videoFile.url!)
                    do {
                        let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        eCell.iconicPreview.image = UIImage(cgImage: cgImage)
                        
                        // MARK: - SDWebImage
                        eCell.iconicPreview.sd_setImage(with: URL(string: videoFile.url!), placeholderImage: UIImage(cgImage: cgImage))
                        
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
                }
                
                // (3B) SPACE POST
            } else if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "CSpacePost")
                
                // (3C) SHARED POSTS
            } else if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "SharedPostIcon")
            }
            
            return eCell // return EphemeralCell.swift
            
        } else if contentObjects[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            // ****************************************************************************************************************
            // TEXT POST ******************************************************************************************************
            // ****************************************************************************************************************
            // (1) Set Text Post
            tpCell.textPost.text! = self.contentObjects[indexPath.row].value(forKey: "textPost") as! String
            
            // (2) Set time
            tpCell.time.text! = rpTime!
            
            // (3) Set post object
            tpCell.postObject = self.contentObjects[indexPath.row]
            
            // (4) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.contentObjects[indexPath.row].objectId!)
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
            comments.whereKey("forObjectId", equalTo: self.contentObjects[indexPath.row].objectId!)
            comments.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.comments.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.comments.append(object)
                    }
                    
                    if self.comments.count == 0 {
                        tpCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if self.comments.count == 1 {
                        tpCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        tpCell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.contentObjects[indexPath.row])
            shares.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.shares.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.shares.append(object)
                    }
                    
                    if self.shares.count == 0 {
                        tpCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if self.shares.count == 1 {
                        tpCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        tpCell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            return tpCell   // return TimeTextPostCell.swift
            
        } else {
            // ****************************************************************************************************************
            // PHOTOS, PROFILE PHOTOS, VIDEOS *********************************************************************************
            // ****************************************************************************************************************
            // (1) Set post object
            mCell.postObject = self.contentObjects[indexPath.row]
            
            // (2) Fetch Photo or Video
            // PHOTO
            
            if let photo = self.contentObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        mCell.mediaAsset.contentMode = .scaleAspectFit
                        mCell.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                // MARK: - SDWebImage
                let fileURL = URL(string: photo.url!)
                mCell.mediaAsset.sd_setImage(with: fileURL, placeholderImage: nil)
                
            } else if let videoFile = self.contentObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // VIDEO
                
                // LayoutViews
                mCell.mediaAsset.layoutIfNeeded()
                mCell.mediaAsset.layoutSubviews()
                mCell.mediaAsset.setNeedsLayout()
                
                // Make Vide Preview Circular
                mCell.mediaAsset.layer.cornerRadius = mCell.mediaAsset.frame.size.width/2
                mCell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                mCell.mediaAsset.layer.borderWidth = 3.50
                mCell.mediaAsset.clipsToBounds = true
                
                let videoUrl = NSURL(string: videoFile.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    mCell.mediaAsset.contentMode = .scaleAspectFill
                    mCell.mediaAsset.image = UIImage(cgImage: cgImage)
                    
                    // MARK: - SDWebImage
                    mCell.mediaAsset.sd_setImage(with: URL(string: videoFile.url!), placeholderImage: UIImage(cgImage: cgImage))
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // (2) Handle caption (text post) if it exists
            if let caption = self.contentObjects[indexPath.row].value(forKey: "textPost") as? String {
                mCell.textPost.text! = caption
            } else {
                mCell.textPost.isHidden = true
            }
            
            // (3) Set time
            mCell.time.text! = rpTime!
            
            // (4) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.contentObjects[indexPath.row].objectId!)
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
            comments.whereKey("forObjectId", equalTo: self.contentObjects[indexPath.row].objectId!)
            comments.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.comments.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.comments.append(object)
                    }
                    
                    if self.comments.count == 0 {
                        mCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if self.comments.count == 1 {
                        mCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        mCell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.contentObjects[indexPath.row])
            shares.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.shares.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.shares.append(object)
                    }
                    
                    if self.shares.count == 0 {
                        mCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if self.shares.count == 1 {
                        mCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        mCell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            // (5) Add tap methods
            mCell.layoutTap()
            
            return mCell // return TimeMediaCell
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
        if page <= self.contentObjects.count + self.skipped.count {
            
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
