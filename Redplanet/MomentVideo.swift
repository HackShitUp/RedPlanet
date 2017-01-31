//
//  MomentVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/10/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import UIKit
import CoreData
import Photos

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import OneSignal
import SimpleAlert


// Define Notification
let momentVideoNotification = Notification.Name("momentVideo")

class MomentVideo: UIViewController, UINavigationControllerDelegate, PlayerDelegate {
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Initialize player
    var player: Player!

    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // Function to show options
    func showMore(sender: UIButton) {
        
        // MARK: - SimpleAlert
        let options = AlertController(title: "Options",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    
                                    // Show Progress
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.show(withStatus: "Deleting")
                                    
                                    // Shared and og content
                                    let content = PFQuery(className: "Newsfeeds")
                                    content.whereKey("byUser", equalTo: PFUser.current()!)
                                    content.whereKey("objectId", equalTo: itmObject.last!.objectId!)
                                    
                                    let shares = PFQuery(className: "Newsfeeds")
                                    shares.whereKey("pointObject", equalTo: itmObject.last!)
                                    
                                    let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                    newsfeeds.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            
                                            // Dismiss progress
                                            SVProgressHUD.dismiss()
                                            
                                            for object in objects! {
                                                object.deleteInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        
                                                        print("Successfully deleted object: \(newsfeeds)")
                                                        
                                                        // Send FriendsNewsfeeds Notification
                                                        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                        
                                                        // Send MyProfile Notification
                                                        NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                        
                                                        // Pop VC
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
        
        let views = AlertAction(title: "🙈 Views",
                                style: .default,
                                handler: { (AlertAction) in
                                    
                                    // Append object
                                    viewsObject.append(itmObject.last!)
                                    
                                    // Push VC
                                    let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        let save = AlertAction(title: "Save",
                               style: .default,
                               handler: { (AlertAction) in
                                
                                if let videoFile = itmObject.last!.value(forKey: "videoAsset") as? PFFile {
                                    // Traverse video url
                                    let videoUrl = NSURL(string: videoFile.url!)
                                    PHPhotoLibrary.shared().performChanges({
                                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: videoUrl as! URL)
                                    }) { (saved: Bool, error: Error?) in
                                        if saved {
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    }
                                }
                                
        })
        
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        
        
        if moreButton.image(for: .normal) == UIImage(named: "More") {
            options.addAction(views)
            options.addAction(save)
            options.addAction(delete)
            options.addAction(cancel)
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            save.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
            self.present(options, animated: true, completion: nil)
        } else if moreButton.image(for: .normal) == UIImage(named: "Exit") {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func likers(_ sender: Any) {
        // Append object
        likeObject.append(itmObject.last!)
        
        // Push VC
        let likesVC = self.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.navigationController?.pushViewController(likesVC, animated: true)
    }
    
    @IBAction func like(_ sender: Any) {
        // Disable button
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            // unlike
            let likes = PFQuery(className: "Likes")
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully deleted like: \(object)")

                                // Delete "Notifications"
                                let notifications = PFQuery(className: "Notifications")
                                notifications.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                notifications.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            object.deleteInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully deleted notification: \(object)")
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                        }
                                    } else {
                                        print(error?.localizedDescription as Any)
                                    }
                                })
                                
                                
                                // Re-enable buttons
                                self.likeButton.isUserInteractionEnabled = true
                                self.likeButton.isEnabled = true
                                
                                
                                // Change button
                                self.likeButton.setTitle("notLiked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "WhiteLike"), for: .normal)
                                
                                // Animate like button
                                UIView.animate(withDuration: 0.6 ,
                                               animations: {
                                                self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                                },
                                               completion: { finish in
                                                UIView.animate(withDuration: 0.5){
                                                    self.likeButton.transform = CGAffineTransform.identity
                                                }
                                })
                                
                                // Reload data
                                self.fetchContent()
                                
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            
            // LIKE
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = itmObject.last!.value(forKey: "byUser") as! PFUser
            likes["to"] = self.rpUsername.titleLabel!.text!
            likes["forObjectId"] = itmObject.last!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like \(likes)")
                    
                    
                    // Save to notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = self.rpUsername.titleLabel!.text!
                    notifications["toUser"] = itmObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["forObjectId"] = itmObject.last!.objectId!
                    notifications["type"] = "like itm"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // Handle optional chaining
                            if let user = itmObject.last!.value(forKey: "byUser") as? PFUser {
                                // MARK: - OneSignal
                                // Send push notification
                                if user.value(forKey: "apnsId") != nil {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Moment"],
                                         "include_player_ids": ["\(user.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
                            }
                            
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    

                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    
                    // Change button title and image
                    self.likeButton.setTitle("liked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "WhiteLikeFilled"), for: .normal)
                    
                    // Reload data
                    self.fetchContent()
                    
                    // Animate like button
                    UIView.animate(withDuration: 0.6 ,
                                   animations: {
                                    self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                    },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.5){
                                        self.likeButton.transform = CGAffineTransform.identity
                                    }
                    })
                    
                    
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }

    }
    
    @IBAction func showComments(_ sender: Any) {
        // Append object
        commentsObject.append(itmObject.last!)
        
        // Push VC
        let commentsVC = self.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    @IBAction func comment(_ sender: Any) {
        // Append object
        commentsObject.append(itmObject.last!)
        
        // Push VC
        let commentsVC = self.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    @IBAction func showShares(_ sender: Any) {
        // Append object
        shareObject.append(itmObject.last!)
        
        // Push VC
        let sharesVC = self.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.navigationController?.pushViewController(sharesVC, animated: true)
    }
    
    @IBAction func share(_ sender: Any) {
        // MARK: - SimpleAlert
        let options = AlertController(title: "Share With",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        let publicShare = AlertAction(title: "All Friends",
                                      style: .default,
                                      handler: { (AlertAction) in
                                        
                                        // Share to public ***FRIENDS ONLY***
                                        let newsfeeds = PFObject(className: "Newsfeeds")
                                        newsfeeds["byUser"] = PFUser.current()!
                                        newsfeeds["username"] = PFUser.current()!.username!
                                        newsfeeds["pointObject"] = itmObject.last!
                                        newsfeeds["contentType"] = "sh"
                                        newsfeeds["videoAsset"] = itmObject.last!.value(forKey: "videoAsset") as! PFFile
                                        newsfeeds.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if error == nil {
                                                print("Successfully shared moment: \(newsfeeds)")
                                                
                                                
                                                // Send Notification
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["fromUser"] = PFUser.current()!
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["toUser"] = itmObject.last!.value(forKey: "byUser") as! PFUser
                                                notifications["to"] = self.rpUsername.titleLabel!.text!
                                                notifications["type"] = "share itm"
                                                notifications["forObjectId"] = itmObject.last!.objectId!
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Sent notification: \(notifications)")
                                                        
                                                        
                                                        
                                                        
                                                        // Send notification
                                                        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                        
                                                        
                                                        
                                                        // Send Push notificaiton
                                                        if let user = itmObject.last!.value(forKey: "byUser") as? PFUser {
                                                            // Handle optional chaining
                                                            if user["apnsId"] != nil {
                                                                // MARK: - OneSignal
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!.uppercased()) shared your Moment"],
                                                                     "include_player_ids": ["\(user["apnsId"] as! String)"],
                                                                     "ios_badgeType": "Increase",
                                                                     "ios_badgeCount": 1
                                                                    ]
                                                                )
                                                            }
                                                            
                                                        }
                                                        
                                                        
                                                        // Show alert
                                                        let alert = UIAlertController(title: "Shared With Friends",
                                                                                      message: "Successfully shared \(self.rpUsername.titleLabel!.text!)'s Moment",
                                                            preferredStyle: .alert)
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .default,
                                                                               handler: {(alertAction: UIAlertAction!) in
                                                                                // Pop view controller
                                                                                _ = self.navigationController?.popViewController(animated: true)
                                                        })
                                                        
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        
                                        
        })
        
        let privateShare = AlertAction(title: "One Friend",
                                       style: .default,
                                       handler: { (AlertAction) in
                                        
                                        // Append to contentObject
                                        shareObject.append(itmObject.last!)
                                        
                                        // Share to chats
                                        let shareToVC = self.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                        self.navigationController?.pushViewController(shareToVC, animated: true)
        })
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .destructive,
                                 handler: nil)
        
        options.addAction(publicShare)
        options.addAction(privateShare)
        options.addAction(cancel)
        publicShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        publicShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        privateShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        privateShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.present(options, animated: true, completion: nil)
    }
    
    // Functiont to go back
    func goBack(sender: UIGestureRecognizer) {
        // Remove last objects
        itmObject.removeLast()
        
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to go to user's profile
    func goUser(sender: UIButton) {
        // Append otherObject
        otherObject.append(itmObject.last!.value(forKey: "byUser") as! PFUser)
        // Append otherName
        otherName.append(self.rpUsername.titleLabel!.text!)
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    // Query content
    func fetchContent() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: itmObject.last!.objectId!)
        newsfeeds.includeKey("byUser")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    
                    // (1) Load moment
                    if let momentVideo = object["videoAsset"] as? PFFile {
                        
                        // Traverse video url
                        let videoUrl = NSURL(string: momentVideo.url!)
                        
                        // MARK: Player
                        self.player = Player()
                        self.player.delegate = self
                        self.player.view.frame = self.view.bounds
                        
                        self.addChildViewController(self.player)
                        self.view.addSubview(self.player.view)
                        self.player.didMove(toParentViewController: self)
                        self.player.setUrl(videoUrl! as URL)
                        self.player.fillMode = "AVLayerVideoGravityResizeAspect"
                        self.player.playFromBeginning()
                        self.player.playbackLoops = true
                        
                        // Store buttons in an array
                        let buttons = [self.likeButton,
                                       self.numberOfLikes,
                                       self.commentButton,
                                       self.numberOfComments,
                                       self.shareButton,
                                       self.numberOfShares,
                                       self.rpUsername,
                                       self.time,
                                       self.moreButton] as [Any]
                        // Add shadows and bring view to front
                        for b in buttons {
                            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
                            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
                            (b as AnyObject).layer.shadowRadius = 3
                            (b as AnyObject).layer.shadowOpacity = 0.5
                            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                            self.player.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                        }
                    }
                    
                    // (2) Set username
                    if let user = object["byUser"] as? PFUser {
                        self.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
                    }
                    
                    // (3) Set time
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E"
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    self.time.text = "\(timeFormatter.string(from: object.createdAt!))"
                    
                    
                    // (4) Fetch likes
                    let likes = PFQuery(className: "Likes")
                    likes.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
                    likes.includeKey("fromUser")
                    likes.order(byDescending: "createdAt")
                    likes.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Clear array
                            self.likes.removeAll(keepingCapacity: false)
                            
                            // (A) Append objects
                            for object in objects! {
                                self.likes.append(object["fromUser"] as! PFUser)
                            }
                            
                            
                            // (B) Manipulate likes
                            if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
                                // liked
                                self.likeButton.setTitle("liked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "WhiteLikeFilled"), for: .normal)
                            } else {
                                // notLiked
                                self.likeButton.setTitle("notLiked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "WhiteLike"), for: .normal)
                            }
                            
                            // (C) Set number of likes
                            if self.likes.count == 0 {
                                self.numberOfLikes.setTitle("likes", for: .normal)
                            } else if self.likes.count == 1 {
                                self.numberOfLikes.setTitle("1 like", for: .normal)
                            } else {
                                self.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                            }
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    // (5) Fetch comments
                    let comments = PFQuery(className: "Comments")
                    comments.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
                    comments.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Clear arrays
                            self.comments.removeAll(keepingCapacity: false)
                            
                            // (A) Append objects
                            for object in objects! {
                                self.comments.append(object)
                            }
                            
                            // (B) Set number of comments
                            if self.comments.count == 0 {
                                self.numberOfComments.setTitle("comments", for: .normal)
                            } else if self.comments.count == 1 {
                                self.numberOfComments.setTitle("1 comment", for: .normal)
                            } else {
                                self.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    // (6) Fetch shares
                    let shares = PFQuery(className: "Newsfeeds")
                    shares.whereKey("contentType", equalTo: "sh")
                    shares.whereKey("pointObject", equalTo: itmObject.last!)
                    shares.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Clear arrays
                            self.shares.removeAll(keepingCapacity: false)
                            
                            // (A) Append objects
                            for object in objects! {
                                self.shares.append(object)
                            }
                            
                            // (B) Set number of shares
                            if self.shares.count == 0 {
                                self.numberOfShares.setTitle("shares", for: .normal)
                            } else if self.shares.count == 1 {
                                self.numberOfShares.setTitle("1 share", for: .normal)
                            } else {
                                self.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide status bar
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Hide navigationBar and tab bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Hide moreButton if not user's content
        if (itmObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            self.moreButton.setImage(UIImage(named: "More"), for: .normal)
        } else {
            self.moreButton.setImage(UIImage(named: "Exit"), for: .normal)
        }
        
        // Fetch data
        fetchContent()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(fetchContent), name: momentVideoNotification, object: nil)
        
        // Tap out implementation
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(goBack))
        tapOut.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(tapOut)
        
        // Add Username tap
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        
        // Add more button tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(showMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
        
        // Hide moreButton if not user's content
        if (itmObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Show button
            self.moreButton.isHidden = false
            self.moreButton.layer.shadowColor = UIColor.black.cgColor
            self.moreButton.layer.shadowOffset = CGSize(width: 1, height: 1)
            self.moreButton.layer.shadowRadius = 3
            self.moreButton.layer.shadowOpacity = 0.5
        } else {
            // Hide button
            self.moreButton.isHidden = true
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        URLCache.shared.removeAllCachedResponses()
    }

}
