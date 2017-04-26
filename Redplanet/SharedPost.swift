//
//  SharedPost.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/11/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SVProgressHUD
import SDWebImage

// Array to hold the sharedObject
var sharedObject = [PFObject]()

// Define notification
let sharedPostNotification = Notification.Name("sharedPostNotification")

class SharedPost: UITableViewController, UINavigationControllerDelegate {
    
    // MARK: - RPPopUpVCDelegate
    var delegate: RPPopUpVCDelegate!
    
    // String variable to create textpost
    var layoutText: String?
    
    // Arrays to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        sharedObject.removeAll(keepingCapacity: false)
//        // Dismiss VC
//        self.navigationController?.dismiss(animated: true, completion: nil)
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        self.refresher.endRefreshing()

        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to fetch the shared object
    func fetchInteractions() {
        
        // (1) Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.includeKey("fromUser")
        likes.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                
                
                
                // (2) Fetch comments
                let comments = PFQuery(className: "Comments")
                comments.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
                comments.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        // Append object
                        for object in objects! {
                            self.comments.append(object)
                        }
                        
                        
                        
                        // (3) Fetch shares
                        let newsfeeds = PFQuery(className: "Newsfeeds")
                        newsfeeds.whereKey("contentType", equalTo: "sh")
                        newsfeeds.whereKey("pointObject", equalTo: sharedObject.last!)
                        newsfeeds.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // Clear array
                                self.shares.removeAll(keepingCapacity: false)
                                
                                // Append object
                                for object in objects! {
                                    self.shares.append(object)
                                }
                                
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                            
                            // Reload data
                            self.tableView!.reloadData()
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                    // Reload data
                    self.tableView!.reloadData()
                })
                
                
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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Shared Post"
        }
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - MainTabUI
        // Hide button
        rpButton.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Stylize navigation bar
        configureView()
        // Fetch interactions
        fetchInteractions()
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        // Set tableView height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 470
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Extend edges
         self.extendedLayoutIncludesOpaqueBars = true
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: sharedPostNotification, object: nil)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(backSwipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title
        configureView()
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
        // StatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - MainTabUI
        // Show button
        rpButton.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // Function to calculate how many new lines UILabel should create before laying out the text
    func createText() -> String? {
        
        if let content = sharedObject.last!.value(forKey: "pointObject") as? PFObject {
            // Check for textPost & handle optional chaining
            if content.value(forKey: "textPost") != nil && content.value(forKey: "contentType") as! String != "itm" {
                // Caption exists
                // Calculate screen height
                if UIScreen.main.nativeBounds.height == 960 {
                    // iPhone 4
                    self.layoutText = "\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                } else if UIScreen.main.nativeBounds.height == 1136 {
                    // iPhone 5 √
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                } else if UIScreen.main.nativeBounds.height == 1334 {
                    // iPhone 6 √
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                    // iPhone 6+ √
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                }
                
            } else {
                // Caption DOES NOT exist
                // Calculate screen height
                if UIScreen.main.nativeBounds.height == 960 {
                    // iPhone 4
                    self.layoutText = "\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 1136 {
                    // iPhone 5
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 1334 {
                    // iPhone 6
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                    // iPhone 6+
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n"
                }
            }
            
        }
        
    
        return layoutText!
    }
    
    

    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 470
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sharedPostCell", for: indexPath) as! SharedPostCell
        
        // Set bounds
        cell.contentView.frame = cell.contentView.frame

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        cell.fromRpUserProPic.makeCircular(imageView: cell.fromRpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Design border for shared content
        cell.container.layer.borderColor = UIColor.lightGray.cgColor
        cell.container.layer.cornerRadius = 8.00
        cell.container.layer.borderWidth = 0.50
        cell.container.clipsToBounds = true
        
        // Clip mediaAsset
        cell.mediaAsset.clipsToBounds = true
        
        
        // Set parent VC delegate
        cell.delegate = self
        
        // (1) USER WHO SHARED THE POST
        if let user = sharedObject.last!.value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.fromRpUsername.text! = user["username"] as! String
            
            // (B) Get user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                // MARK: - SDWebImage
                cell.fromRpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (C) Set fromUser's object
            cell.fromUserObject = user
        }
        
        // (2) TIME THE POST WAS SHARED
        let from = sharedObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.sharedTime.text = difference.getFullTime(difference: difference, date: from)
        // Enable/Disable button depending on "saved" Boolean and time of reference
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                cell.sharedTime.text = "1 day ago"
            } else {
                cell.sharedTime.text = "\(difference.day!) days ago"
            }
            if sharedObject.last!.value(forKey: "saved") as! Bool == true {
                cell.likeButton.isUserInteractionEnabled = false
                cell.numberOfLikes.isUserInteractionEnabled = false
                cell.commentButton.isUserInteractionEnabled = false
                cell.numberOfComments.isUserInteractionEnabled = false
                cell.shareButton.isUserInteractionEnabled = false
                cell.numberOfShares.isUserInteractionEnabled = false
                cell.container.isUserInteractionEnabled = false
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            cell.sharedTime.text = createdDate.string(from: sharedObject.last!.createdAt!)
            if sharedObject.last!.value(forKey: "saved") as! Bool == true {
                cell.likeButton.isUserInteractionEnabled = false
                cell.numberOfLikes.isUserInteractionEnabled = false
                cell.commentButton.isUserInteractionEnabled = false
                cell.numberOfComments.isUserInteractionEnabled = false
                cell.shareButton.isUserInteractionEnabled = false
                cell.numberOfShares.isUserInteractionEnabled = false
                cell.container.isUserInteractionEnabled = false
            }
        }
        
        // Content
        // Fetch content
        if let content = sharedObject.last!.value(forKey: "pointObject") as? PFObject {
            // Hide both objects
            cell.mediaAsset.isHidden = true
            cell.textPost.isHidden = true
            
            // (4) Set shared content's object
            cell.cellSharedObject = content
            
            // (1) Get user's object
            if let user = content["byUser"] as? PFUser {
                user.fetchIfNeededInBackground(block: {
                    (object: PFObject?, error: Error?) in
                    if error == nil {
                        // (A) Set username
                        cell.rpUsername.text! = object!["username"] as! String
                        
                        // (B) Get user's profile photo
                        if let proPic = object!["userProfilePicture"] as? PFFile {
                            // MARK: - SDWebImage
                            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                        }
                        
                        // (C) Set byUser's object
                        cell.byUserObject = object
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }

            // (2) Fetch content
            // Create text
            _ = self.createText()
            
            // ==============================================================================================================
            // TEXT POST ====================================================================================================
            // ==============================================================================================================
            if content["contentType"] as! String == "tp" {
                // Show text post
                cell.textPost.isHidden = false
                // Text post
                cell.textPost.text! = content["textPost"] as! String
            }
            
            // ==============================================================================================================
            // PHOTO,  PROFILE PHOTO,    &   ITM ============================================================================
            // ==============================================================================================================
            if content["contentType"] as! String == "ph" || content["contentType"] as! String == "pp" || content["contentType"] as! String == "itm" {
                
                // (A) Configure photo
                cell.mediaAsset.layer.cornerRadius = 0.0
                cell.mediaAsset.layer.borderColor = UIColor.clear.cgColor
                cell.mediaAsset.layer.borderWidth = 0.0
                cell.mediaAsset.contentMode = .scaleAspectFill
                cell.mediaAsset.isHidden = false
                cell.mediaAsset.clipsToBounds = true
                
                // (A) Fetch photo
                if let photo = content.value(forKey: "photoAsset") as? PFFile {
                    // MARK: - SDWebImage
                    cell.mediaAsset.sd_setImage(with: URL(string: photo.url!), placeholderImage: cell.mediaAsset.image)
                }
                
                // (B) Configure Text
                cell.textPost.isHidden = false
                cell.textPost.text! = self.layoutText!
            }
            
            // ==============================================================================================================
            // VIDEO ========================================================================================================
            // ==============================================================================================================
            if content["contentType"] as! String == "vi" || content["contentType"] as! String == "itm" && content["videoAsset"] != nil {
                // (A) Stylize video preview
                cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
                cell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                cell.mediaAsset.layer.borderWidth = 3.50
                cell.mediaAsset.contentMode = .scaleAspectFill
                cell.mediaAsset.isHidden = false
                cell.mediaAsset.clipsToBounds = true

                // (B) Fetch video thumbnail
                if let videoFile = content.value(forKey: "videoAsset") as? PFFile {
                // VIDEO
                    // LayoutViews
                    cell.mediaAsset.layoutIfNeeded()
                    cell.mediaAsset.layoutSubviews()
                    cell.mediaAsset.setNeedsLayout()

                    // MARK: - SDWebImage
                    cell.mediaAsset.sd_setShowActivityIndicatorView(true)
                    cell.mediaAsset.sd_setIndicatorStyle(.gray)
                    
                    // Load Video Preview and Play Video
                    let player = AVPlayer(url: URL(string: videoFile.url!)!)
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.frame = cell.bounds
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    cell.mediaAsset.contentMode = .scaleToFill
                    cell.mediaAsset.layer.addSublayer(playerLayer)
                    player.isMuted = true
                    player.play()
                }
                
                // (C) Configure Text
                cell.textPost.isHidden = false
                cell.textPost.text! = self.layoutText!
            }
            // ==============================================================================================================
            // SPACE POST ===================================================================================================
            // ==============================================================================================================
            if content["contentType"] as! String == "sp" {
                
                // (1) PHOTO
                if content["photoAsset"] != nil {
                    
                    // (A) Configure photo
                    cell.mediaAsset.layer.cornerRadius = 0.0
                    cell.mediaAsset.layer.borderColor = UIColor.clear.cgColor
                    cell.mediaAsset.layer.borderWidth = 0.0
                    cell.mediaAsset.contentMode = .scaleAspectFill
                    cell.mediaAsset.isHidden = false
                    cell.mediaAsset.clipsToBounds = true
                    
                    // (A) Fetch photo
                    if let photo = content["photoAsset"] as? PFFile {
                        // MARK: - SDWebImage
                        cell.mediaAsset.sd_setImage(with: URL(string: photo.url!), placeholderImage: cell.mediaAsset.image)
                    }
                    
                    // (B) Configure Text
                    cell.textPost.isHidden = false
                    cell.textPost.text! = self.layoutText!
                } else if content["videoAsset"] != nil {
                    
                    // (2) VIDEO
                    
                    // (A) Stylize video preview
                    cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
                    cell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    cell.mediaAsset.layer.borderWidth = 3.50
                    cell.mediaAsset.contentMode = .scaleAspectFill
                    cell.mediaAsset.isHidden = false
                    cell.mediaAsset.clipsToBounds = true

                    // (B) Fetch video thumbnail
                    if let videoFile = content["videoAsset"] as? PFFile {
                        // LayoutViews
                        cell.mediaAsset.layoutIfNeeded()
                        cell.mediaAsset.layoutSubviews()
                        cell.mediaAsset.setNeedsLayout()
                        
                        // MARK: - SDWebImage
                        cell.mediaAsset.sd_setShowActivityIndicatorView(true)
                        cell.mediaAsset.sd_setIndicatorStyle(.gray)
                        
                        // Load Video Preview and Play Video
                        let player = AVPlayer(url: URL(string: videoFile.url!)!)
                        let playerLayer = AVPlayerLayer(player: player)
                        playerLayer.frame = cell.mediaAsset.bounds
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        cell.mediaAsset.contentMode = .scaleAspectFit
                        cell.mediaAsset.layer.addSublayer(playerLayer)
                    }
                    
                    // (C) Configure Text
                    cell.textPost.isHidden = false
                    cell.textPost.text! = self.layoutText!
                    
                } else {
                    // Add lines for sizing constraints
                    cell.textPost.isHidden = false
                    cell.textPost.text! = "\(content["textPost"] as! String)"
                }
            }
            
            
            // (3) set time
            let from = content.createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPHelpers
            cell.time.text = difference.getFullTime(difference: difference, date: from)   
        }
        
        
        
        // Set Like Button
        if self.likes.contains(where: {$0.objectId == PFUser.current()!.objectId! }) {
            cell.likeButton.setTitle("liked", for: .normal)
            cell.likeButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
        } else {
            cell.likeButton.setTitle("notLiked", for: .normal)
            cell.likeButton.setImage(UIImage(named: "Like"), for: .normal)
        }
        
        // Set numberOfLikes
        if self.likes.count == 0 {
            cell.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        
        // Set numberOfComments
        if self.comments.count == 0 {
            cell.numberOfComments.setTitle("comments", for: .normal)
        } else if self.comments.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
        }
        
        // Set numberOfShares
        if self.shares.count == 0 {
            cell.numberOfShares.setTitle("shares", for: .normal)
        } else if self.shares.count == 1 {
            cell.numberOfShares.setTitle("1 share", for: .normal)
        } else {
            cell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
        }

        return cell
        
    } // end cellForRowAt
    
}
