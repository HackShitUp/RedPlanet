//
//  SpacePost.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//


import AVFoundation
import AVKit
import CoreData
import MobileCoreServices
import Photos
import PhotosUI
import UIKit

import Parse
import ParseUI
import Bolts

import OneSignal
import SVProgressHUD
import SDWebImage

// Array to hold space post object
var spaceObject = [PFObject]()

// Define Notification
let spaceNotification = Notification.Name("spaceNotification")

class SpacePost: UITableViewController, UINavigationControllerDelegate {
    
    // Array to hold likers, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last object
        spaceObject.removeLast()
        // POP VC
        self.navigationController?.radialPopViewController(withDuration: 0.2, withStartFrame: CGRect(x: CGFloat(self.view.frame.size.width/2), y: CGFloat(self.view.frame.size.height), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {() -> Void in
        })
    }
    
    
    @IBAction func more(_ sender: Any) {
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Space Post", message: "Options")
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
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        // (1) VIEWS
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            viewsObject.append(spaceObject.last!)
            // Push VC
            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) EDIT
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            editObjects.append(spaceObject.last!)
            // Push VC
            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            self.navigationController?.pushViewController(editVC, animated: true)
        })
        
        // (3) SAVE
        let save = AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor.black)
            SVProgressHUD.show(withStatus: "Saving")
            
            // Save Post
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.getObjectInBackground(withId: spaceObject.last!.objectId!, block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    object!["saved"] = true
                    object!.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if error == nil {
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                            SVProgressHUD.showSuccess(withStatus: "Saved")
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
        })
        
        // (4) DELETE <byUser>
        let delete1 = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
            SVProgressHUD.show(withStatus: "Deleting")
            
            // Set content
            let content = PFQuery(className: "Newsfeeds")
            content.whereKey("byUser", equalTo: PFUser.current()!)
            content.whereKey("objectId", equalTo: spaceObject.last!.objectId!)
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("pointObject", equalTo: spaceObject.last!)
            
            let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
            newsfeeds.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Delete all objects
                    PFObject.deleteAll(inBackground: objects, block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                            SVProgressHUD.showSuccess(withStatus: "Deleted")
                            
                            // Reload data
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"),object: nil)
                            NotificationCenter.default.post(name: myProfileNotification, object: nil)
                            NotificationCenter.default.post(name: otherNotification, object: nil)
                            
                            // Pop view controller
                            _ = self.navigationController?.popViewController(animated: true)
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
        })
        
        // (5) DELETE <toUser>
        let delete2 = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Show Progress
            SVProgressHUD.show()
            SVProgressHUD.setBackgroundColor(UIColor.white)
            
            // Set content
            let content = PFQuery(className: "Newsfeeds")
            content.whereKey("toUser", equalTo: PFUser.current()!)
            content.whereKey("objectId", equalTo: spaceObject.last!.objectId!)
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("pointObject", equalTo: spaceObject.last!)
            
            let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
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
                                
                                // Reload data
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                NotificationCenter.default.post(name: otherNotification, object: nil)
                                
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
        })
        
      
        // (6) REPORT
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            let alert = UIAlertController(title: "Report",
                                          message: "Please provide your reason for reporting \(spaceObject.last!.value(forKey: "username") as! String)'s Space Post",
                preferredStyle: .alert)
            
            let report = UIAlertAction(title: "Report", style: .destructive) { (action: UIAlertAction!) in
                
                let answer = alert.textFields![0]
                
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["toUsername"] = spaceObject.last!.value(forKey: "username") as! String
                report["toUser"] = spaceObject.last!.value(forKey: "byUser") as! PFUser
                report["forObjectId"] = spaceObject.last!.objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved report: \(report)")
                        
                        // SVProgressHUD
                        SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                        SVProgressHUD.showSuccess(withStatus: "Reported")
                        // Dismiss
                        dialog.dismiss()
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Dismiss
                        dialog.dismiss()
                    }
                })
            }
            
            
            let cancel = UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: { (alertAction: UIAlertAction!) in
                                        // Dismiss
                                        dialog.dismiss()
            })
            
            alert.addTextField(configurationHandler: nil)
            alert.addAction(report)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            dialog.present(alert, animated: true, completion: nil)
        })
        
        
        // Show options dependent on type
        if (spaceObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(edit)
            dialogController.addAction(save)
            dialogController.addAction(delete1)
            dialogController.show(in: self)
            
        } else if (spaceObject.last!.value(forKey: "toUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(save)
            dialogController.addAction(delete2)
            dialogController.show(in: self)
            
        } else {
            dialogController.addAction(report)
            dialogController.show(in: self)
        }
    }
    
    // Function to refresh
    func refresh() {
        // Fetch interactions
        fetchInteractions()
        // End refresher
        self.refresher.endRefreshing()
        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to fetch interactions
    func fetchInteractions() {
        // Fetch likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append objects
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                // Fetch comments
                let comments = PFQuery(className: "Comments")
                comments.includeKey("byUser")
                comments.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
                comments.order(byDescending: "createdAt")
                comments.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        // Append objects
                        for object in objects! {
                            self.comments.append(object)
                        }
                        // Fetch shares
                        let shares = PFQuery(className: "Newsfeeds")
                        shares.whereKey("contentType", equalTo: "sh")
                        shares.whereKey("pointObject", equalTo: spaceObject.last!)
                        shares.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // Clear array
                                self.shares.removeAll(keepingCapacity: false)
                                
                                // Append objects
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
        })
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName:  UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Space Post"
        }
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - MainTabUI
        // Show button
        rpButton.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Stylize navigation bar
        configureView()
        
        // Fetch interactions
        fetchInteractions()
        
        // MARK: - RadialTransitionSwipe
        self.navigationController?.enableRadialSwipe()
        
        // Set estimated row height
        self.extendedLayoutIncludesOpaqueBars = true
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 255
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        self.refresher = UIRefreshControl()
        self.refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.refresher.tintColor = UIColor.white
        self.refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: spaceNotification, object: nil)
        
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
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
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
        return 255
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "spacePostCell", for: indexPath) as! SpacePostCell

        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Set parent vc
        cell.delegate = self
        
        // BYUSER
        // (1) Get byUser's data
        if let user = spaceObject.last!.value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.rpUsername.text! = user["username"] as! String
            
            // (B) Get and set user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (C) Set byUser's object
            cell.byUserObject = user
        }
        
        // TOUSER
        // (2) Fetch toUser's data
        let toUser = spaceObject.last!.value(forKey: "toUser") as! PFUser
        // (A) Set toUser's Object
        cell.toUserObject = toUser
        // LayoutViews
        cell.spaceProPic.layoutIfNeeded()
        cell.spaceProPic.layoutSubviews()
        cell.spaceProPic.setNeedsLayout()
        // Make Profile Photo Circular
        cell.spaceProPic.layer.cornerRadius = cell.spaceProPic.frame.size.width/2
        cell.spaceProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.spaceProPic.layer.borderWidth = 0.5
        cell.spaceProPic.clipsToBounds = true
        // (B) Set user's name
        cell.spaceName.text! = "shared on \(toUser.value(forKey: "realNameOfUser") as! String)'s Space"
        // (C) Set user's profile photo
        if let spaceProPic = toUser.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.spaceProPic.sd_setImage(with: URL(string: spaceProPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        
        // (3) Fetch content
        if spaceObject.last!.value(forKey: "photoAsset") != nil {
            // ======================================================================================================================
            // PHOTO ================================================================================================================
            // ======================================================================================================================
            // (A) Configure image
            cell.mediaAsset.contentMode = .scaleAspectFill
            cell.mediaAsset.layer.cornerRadius = 12.00
            cell.mediaAsset.layer.borderColor = UIColor.clear.cgColor
            cell.mediaAsset.layer.borderWidth = 0.0
            cell.mediaAsset.clipsToBounds = true
            
            // (B) Fetch Photo
            if let photo = spaceObject.last!.value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                cell.mediaAsset.sd_setImage(with: URL(string: photo.url!), placeholderImage: cell.mediaAsset.image)
            }
            
            // (C) Configure textPost
            if let tp = spaceObject.last!.value(forKey: "textPost") as? String {
                cell.textPost.text! = tp
            } else {
                cell.textPost.text! = ""
            }
            
        } else if spaceObject.last!.value(forKey: "videoAsset") != nil {
            
            // ======================================================================================================================
            // VIDEO ================================================================================================================
            // ======================================================================================================================
            
            // (A) Configure video preview
            cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
            cell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            cell.mediaAsset.layer.borderWidth = 3.50
            cell.mediaAsset.clipsToBounds = true
            
            
            // (B) Fetch Video Thumbnail
            if let videoFile = spaceObject.last!.value(forKey: "videoAsset") as? PFFile {
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = cell.mediaAsset.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                cell.mediaAsset.contentMode = .scaleAspectFill
                cell.mediaAsset.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            
            // (C) Configure textPost
            if let tp = spaceObject.last!.value(forKey: "textPost") as? String {
                cell.textPost.text! = tp
            } else {
                cell.textPost.text! = ""
            }
            
        } else {
            
            // ======================================================================================================================
            // TEXT POST ============================================================================================================
            // ======================================================================================================================
            cell.textPost.text! = "\(spaceObject.last!.value(forKey: "textPost") as! String)"
        }
        
        
        // (4) Layout taps
        cell.layoutTaps()
        cell.textPost.sizeToFit()
        
        // (5) Set time
        let from = spaceObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            cell.time.text = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                cell.time.text = "1s ago"
            } else {
                cell.time.text = "\(difference.second!)s ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                cell.time.text = "1m ago"
            } else {
                cell.time.text = "\(difference.minute!)m ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                cell.time.text = "1h ago"
            } else {
                cell.time.text = "\(difference.hour!)h ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                cell.time.text = "1d ago"
            } else {
                cell.time.text = "\(difference.day!)d ago"
            }
            if spaceObject.last!.value(forKey: "saved") as! Bool == true {
                cell.likeButton.isUserInteractionEnabled = false
                cell.numberOfLikes.isUserInteractionEnabled = false
                cell.commentButton.isUserInteractionEnabled = false
                cell.numberOfComments.isUserInteractionEnabled = false
                cell.shareButton.isUserInteractionEnabled = false
                cell.numberOfShares.isUserInteractionEnabled = false
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            cell.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
            if spaceObject.last!.value(forKey: "saved") as! Bool == true {
                cell.likeButton.isUserInteractionEnabled = false
                cell.numberOfLikes.isUserInteractionEnabled = false
                cell.commentButton.isUserInteractionEnabled = false
                cell.numberOfComments.isUserInteractionEnabled = false
                cell.shareButton.isUserInteractionEnabled = false
                cell.numberOfShares.isUserInteractionEnabled = false
            }
        }
        
        // (6) Set Likes, Comments, and Shares
        if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
            // Set button title
            cell.likeButton.setTitle("liked", for: .normal)
            // Set/ button image
            cell.likeButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
        } else {
            // Set button title
            cell.likeButton.setTitle("notLiked", for: .normal)
            // Set button image
            cell.likeButton.setImage(UIImage(named: "Like"), for: .normal)
        }
        // Set number of likes
        if self.likes.count == 0 {
            cell.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        // Set number of comments
        if self.comments.count == 0 {
            cell.numberOfComments.setTitle("comments", for: .normal)
        } else if self.comments.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
        }
        // Set number of shares
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
