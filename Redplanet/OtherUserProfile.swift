//
//  OtherUserProfile.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SimpleAlert


// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()


// Define identifier
let otherNotification = Notification.Name("otherUser")


class OtherUserProfile: UICollectionViewController, UINavigationControllerDelegate {
    
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

    
    // Array to hold other user's space posts
    var spaceObjects = [PFObject]()
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Page size
    var page: Int = 50
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    
    
    // View to cover collectionView when hidden swift
    let cover = UIButton()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        
        // Remove last
        otherObject.removeLast()
        otherName.removeLast()
        
        // Pop view controller
        _ = _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var moreButton: UIBarButtonItem!
    @IBAction func moreButton(_ sender: AnyObject) {
        
        // MARK: - SimpleAlert
        let alert = AlertController(title: "Options",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
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
        if myFriends.contains(otherObject.last!) {
            alert.addAction(space)
            alert.addAction(chat)
            alert.addAction(reportOrBlock)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        } else {
            alert.addAction(chat)
            alert.addAction(reportOrBlock)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
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
                    if object.value(forKey: "contentType") as! String == "itm" {
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
                    
                    if myFriends.contains(otherObject.last!) {
                        // FRIENDS
                        print("Don't hide because FRIENDS")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNo Posts Yet\n", for: .normal)
                            self.collectionView!.addSubview(self.cover)
                            self.collectionView!.allowsSelection = false
                        }
                        
                    } else if myRequestedFriends.contains(otherObject.last!) || requestedToFriendMe.contains(otherObject.last!) {
                        // FRIEND REQUESTED
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                        
                    } else if myFollowers.contains(otherObject.last!) && !myFollowing.contains(otherObject.last!) {
                        // FOLLOWER ONLY
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                        
                    } else if myRequestedFollowers.contains(otherObject.last!) {
                        // CONFIRM FOLLOW REQUEST
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                        
                    } else if myFollowing.contains(otherObject.last!) {
                        // FOLLOWING
                        print("Don't hide because FOLLOWING")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNo Posts Yet\n", for: .normal)
                            self.collectionView!.addSubview(self.cover)
                            self.collectionView!.allowsSelection = false
                        }
                        
                    } else if myRequestedFollowing.contains(otherObject.last!) {
                        // FOLLOW REQUESTED
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                        
                    } else if myFollowers.contains(otherObject.last!) && myFollowing.contains(otherObject.last!) {
                        // FOLLOWER & FOLLOWING
                        print("Don't hide because FOLLOWING")
                        if self.contentObjects.count == 0 {
                            self.cover.setTitle("🤔\nNo Posts Yet\n", for: .normal)
                            self.collectionView!.addSubview(self.cover)
                            self.collectionView!.allowsSelection = false
                        }
                        
                    } else {
                        // Not yet connected
                        self.cover.setTitle("🔒\nPrivate Account.\nAdd your friends. Follow the things you love.", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                    }
                    
                } else {
                    // PUBLIC ACCOUNT
                    if self.contentObjects.count == 0 {
                        self.cover.setTitle("🤔\nNo Posts Yet\n", for: .normal)
                        self.collectionView!.addSubview(self.cover)
                        self.collectionView!.allowsSelection = false
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
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
        self.collectionView!.reloadData()
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize and set title
        configureView()
        
        // Query content
        queryContent()
        
        // Set collectionview's cell size
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width, height: 65.00)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: otherNotification, object: nil)
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        
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
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 356, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        // Set fullname
        let fullName = otherObject.last!.value(forKey: "realNameOfUser") as! String
        if otherObject.last!.value(forKey: "userBiography") != nil {
            label.text = "\(fullName.uppercased())\n\(otherObject.last!.value(forKey: "userBiography") as! String)"
        } else {
            label.text = "\(fullName.uppercased())"
        }
        
        // Set label's dynamic height
        label.sizeToFit()

        
        // Add cover
        self.cover.frame = CGRect(x: 0, y: CGFloat(426 + label.frame.size.height), width: self.collectionView!.frame.size.width, height: self.collectionView!.frame.size.height+426+label.frame.size.height)
        self.cover.isUserInteractionEnabled = false
        self.cover.isEnabled = false
        self.cover.titleLabel!.lineBreakMode = .byWordWrapping
        self.cover.contentVerticalAlignment = .top
        self.cover.contentHorizontalAlignment = .center
        self.cover.titleLabel!.textAlignment = .center
        self.cover.titleLabel!.font = UIFont(name: "AvenirNext-Medium", size: 15)
        self.cover.setTitleColor(UIColor.darkGray, for: .normal)
        self.cover.backgroundColor = UIColor.white
        
        
        // Size should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: CGFloat(425 + label.frame.size.height))
    }

    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! OtherUserHeader
        
        
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
        
        
        // Friend Requested
        if myRequestedFriends.contains(where: {$0.objectId == otherObject.last!.objectId!} ) || requestedToFriendMe.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            // FRIEND REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Friend Requested", for: .normal)
        }
        
        
        // Follower
        if myFollowers.contains(where: {$0.objectId == otherObject.last!.objectId!}) && !myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            // FOLLOWER
            header.relationType.isHidden = false
            header.relationType.setTitle("Follower", for: .normal)
            
        }
        
        
        // Following
        if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            // FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        
        // Follow Requested
            if myRequestedFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) || myRequestedFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
            // FOLLOW REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Follow Requested", for: .normal)
        }
        
        
        // Following
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
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.contentObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        print("Returning: \(contentObjects.count) count")
        return CGSize(width: self.view.frame.size.width, height: 105)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherContentCell", for: indexPath) as! OtherContentCell
        
        
        
        // LayoutViews for rpUserProPic
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // LayoutViews for iconicPreview
        cell.iconicPreview.layoutIfNeeded()
        cell.iconicPreview.layoutSubviews()
        cell.iconicPreview.setNeedsLayout()
        
        // Set iconicPreview default configs
        cell.iconicPreview.layer.borderColor = UIColor.clear.cgColor
        cell.iconicPreview.layer.borderWidth = 0.00
        cell.iconicPreview.contentMode = .scaleAspectFill
        
        // Set name's layout
        cell.rpUsername.sizeToFit()
        
    
        // Configure the cell
        contentObjects[indexPath.row].fetchIfNeededInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (1) Get user's object
                if let user = object!["byUser"] as? PFUser {
                    
                    // (A) Username
                    cell.rpUsername.text! = user.value(forKey: "realNameOfUser") as! String
                    
                    // (B) Profile Photo
                    // Handle optional chaining for user's profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }

                }
                
                
                
                // *************************************************************************************************************************
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "ph" {
                    
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Fetch photo
                    if let photo = object!["photoAsset"] as? PFFile {
                        photo.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Show iconicPreview
                                cell.iconicPreview.isHidden = false
                                // Set media
                                cell.iconicPreview.image = UIImage(data: data!)
                                
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                // (B) Text Post
                if object!["contentType"] as! String == "tp" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    // Set iconicPreview's icon
                    cell.iconicPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                if object!["contentType"] as! String == "sh" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "SharedPostIcon")
                }
                
                
                
                
                
                // (D) Profile Photo
                if object!["contentType"] as! String == "pp" {
                    
                    // Make iconicPreview circular
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.layer.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    
                    // Fetch Profile photo
                    if let iconicPreview = object!["photoAsset"] as? PFFile {
                        iconicPreview.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Show iconicPreview
                                cell.iconicPreview.isHidden = false
                                // Set media
                                cell.iconicPreview.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                
                
                // (E) In the moment
                if object!["contentType"] as! String == "itm" {
                    
                    // Make iconicPreview circular with red border color
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                    cell.iconicPreview.layer.borderWidth = 3.50
                    cell.iconicPreview.contentMode = .scaleAspectFill
                    cell.iconicPreview.clipsToBounds = true
                    
                    if object!["photoAsset"] != nil {
                        
                        // Fetch photo
                        if let itm = object!["photoAsset"] as? PFFile {
                            itm.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                        
                    } else if object!["videoAsset"] != nil {
                        // (2) Get video preview
                        if let videoFile = object!["videoAsset"] as? PFFile {
                            let videoUrl = NSURL(string: videoFile.url!)
                            do {
                                let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                                let imgGenerator = AVAssetImageGenerator(asset: asset)
                                imgGenerator.appliesPreferredTrackTransform = true
                                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                                cell.iconicPreview.image = UIImage(cgImage: cgImage)
                                
                            } catch let error {
                                print("*** Error generating thumbnail: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                }
                
                
                
                // (F) Space Post
                if object!["contentType"] as! String == "sp" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "SpacePost")
                }
                
                
                // (G) Video
                if object!["contentType"] as! String == "vi" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "VideoIcon")
                }
                
                // ***********************************************************************************************************************
                
                
                
                // (3) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "right now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    if difference.second! == 1 {
                        cell.time.text = "1 second ago"
                    } else {
                        cell.time.text = "\(difference.second!) seconds ago"
                    }
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    if difference.minute! == 1 {
                        cell.time.text = "1 minute ago"
                    } else {
                        cell.time.text = "\(difference.minute!) minutes ago"
                    }
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    if difference.hour! == 1 {
                        cell.time.text = "1 hour ago"
                    } else {
                        cell.time.text = "\(difference.hour!) hours ago"
                    }
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    if difference.day! == 1 {
                        cell.time.text = "1 day ago"
                    } else {
                        cell.time.text = "\(difference.day!) days ago"
                    }
                }
                
                if difference.weekOfMonth! > 0 {
                    let createdDate = DateFormatter()
                    createdDate.dateFormat = "MMM d, yyyy"
                    cell.time.text = createdDate.string(from: object!.createdAt!)
                }
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    
        return cell
    }

    
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Save to Views
        let view = PFObject(className: "Views")
        view["byUser"] = PFUser.current()!
        view["username"] = PFUser.current()!.username!
        view["forObjectId"] = self.contentObjects[indexPath.row].objectId!
        view.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if error == nil {
                
                // TEXT POST
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                    // Append Object
                    textPostObject.append(self.contentObjects[indexPath.row])
                    
                    
                    // Present VC
                    let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                    self.navigationController?.pushViewController(textPostVC, animated: true)
                }
                
                // PHOTO
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "ph" {
                    // Append Object
                    photoAssetObject.append(self.contentObjects[indexPath.row])
                    
                    // Present VC
                    let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                    self.navigationController?.pushViewController(photoVC, animated: true)
                }
                
                // SHARED
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                    
                    // Append object
                    sharedObject.append(self.contentObjects[indexPath.row])
                    // Push VC
                    let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                    self.navigationController?.pushViewController(sharedPostVC, animated: true)
                    
                }
                
                
                // PROFILE PHOTO
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "pp" {
                    // Append user's object
                    otherObject.append(self.contentObjects[indexPath.row].value(forKey: "byUser") as! PFUser)
                    // Append user's username
                    otherName.append(self.contentObjects[indexPath.row].value(forKey: "username") as! String)
                    
                    // Append object
                    proPicObject.append(self.contentObjects[indexPath.row])
                    
                    // Push VC
                    let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                    self.navigationController?.pushViewController(proPicVC, animated: true)
                    
                }
                
                
                // SPACE POST
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                    // Append object
                    spaceObject.append(self.contentObjects[indexPath.row])
                    
                    // Append otherObject
                    otherObject.append(self.contentObjects[indexPath.row].value(forKey: "toUser") as! PFUser)
                    
                    // Append otherName
                    otherName.append(self.contentObjects[indexPath.row].value(forKey: "toUsername") as! String)
                    
                    // Push VC
                    let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                    self.navigationController?.pushViewController(spacePostVC, animated: true)
                }
                
                
                // ITM
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                    // Append content object
                    itmObject.append(self.contentObjects[indexPath.row])
                    
                    // PHOTO
                    if self.contentObjects[indexPath.row].value(forKey: "photoAsset") != nil {
                        // Push VC
                        let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                        self.navigationController?.pushViewController(itmVC, animated: true)
                    } else {
                        // VIDEO
                        // Push VC
                        let momentVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                        self.navigationController?.pushViewController(momentVideoVC, animated: true)
                    }
                }
                
                
                // VIDEO
                if self.contentObjects[indexPath.row].value(forKey: "contentType") as! String == "vi" {
                    // Append content object
                    videoObject.append(self.contentObjects[indexPath.row])
                    
                    // Push VC
                    let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                    self.navigationController?.pushViewController(videoVC, animated: true)
                }

                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
    } // end didSelectRow
    
    
    
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // Load more content
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.contentObjects.count + self.skipped.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query content
            // ISSUE:
            // CAUSES BUGS
            queryContent()
            
        }
    }
    

}
