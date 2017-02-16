//
//  SavedPosts.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/14/17.
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

class SavedPosts: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate {

    // Saved Posts
    var posts = [PFObject]()
    var likes = [PFObject]()
    let ephemeralTypes = ["itm", "sh", "sp"]
    
    @IBAction func backButton(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func reload(_ sender: Any) {
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
                self.posts.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.posts.append(object)
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
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Saved Posts"
        }
        
        // Configure nav bar, show tab bar, and set statusBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.delegate = self
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch saved posts
        fetchSaved()
        
        // Layout
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        
        // Configure table view
        self.tableView!.estimatedRowHeight = 65.00
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            eCell.time.text! = "\(timeFormatter.string(from: self.posts[indexPath.row].createdAt!))"
            
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
                mCell.mediaAsset.layer.cornerRadius = 12.00
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
            ppCell.rpUserProPic.layoutIfNeeded()
            ppCell.rpUserProPic.layoutSubviews()
            ppCell.rpUserProPic.setNeedsLayout()
            
            // Make Vide Preview Circular
            ppCell.rpUserProPic.layer.cornerRadius = ppCell.rpUserProPic.frame.size.width/2
            ppCell.rpUserProPic.layer.borderColor = UIColor.darkGray.cgColor
            ppCell.rpUserProPic.layer.borderWidth = 1.50
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
                
                // LayoutViews
                vCell.videoPreview.layoutIfNeeded()
                vCell.videoPreview.layoutSubviews()
                vCell.videoPreview.setNeedsLayout()
                
                // Make Vide Preview Circular
                vCell.videoPreview.layer.cornerRadius = vCell.videoPreview.frame.size.width/2
                vCell.videoPreview.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                vCell.videoPreview.layer.borderWidth = 3.50
                // MARK: - SDWebImage
                vCell.videoPreview.sd_setShowActivityIndicatorView(true)
                vCell.videoPreview.sd_setIndicatorStyle(.gray)
                
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = vCell.videoPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                vCell.videoPreview.contentMode = .scaleAspectFit
                vCell.videoPreview.layer.addSublayer(playerLayer)
                player.isMuted = true
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
    }//end cellForRowAt

    
    

}