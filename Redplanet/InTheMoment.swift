//
//  InTheMoment.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/1/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import SwipeNavigationController
import SDWebImage
import OneSignal

// Array to hold object
var itmObject = [PFObject]()

// Define Notification
let itmNotification = Notification.Name("itmNotification")

class InTheMoment: UIViewController, UINavigationControllerDelegate {
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    @IBOutlet weak var itmMedia: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // Functiont to go back
    func goBack(sender: UIGestureRecognizer) {
        // Remove last objects
        itmObject.removeLast()
        // POP VC
        self.navigationController?.radialPopViewController(withDuration: 0.2, withStartFrame: CGRect(x: CGFloat(self.view.frame.size.width/2), y: CGFloat(self.view.frame.size.height), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {() -> Void in
        })
    }
    
    // Functiont to share to other platforms
    func shareVia() {
        // Photo to Share
        let image = SNUtils.screenShot(self.view)!
        let imageToShare = [image]
        let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    
    // Function to show options
    func showMore(sender: UIButton) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Moment", message: "Options")
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
        dialogController.addAction(AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            viewsObject.append(itmObject.last!)
            // Push VC
            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            self.navigationController?.pushViewController(viewsVC, animated: true)
        }))
        
        // (2) SAVE
        dialogController.addAction(AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor.black)
            SVProgressHUD.show(withStatus: "Saving")
            
            // Shared and og content
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
            newsfeeds.whereKey("objectId", equalTo: itmObject.last!.objectId!)
            newsfeeds.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object["saved"] = true
                        object.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                                SVProgressHUD.showSuccess(withStatus: "Saved")
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - SVProgressHUD
                                SVProgressHUD.showError(withStatus: "Error")
                            }
                        })
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - SVProgressHUD
                    SVProgressHUD.showError(withStatus: "Error")
                }
            })
        }))
        
        // (3) DELETE
        dialogController.addAction(AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
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
                    // Delete all objects
                    PFObject.deleteAll(inBackground: objects, block: {
                        (success: Bool, error: Error?) in
                        if success {
                            // Delete all Notifications
                            let notifications = PFQuery(className: "Notifications")
                            notifications.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
                            notifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteEventually()
                                    }
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                                    SVProgressHUD.showSuccess(withStatus: "Deleted")
                                    
                                    // Send FriendsNewsfeeds Notification
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                    
                                    // Send MyProfile Notification
                                    NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                    
                                    // Pop VC
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
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - SVProgressHUD
                    SVProgressHUD.showError(withStatus: "Error")
                }
            })
        }))
        
        // Show
        dialogController.show(in: self)
    }
    
    
    // Query content
    func fetchContent() {
        
        // (1) Load moment
        if let moment = itmObject.last!.value(forKey: "photoAsset") as? PFFile {
            // MARK: - SDWebImage
            self.itmMedia.sd_setImage(with: URL(string: moment.url!), placeholderImage: self.itmMedia.image)
        }
        
        // (2) Set username
        if let user = itmObject.last!.object(forKey: "byUser") as? PFUser {
            self.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
        }
        
        // (3) Set time
        let from = itmObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        if difference.second! <= 0 {
            self.time.text = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                self.time.text = "1 second ago"
            } else {
                self.time.text = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                self.time.text = "1 minute ago"
            } else {
                self.time.text = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                self.time.text = "1 hour ago"
            } else {
                self.time.text = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                self.time.text = "1 day ago"
            } else {
                self.time.text = "\(difference.day!) days ago"
            }
            if itmObject.last!.value(forKey: "saved") as! Bool == true {
                self.likeButton.isUserInteractionEnabled = false
                self.numberOfLikes.isUserInteractionEnabled = false
                self.commentButton.isUserInteractionEnabled = false
                self.numberOfComments.isUserInteractionEnabled = false
                self.shareButton.isUserInteractionEnabled = false
                self.numberOfShares.isUserInteractionEnabled = false
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            self.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
            if itmObject.last!.value(forKey: "saved") as! Bool == true {
                self.likeButton.isUserInteractionEnabled = false
                self.numberOfLikes.isUserInteractionEnabled = false
                self.commentButton.isUserInteractionEnabled = false
                self.numberOfComments.isUserInteractionEnabled = false
                self.shareButton.isUserInteractionEnabled = false
                self.numberOfShares.isUserInteractionEnabled = false
            }
        }
        
        
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
                    self.likeButton.setImage(UIImage(named: "WhiteLiked"), for: .normal)
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
    
    
    
    // Function to show number of likes
    func showLikes(sender: UIButton) {
        // Append object
        likeObject.append(itmObject.last!)
        
        // Push VC
        let likesVC = self.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.navigationController?.pushViewController(likesVC, animated: true)
    }
    
    // Function to like content
    func like(sender: UIButton) {
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
                    self.likeButton.setImage(UIImage(named: "WhiteLiked"), for: .normal)
                    
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
    
    // Function to show comments
    func showComments(sender: UIButton) {
        // Append object
        commentsObject.append(itmObject.last!)
        
        // Push VC
        let commentsVC = self.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }

    // Function to show shares
    func showShares(sender: UIButton) {
        // Append object
        shareObject.append(itmObject.last!)
        
        // Push VC
        let sharesVC = self.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.navigationController?.pushViewController(sharesVC, animated: true)

    }
    
    // Function to share
    func shareOptions(sender: UIButton) {
        // Append post's object: PFObject
        shareObject.append(itmObject.last!)
        // Share to chats
        let shareToVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
        self.navigationController?.pushViewController(shareToVC, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // Hide statusBar, navigationBar, and tabBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - MainUITab
        // Hide button
        rpButton.isHidden = true
        
        // Hide moreButton if not user's content
        if (itmObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            self.moreButton.isHidden = false
        } else {
            self.moreButton.isHidden = true
        }

        // Fetch data
        fetchContent()
        
        // Add shadows
        let buttons = [self.likeButton,
                       self.numberOfLikes,
                       self.commentButton,
                       self.numberOfComments,
                       self.shareButton,
                       self.numberOfShares,
                       self.rpUsername,
                       self.time,
                       self.moreButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3.5
            (b as AnyObject).layer.shadowOpacity = 0.6
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(fetchContent), name: itmNotification, object: nil)
        
        // Tap out implementation
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(goBack))
        tapOut.numberOfTapsRequired = 1
        self.itmMedia.isUserInteractionEnabled = true
        self.itmMedia.addGestureRecognizer(tapOut)
        
        // MARK: - RadialTransitionSwipe
        self.navigationController?.enableRadialSwipe()
        
        // (1) Add more tap method
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(showMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
        // (2) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (4) Add like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (5) Add Username tap
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        
        // (6) Add numComments tap
        let numCommentsTap = UITapGestureRecognizer(target: self, action: #selector(showComments))
        numCommentsTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(numCommentsTap)
        
        // (7) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(showComments))
        commentTap.numberOfTapsRequired = 1
        self.commentButton.isUserInteractionEnabled = true
        self.commentButton.addGestureRecognizer(commentTap)
        
        // (8) Add num shares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (9) Add share options
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        shareTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(shareTap)
        
        // (10) Long press to share
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(shareVia))
        longTap.minimumPressDuration = 0.15
        self.itmMedia.isUserInteractionEnabled = true
        self.itmMedia.addGestureRecognizer(longTap)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show Status Bar
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // MARK: - MainUITab
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

}
