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
import OneSignal

// Array to hold object
var itmObject = [PFObject]()

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
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to show options
    func showMore(sender: UIButton) {
        // Show Options
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let delete = UIAlertAction(title: "Delete",
                                   style: .destructive,
                                   handler: {(alertAction: UIAlertAction!) in
                                    // Show Progress
                                    SVProgressHUD.show()
                                
//                                    let newsfeeds = PFQuery(className: "Newsfeeds")
//                                    newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
//                                    newsfeeds.whereKey("objectId", equalTo: itmObject.last!.objectId!)
                                    
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
                                                        self.navigationController?.popViewController(animated: true)
                                                        
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
        
        let views = UIAlertAction(title: "Views",
                                  style: .default,
                                  handler: {(alertAction: UIAlertAction!) in
                                    
                                    // Append object
                                    viewsObject.append(itmObject.last!)
                                    
                                    // Push VC
                                    let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        let share = UIAlertAction(title: "Share Via",
                                  style: .default,
                                  handler: {(alertAction: UIAlertAction!) in
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addAction(delete)
        alert.addAction(views)
        alert.addAction(share)
        alert.addAction(cancel)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
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
                    if let moment = object["photoAsset"] as? PFFile {
                        moment.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set moment
                                self.itmMedia.image = UIImage(data: data!)
                                
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                    
                    // (2) Set username
                    if let user = object["byUser"] as? PFUser {
                        self.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
                    }
                    
                    // (3) Set time
                    let from = object.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        self.time.text = "right now"
                    }
                    
                    if difference.second! > 0 && difference.minute! == 0 {
                        if difference.second! == 1 {
                            self.time.text = "1 second ago"
                        } else {
                            self.time.text = "\(difference.second!) seconds ago"
                        }
                    }
                    
                    if difference.minute! > 0 && difference.hour! == 0 {
                        if difference.minute! == 1 {
                            self.time.text = "1 minute ago"
                        } else {
                            self.time.text = "\(difference.minute!) minutes ago"
                        }
                    }
                    
                    if difference.hour! > 0 && difference.day! == 0 {
                        if difference.hour! == 1 {
                            self.time.text = "1 hour ago"
                        } else {
                            self.time.text = "\(difference.hour!) hours ago"
                        }
                    }
                    
                    if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        if difference.day! == 1 {
                            self.time.text = "1 day ago"
                        } else {
                            self.time.text = "\(difference.day!) days ago"
                        }
                    }
                    
                    if difference.weekOfMonth! > 0 {
                        let createdDate = DateFormatter()
                        createdDate.dateFormat = "MMM d, yyyy"
                        self.time.text = createdDate.string(from: object.createdAt!)
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
                            if self.likes.contains(PFUser.current()!) {
                                // liked
                                self.likeButton.setTitle("liked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
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
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
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
                                         "include_player_ids": ["\(user.value(forKey: "apnsId") as! String)"]
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
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
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
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
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
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        // TODO::
        // Share the moment as a photo
        // 'photoAsset'
        
        
        // TODO:
        // Add option to share to followers
        
        let publicShare = UIAlertAction(title: "All Friends",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
                                            
                                            
                                            // Turn image to readable PFFile
                                            let imageData = UIImageJPEGRepresentation(self.itmMedia.image!, 0.5)
                                            let parseFile = PFFile(data: imageData!)
                                            
                                            // Share to public ***FRIENDS ONLY***
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
                                            newsfeeds["textPost"] = "shared @\(self.rpUsername.titleLabel!.text!)'s Moment: "
                                            newsfeeds["pointObject"] = itmObject.last!
                                            newsfeeds["contentType"] = "sh"
                                            newsfeeds["photoAsset"] = parseFile
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
                                                                         "include_player_ids": ["\(user["apnsId"] as! String)"]
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
                                                                                    self.navigationController?.popViewController(animated: true)
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
        
        let privateShare = UIAlertAction(title: "One Friend",
                                         style: .default,
                                         handler: {(alertAction: UIAlertAction!) in
                                            
                                            // Append to contentObject
                                            shareObject.append(itmObject.last!)
                                            
                                            // Share to chats
                                            let shareToVC = self.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                            self.navigationController?.pushViewController(shareToVC, animated: true)
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        options.addAction(publicShare)
        options.addAction(privateShare)
        options.addAction(cancel)
        options.view.tintColor = UIColor.black
        self.present(options, animated: true, completion: nil)
    }
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    
    // Save or share the photo
    func saveShare(sender: UILongPressGestureRecognizer) {
        // Photo to Share
        let image = self.itmMedia.image!
        let imageToShare = [image]
        let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch data
        fetchContent()
        
        // Hide navigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(goBack))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        
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
        
        // (10) Add Save??
        let holdTap = UILongPressGestureRecognizer(target: self, action: #selector(saveShare))
        holdTap.minimumPressDuration = 0.5
        self.itmMedia.isUserInteractionEnabled = true
        self.itmMedia.addGestureRecognizer(holdTap)
        
        
        // Hide moreButton if not user's content
        if itmObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            // Show button
            self.moreButton.isHidden = false
        } else {
            // Hide button
            self.moreButton.isHidden = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
