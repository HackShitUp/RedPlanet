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
import SimpleAlert


// Array to hold the sharedObject
var sharedObject = [PFObject]()

// Define notification
let sharedPostNotification = Notification.Name("sharedPostNotification")

class SharedPost: UITableViewController, UINavigationControllerDelegate {
    
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
        sharedObject.removeLast()
        
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch interactions
        fetchInteractions()

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
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    
        
        // Show the user what to do!
        let openedPost = UserDefaults.standard.bool(forKey: "DidOpenPost")
        if openedPost == false && sharedObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {

            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenPost")
            
            let alert = AlertController(title: "🎉\nCongrats, you viewed your first Shared Post!",
                                        message: "•Swipe down to leave\n•Swipe left for Views 🙈",
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
            
            let ok = AlertAction(title: "ok",
                                 style: .default,
                                 handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        
        

        // Fetch interactions
        fetchInteractions()
        
        // Stylize navigation bar
        configureView()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()

        // Set tableView height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 470
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Show navBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: sharedPostNotification, object: nil)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Stylize title
        configureView()
        
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                } else if UIScreen.main.nativeBounds.height == 1334 {
                    // iPhone 6 √
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                    // iPhone 6+ √
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(content["textPost"] as! String)"
                }
                
            } else {
                // Caption DOES NOT exist
                // Calculate screen height
                if UIScreen.main.nativeBounds.height == 960 {
                    // iPhone 4
                    self.layoutText = "\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 1136 {
                    // iPhone 5
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 1334 {
                    // iPhone 6
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n"
                } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                    // iPhone 6+
                    self.layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
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
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = 6.00
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // LayoutViews
        cell.fromRpUserProPic.layoutIfNeeded()
        cell.fromRpUserProPic.layoutSubviews()
        cell.fromRpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.fromRpUserProPic.layer.cornerRadius = cell.fromRpUserProPic.frame.size.width/2
        cell.fromRpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.fromRpUserProPic.layer.borderWidth = 0.5
        cell.fromRpUserProPic.clipsToBounds = true
        
        
        // Design border fpr shared content
        cell.container.layer.borderColor = UIColor.lightGray.cgColor
        cell.container.layer.cornerRadius = 8.00
        cell.container.layer.borderWidth = 0.50
        cell.container.clipsToBounds = true
        
        // Clip mediaAsset
        cell.mediaAsset.clipsToBounds = true
        
        
        // Set parent VC delegate
        cell.delegate = self

        
        
        // (1) Fetch user
        if let user = sharedObject.last!.value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.fromRpUsername.text! = user["username"] as! String
            
            // (B) Get user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set profile photo
                        cell.fromRpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                        // Set default
                        cell.fromRpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                    }
                })
            }
            
            // (C) Set fromUser's object
            cell.fromUserObject = user
        }
        
        // (2) set time
        let from = sharedObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            cell.sharedTime.text = "right now"
        }
        
        if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                cell.sharedTime.text = "1 second ago"
            } else {
                cell.sharedTime.text = "\(difference.second!) seconds ago"
            }
        }
        
        if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                cell.sharedTime.text = "1 minute ago"
            } else {
                cell.sharedTime.text = "\(difference.minute!) minutes ago"
            }
        }
        
        if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                cell.sharedTime.text = "1 hour ago"
            } else {
                cell.sharedTime.text = "\(difference.hour!) hours ago"
            }
        }
        
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                cell.sharedTime.text = "1 day ago"
            } else {
                cell.sharedTime.text = "\(difference.day!) days ago"
            }
        }
        
        if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            cell.sharedTime.text = createdDate.string(from: sharedObject.last!.createdAt!)
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
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
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
            
            
            // ============================================================================================================================
            // PHOTO,  PROFILE PHOTO,    &   ITM ==========================================================================================
            // ============================================================================================================================
            
            if content["contentType"] as! String == "ph" || content["contentType"] as! String == "pp" || content["contentType"] as! String == "itm" {
                
                // (A) Configure photo
                cell.mediaAsset.layer.cornerRadius = 0.0
                cell.mediaAsset.layer.borderColor = UIColor.clear.cgColor
                cell.mediaAsset.layer.borderWidth = 0.0
                cell.mediaAsset.contentMode = .scaleAspectFill
                cell.mediaAsset.isHidden = false
                cell.mediaAsset.clipsToBounds = true
                
                // (A) Fetch photo
                if let photo = content["photoAsset"] as? PFFile {
                    photo.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set Photo
                            cell.mediaAsset.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
                
                // (B) Configure Text
                cell.textPost.isHidden = false
                cell.textPost.text! = self.layoutText!
            }
            
            
            // ==============================================================================================================
            // VIDEO ========================================================================================================
            // ==============================================================================================================
            
            if content["contentType"] as! String == "vi" {
                // (A) Stylize video preview
                cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
                cell.mediaAsset.layer.borderColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0).cgColor
                cell.mediaAsset.layer.borderWidth = 3.50
                cell.mediaAsset.contentMode = .scaleAspectFill
                cell.mediaAsset.isHidden = false
                cell.mediaAsset.clipsToBounds = true
                
                // (B) Fetch video thumbnail
                if let video = sharedObject.last!.value(forKey: "videoAsset") as? PFFile {
                    let videoUrl = NSURL(string: video.url!)
                    do {
                        let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        cell.mediaAsset.image = UIImage(cgImage: cgImage)
                        
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
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
                        photo.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set Photo
                                cell.mediaAsset.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                    
                    // (B) Configure Text
                    cell.textPost.isHidden = false
                    cell.textPost.text! = self.layoutText!
                    
                    
                } else if content["videoAsset"] != nil {
                    
                    // (2) VIDEO
                    
                    // (A) Stylize video preview
                    cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
                    cell.mediaAsset.layer.borderColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0).cgColor
                    cell.mediaAsset.layer.borderWidth = 3.50
                    cell.mediaAsset.contentMode = .scaleAspectFill
                    cell.mediaAsset.isHidden = false
                    cell.mediaAsset.clipsToBounds = true
                    
                    // (B) Fetch video thumbnail
                    if let video = content["videoAsset"] as? PFFile {
                        let videoUrl = NSURL(string: video.url!)
                        do {
                            let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                            let imgGenerator = AVAssetImageGenerator(asset: asset)
                            imgGenerator.appliesPreferredTrackTransform = true
                            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                            cell.mediaAsset.image = UIImage(cgImage: cgImage)
                            
                        } catch let error {
                            print("*** Error generating thumbnail: \(error.localizedDescription)")
                        }
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
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.sharedTime.text = "right now"
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
                cell.time.text = createdDate.string(from: content.createdAt!)
            }
            
        } // end handling of optional chaining
        
        
        // Manipulate likes, comments, and shares
        
        // Set Like Button
//        if self.likes.contains(PFUser.current()!) {
        if self.likes.contains(where: { $0.objectId == "\(PFUser.current()!.objectId!)" }) {
            cell.likeButton.setTitle("liked", for: .normal)
            cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
        } else {
            cell.likeButton.setTitle("notLiked", for: .normal)
            cell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
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
    
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // (1) Delete Shared Post
        let delete = UITableViewRowAction(style: .normal,
                                          title: "X\nDelete") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            SVProgressHUD.show(withStatus: "Deleting")
                                            
                                            // Delete content
                                            let newsfeeds = PFQuery(className: "Newsfeeds")
                                            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
                                            newsfeeds.whereKey("objectId", equalTo: sharedObject.last!.objectId!)
                                            newsfeeds.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        // Delete object
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted object: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                                
                                                                // Reload newsfeed
                                                                NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                                
                                                                // Reload myProfile
                                                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                                
                                                                // Pop view controller
                                                                _ = self.navigationController?.popViewController(animated: true)
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                            
        }
        

        
        // (2) Views
        let views = UITableViewRowAction(style: .normal,
                                         title: "🙈\nViews") { (UITableViewRowAction, indexPath) in
                                            // Append object
                                            viewsObject.append(sharedObject.last!)
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
                                            
        }
        
        
        // (4) Report Content
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report",
                                                                          message: "Please provide your reason for reporting \(sharedObject.last!.value(forKey: "username") as! String)'s Share",
                                                preferredStyle: .alert)
                                            
                                            let report = UIAlertAction(title: "Report", style: .destructive) {
                                                [unowned self, alert] (action: UIAlertAction!) in
                                                
                                                let answer = alert.textFields![0]
                                                
                                                // Save to <Block_Reported>
                                                let report = PFObject(className: "Block_Reported")
                                                report["from"] = PFUser.current()!.username!
                                                report["fromUser"] = PFUser.current()!
                                                report["to"] = sharedObject.last!.value(forKey: "username") as! String
                                                report["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
                                                report["forObjectId"] = sharedObject.last!.objectId!
                                                report["type"] = answer.text!
                                                report.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved report: \(report)")
                                                        
                                                        // Dismiss
                                                        let alert = UIAlertController(title: "Successfully Reported",
                                                                                      message: "\(sharedObject.last!.value(forKey: "username") as! String)'s Share",
                                                            preferredStyle: .alert)
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .default,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(ok)
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
        }
        
        
        
        
        
        // Set background colors
        
        // Super Dark Gray
        delete.backgroundColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.0)
        // Red
        views.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0)
        
        
//        if sharedObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
        if (sharedObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            return [delete, views]
        } else {
            return [report]
        }
        
        
        
        
    } // End edit action
    
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y < -85 {
            // Pop view controller
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    

}
