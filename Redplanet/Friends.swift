//
//  Friends.swift
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
import OneSignal
import SimpleAlert
import SVProgressHUD
import SDWebImage



class Friends: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Array to hold friends, posts, and skipped objects
    var friends = [PFObject]()
    var posts = [PFObject]()
    var likesPerPost = [Int]()
    var commentsPerPost = [Int]()
    var sharesPerPost = [Int]()
    var skipped = [PFObject]()
    
    // Pipeline method
    var page: Int = 50
    
    // Parent Navigator
    var parentNavigator: UINavigationController!
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
    var likes = [PFObject]()
    
    // Function to refresh data
    func refresh() {
        fetchPosts()
        self.refresher.endRefreshing()
    }
    
    // Function to fetch friends
    func fetchFriends() {
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [fFriends, eFriends])
        friends.includeKeys(["endFriend", "frontFriend"])
        friends.whereKey("isFriends", equalTo: true)
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if (object.object(forKey: "frontFriend") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        // Append end friend
                        self.friends.append(object.object(forKey: "endFriend") as! PFUser)
                    } else {
                        // Append front friend
                        self.friends.append(object.object(forKey: "frontFriend") as! PFUser)
                    }
                }
                
                // Fetch Posts
                self.fetchPosts()
                
            } else {
                if (error?.localizedDescription.hasSuffix("offline."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            
        })
        
    }
    
    
    
    func fetchPosts() {
        // Get News Feed content
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: self.friends)
        newsfeeds.includeKeys(["byUser", "pointObject", "toUser"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.limit = self.page
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Ephemeral content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if self.ephemeralTypes.contains(object.value(forKey: "contentType") as! String) {
                        if difference.hour! < 24 {
                            self.posts.append(object)
                        } else {
                            self.skipped.append(object)
                        }
                    } else {
                        self.posts.append(object)
                    }
                }
                
                // Set DZN
                if self.posts.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                if (error?.localizedDescription.hasSuffix("offline."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.clear)
        SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
        
        // Fetch friends
        fetchFriends()
        
        // Configure table view
        self.tableView?.estimatedRowHeight = 658
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView?.tableFooterView = UIView()
        
        // Set tabBarController delegate
        self.parentNavigator.tabBarController?.delegate = self
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Define Notification to reload data
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
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
        if self.posts.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nYour Friends' News Feed is empty."
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Redplanet is more fun with your friends."
        let font = UIFont(name: "AvenirNext-Medium", size: 17.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find My Friends"
        let font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // If iOS 9
        if #available(iOS 9, *) {
            // Push VC
            let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
            self.parentNavigator.pushViewController(contactsVC, animated: true)
        } else {
            // Fallback on earlier versions
            // Show search
            let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
            self.parentNavigator.pushViewController(search, animated: true)
        }
    }
    
    // MARK: - TabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if self.parentNavigator.tabBarController?.selectedIndex == 0 {
            // Scroll to top
            self.tableView!.setContentOffset(CGPoint.zero, animated: true)
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
        if self.ephemeralTypes.contains(self.posts[indexPath.row].value(forKeyPath: "contentType") as! String) {
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
        let ppCell = Bundle.main.loadNibNamed("ProPicCell", owner: self, options: nil)?.first as! ProPicCell
        let vCell = Bundle.main.loadNibNamed("TimeVideoCell", owner: self, options: nil)?.first as! TimeVideoCell
        
        // Initialize all level configurations: rpUserProPic && rpUsername
        let proPics = [eCell.rpUserProPic, tpCell.rpUserProPic, mCell.rpUserProPic, ppCell.smallProPic, vCell.rpUserProPic]
        let usernames = [eCell.rpUsername, tpCell.rpUsername, mCell.rpUsername, ppCell.rpUsername, vCell.rpUsername]
        
        // Set parent vc's UINavigationController: delegate
        eCell.delegate = self.parentNavigator
        tpCell.delegate = self.parentNavigator
        ppCell.delegate = self.parentNavigator
        mCell.delegate = self.parentNavigator
        vCell.delegate = self.parentNavigator
        
        // I) FETCH USER'S PFObject: userProfilePicture, username/realNameOfUser, user's PFObject
        if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
            user.fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (A) userProfilePicture
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
                        if let proPic = object!["userProfilePicture"] as? PFFile {
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
                    
                    // (B) realNameOfUser for FRIENDS && username for FOLLOWING
                    for u in usernames {
                        u?.text! = user["realNameOfUser"] as! String
                    }
                    
                    // (C) User's Object
                    eCell.userObject = user
                    tpCell.userObject = user
                    mCell.userObject = user
                    ppCell.userObject = user
                    vCell.userObject = user
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        // II) CONFIGURE TIME FOR PHOTOS, PROFILE PHOTOS, VIDEOS, and TEXT POSTS
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        
        // III) LAYOUT CONTENT
        if self.posts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
        // ****************************************************************************************************************
        // TEXT POST ******************************************************************************************************
        // ****************************************************************************************************************
            
            // (1) Set Text Post
            tpCell.textPost.text! = self.posts[indexPath.row].value(forKey: "textPost") as! String
            
            // (2) Set time
            // logic what to show : Seconds, minutes, hours, days, or weeks
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

            
            // (3) Set post object
            tpCell.postObject = self.posts[indexPath.row]
            
            // (4) Fetch likes, comments, and shares
            // SET DEFAULTS:
            tpCell.numberOfLikes.setTitle("likes", for: .normal)
            tpCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            tpCell.numberOfComments.setTitle("comments", for: .normal)
            tpCell.numberOfShares.setTitle("shares", for: .normal)
            
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
            eCell.postObject = self.posts[indexPath.row]
            
            // (2) Configure time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            eCell.time.text! = "\(timeFormatter.string(from: self.posts[indexPath.row].createdAt!))"
            
            // (3) Layout content
            // (3A) MOMENT
            if self.posts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                
                // Make iconicPreview circular with red border color
                eCell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                eCell.iconicPreview.layer.borderWidth = 3.50
                
                if let still = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // STILL PHOTO
                    still.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            eCell.iconicPreview.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    // MARK: - SDWebImage
                    let fileURL = URL(string: still.url!)
                    eCell.iconicPreview.sd_setImage(with: fileURL, placeholderImage: eCell.iconicPreview.image)
                    
                } else if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
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
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "CSpacePost")
                
            // (3C) SHARED POSTS
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "SharedPostIcon")
            }
            
            return eCell // return EphemeralCell.swift
        
        } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "ph" {
        // ****************************************************************************************************************
        // PHOTOS *********************************************************************************************************
        // ****************************************************************************************************************
            // (1) Set post object
            mCell.postObject = self.posts[indexPath.row]
            
            // (2) Fetch photo
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
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
                mCell.mediaAsset.sd_setImage(with: fileURL, placeholderImage: mCell.mediaAsset.image)
            }
            
            // (2) Handle caption (text post) if it exists
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                mCell.textPost.text! = caption
            } else {
                mCell.textPost.isHidden = true
            }
            
            // (3) Set time
            // logic what to show : Seconds, minutes, hours, days, or weeks
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
            
            // (4) Fetch likes, comments, and shares
            // SET DEFAULTS:
            mCell.numberOfLikes.setTitle("likes", for: .normal)
            mCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            mCell.numberOfComments.setTitle("comments", for: .normal)
            mCell.numberOfShares.setTitle("shares", for: .normal)
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
            // (1) Set post object
            ppCell.postObject = self.posts[indexPath.row]
            
            // (2) Fetch Profile Photo
            // LayoutViews
            ppCell.rpUserProPic.layoutIfNeeded()
            ppCell.rpUserProPic.layoutSubviews()
            ppCell.rpUserProPic.setNeedsLayout()
            
            // Make Vide Preview Circular
            ppCell.rpUserProPic.layer.cornerRadius = ppCell.rpUserProPic.frame.size.width/2
            ppCell.rpUserProPic.layer.borderColor = UIColor.darkGray.cgColor
            ppCell.rpUserProPic.layer.borderWidth = 1.50
            ppCell.rpUserProPic.clipsToBounds = true
            
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        ppCell.rpUserProPic.contentMode = .scaleAspectFit
                        ppCell.rpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                // MARK: - SDWebImage
                let fileURL = URL(string: photo.url!)
                ppCell.rpUserProPic.sd_setImage(with: fileURL, placeholderImage: mCell.mediaAsset.image)
                
            }
            
            // (2) Handle caption (text post) if it exists
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                ppCell.textPost.text! = caption
            } else {
                ppCell.textPost.isHidden = true
            }
            
            // (3) Set time
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                ppCell.time.text! = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    ppCell.time.text! = "1 second ago"
                } else {
                    ppCell.time.text! = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    ppCell.time.text! = "1 minute ago"
                } else {
                    ppCell.time.text! = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    ppCell.time.text! = "1 hour ago"
                } else {
                    ppCell.time.text! = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    ppCell.time.text! = "1 day ago"
                } else {
                    ppCell.time.text! = "\(difference.day!) days ago"
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                ppCell.time.text! = createdDate.string(from: self.posts[indexPath.row].createdAt!)
            }
            
            // (4) Fetch likes, comments, and shares
            // SET DEFAULTS:
            ppCell.numberOfLikes.setTitle("likes", for: .normal)
            ppCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            ppCell.numberOfComments.setTitle("comments", for: .normal)
            ppCell.numberOfShares.setTitle("shares", for: .normal)
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
            // (1) Set video's postObject: PFObject?
            vCell.postObject = self.posts[indexPath.row]
            
            // (2) Fetch Video Thumbnail
            if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // VIDEO
                
                // LayoutViews
                vCell.videoPreview.layoutIfNeeded()
                vCell.videoPreview.layoutSubviews()
                vCell.videoPreview.setNeedsLayout()
                
                // Make Vide Preview Circular
                vCell.videoPreview.layer.cornerRadius = vCell.videoPreview.frame.size.width/2
                vCell.videoPreview.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                vCell.videoPreview.layer.borderWidth = 3.50
                vCell.videoPreview.clipsToBounds = true
                
                let videoUrl = NSURL(string: videoFile.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    vCell.videoPreview.contentMode = .scaleAspectFill
                    vCell.videoPreview.image = UIImage(cgImage: cgImage)
                    
                    // MARK: - SDWebImage
                    vCell.videoPreview.sd_setImage(with: URL(string: videoFile.url!), placeholderImage: UIImage(cgImage: cgImage))
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // (3) Handle caption (text post) if it exists
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                vCell.textPost.text! = caption
            } else {
                vCell.textPost.isHidden = true
            }
            
            // (4) Set time
            // logic what to show : Seconds, minutes, hours, days, or weeks
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
            
            // (5) Fetch likes, comments, and shares
            // SET DEFAULTS:
            vCell.numberOfLikes.setTitle("likes", for: .normal)
            vCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            vCell.numberOfComments.setTitle("comments", for: .normal)
            vCell.numberOfShares.setTitle("shares", for: .normal)
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
    }//end cellForRowAt
    
    
    // MARK: RP's very own Pipeline Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.posts.count + self.skipped.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            fetchPosts()
        }
    }
}
