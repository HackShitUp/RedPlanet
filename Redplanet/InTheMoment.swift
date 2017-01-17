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
import SimpleAlert

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
        
        // Pop VC
        DispatchQueue.main.async {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    // Function to show options
    func showMore(sender: UIButton) {
        
        // MARK: - SimpleAlert
        let options = AlertController(title: "Options",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.textColor = UIColor.black
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        let delete = AlertAction(title: "X Delete",
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
                                    UIImageWriteToSavedPhotosAlbum(SNUtils.screenShot(self.view)!, self, nil, nil)
        })
        
//        let share = AlertAction(title: "Share Via",
//                                  style: .default,
//                                  handler: { (AlertAction) in
//                                    let imageToShare = [self.itmMedia.image!]
//                                    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
//                                    activityViewController.popoverPresentationController?.sourceView = self.view
//                                    self.present(activityViewController, animated: true, completion: nil)
//        })
        
        let cancel = AlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        options.addAction(views)
        options.addAction(save)
//        options.addAction(share)
        options.addAction(delete)
        options.addAction(cancel)
        options.view.tintColor = UIColor.black
        self.present(options, animated: true, completion: nil)
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
                            if self.likes.contains(where: { $0.objectId == "\(PFUser.current()!.objectId!)" }) {
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
        
        // MARK: - SimpleAlert
        let options = AlertController(title: "Share To",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.textColor = UIColor.black
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        let publicShare = AlertAction(title: "All Friends",
                                      style: .default,
                                      handler: { (AlertAction) in
                                            
                                            
                                            // Turn image to readable PFFile
                                            let imageData = UIImageJPEGRepresentation(self.itmMedia.image!, 0.5)
                                            let parseFile = PFFile(data: imageData!)
                                            
                                            // Share to public ***FRIENDS ONLY***
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
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
        options.view.tintColor = UIColor.black
        self.present(options, animated: true, completion: nil)
    }
    
    // Save or share the photo
    func saveShare(sender: UILongPressGestureRecognizer) {
        // Photo to Share
        let image = self.itmMedia.image!
        let imageToShare = [image]
        let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // Hide statusBar
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Hide navigationBar and tab bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show the user what to do!
        let openedMoment = UserDefaults.standard.bool(forKey: "DidOpenMoment")
        if openedMoment == false {
            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenMoment")
            

            let alert = AlertController(title: "🎉\nCongrats, you viewed your first Moment!",
                                          message: "•Swipe right or tap once to leave",
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
        

        // Fetch data
        fetchContent()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(fetchContent), name: itmNotification, object: nil)

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(goBack))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Tap out implementation
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(goBack))
        tapOut.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(tapOut)
        
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
        
        // (10) Add Save
        let holdTap = UILongPressGestureRecognizer(target: self, action: #selector(saveShare))
        holdTap.minimumPressDuration = 0.5
        self.itmMedia.isUserInteractionEnabled = true
        self.itmMedia.addGestureRecognizer(holdTap)
        
        
        // Add shadows
        let buttons = [self.likeButton,
                       self.numberOfLikes,
                       self.commentButton,
                       self.numberOfComments,
                       self.shareButton,
                       self.numberOfShares,
                       self.rpUsername,
                       self.time] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
        }
        
        
        
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
        // Dispose of any resources that can be recreated.
    }

}
