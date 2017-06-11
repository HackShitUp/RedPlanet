//
//  OtherUserHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/31/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import AudioToolbox
import CoreData
import SafariServices
import UIKit

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal

/*
 UITableViewHeaderFooterView class that shows the user's profile.
 This class references to the XIB file, "OtherUserHeader.xib" which presents the following:
 • Number of Posts
 • Number of Followers
 • Number of Following
 • Follow/Unfollow Button
 • Current Relationship State Button (ie: Follow Requested).
 • Block Button
 • New Space Post Button
 • Chat Button
 • User's bio ("userBiography" in database)
 Works with "OtherUser.swift", this class where the user's posts are shown.
 */

class OtherUserHeader: UITableViewHeaderFooterView {
    
    // Initialize parent VC
    var delegate: UIViewController?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var numberOfPosts: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var userBio: KILabel!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newSpaceButton: UIButton!
    @IBOutlet weak var segmentView: UIView!
    
    
    // FUNCTION - Zoom into photo
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    // FUNCTION - Show followers
    func showFollowers() {
        // Show FollowersFollowingVC
        let followersFollowingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followersFollowingVC") as! FollowersFollowing
        followersFollowingVC.relationForUser = otherObject.last!
        followersFollowingVC.followersFollowing = "Followers"
        self.delegate?.navigationController?.pushViewController(followersFollowingVC, animated: true)
    }
    
    // FUNCTION - Show following
    func showFollowing() {
        // Show FollowersFollowingVC
        let followersFollowingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followersFollowingVC") as! FollowersFollowing
        followersFollowingVC.relationForUser = otherObject.last!
        followersFollowingVC.followersFollowing = "Following"
        self.delegate?.navigationController?.pushViewController(followersFollowingVC, animated: true)
    }
    
    
    // FUNCTION - Show current profile photo
    func showProPic() {
        // If proPicExists
        if otherObject.last!.value(forKey: "proPicExists") as! Bool == true {    
            // Get user's profile photo
            let proPic = PFQuery(className: "Posts")
            proPic.whereKey("byUser", equalTo: otherObject.last!)
            proPic.whereKey("contentType", equalTo: "pp")
            proPic.order(byDescending: "createdAt")
            proPic.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // StoryVC
                    let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                    storyVC.storyObject = object
                    // MARK: - RPPopUpVC
                    let rpPopUpVC = RPPopUpVC()
                    rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                    self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                } else {
                    print(error?.localizedDescription as Any)
                    // Error
                    // Call Agrume
                    self.zoom(sender: self)
                }
            }
        } else {
            // Call Agrume
            self.zoom(sender: self)
        }
    }
    
    
    // FUNCTION - Configure UIButton
    func configureButton(relationTitle: String) {
        
        // REQUESTED
        // FOLLOW
        // FOLLOWER
        // FOLLOWING
        
        // Set UIButton title
        self.followButton.setTitle(relationTitle, for: .normal)
        
        switch relationTitle {
            case "Requested", "Following", "Follower":
                self.followButton.setTitleColor(UIColor.white, for: .normal)
                self.followButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
                self.followButton.layer.borderWidth = 3
                self.followButton.layer.cornerRadius = 22.00
                self.followButton.clipsToBounds = true
            case "Follow":
                self.followButton.backgroundColor = UIColor.white
                self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.31, alpha: 1), for: .normal)
                self.followButton.layer.borderWidth = 3
                self.followButton.layer.cornerRadius = 22.00
                self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
                self.followButton.clipsToBounds = true
        default:
            self.followButton.backgroundColor = UIColor.white
            self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.31, alpha: 1), for: .normal)
            self.followButton.layer.borderWidth = 3
            self.followButton.layer.cornerRadius = 22.00
            self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
            self.followButton.clipsToBounds = true
        }
        
        
        DispatchQueue.main.async(execute: {
            // Re-enable followButton
            self.followButton.isUserInteractionEnabled = true
            self.followButton.isEnabled = true
        })
    }
    
    
    // FOLLOW ACTION
    @IBAction func followAction(_ sender: Any) {
        // MARK: - HEAP
        Heap.track("FollowedUser", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Disable buttons
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false

        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)",
            message: "Options")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Add proPic
        dialogController.imageHandler = { (imageView) in
            imageView.image = self.rpUserProPic.image!
            imageView.contentMode = .scaleAspectFill
            return true //must return true, otherwise image won't show.
        }
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
            button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }

        // FOLLOW
        if self.followButton.titleLabel?.text == "Follow" {
            if otherObject.last!.value(forKey: "private") as! Bool == true {
                
                // PRIVATE ACCOUNT
                let follow = PFObject(className: "FollowMe")
                follow["followerUsername"] = PFUser.current()!.username!
                follow["follower"] = PFUser.current()!
                follow["followingUsername"] = otherName.last!
                follow["following"] = otherObject.last!
                follow["isFollowing"] = false
                follow.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        
                        // Configure button
                        self.configureButton(relationTitle: "Requested")
                        
                        // Send "follow requested" Notification
                        let notifications = PFObject(className: "Notifications")
                        notifications["from"] = PFUser.current()!.username!
                        notifications["fromUser"] = PFUser.current()!
                        notifications["forObjectId"] = follow.objectId!
                        notifications["to"] = otherName.last!
                        notifications["toUser"] = otherObject.last!
                        notifications["type"] = "follow requested"
                        notifications.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully sent follow notification: \(notifications)")
                                
                                // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                let rpHelpers = RPHelpers()
                                rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "requested to follow you.")
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // Re-enable followButton
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                            }
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable followButton
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
                
            } else {
                
                // PUBLIC ACCOUNT
                let follow = PFObject(className: "FollowMe")
                follow["followerUsername"] = PFUser.current()!.username!
                follow["follower"] = PFUser.current()!
                follow["followingUsername"] = otherName.last!
                follow["following"] = otherObject.last!
                follow["isFollowing"] = true
                follow.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved follow: \(follow)")
                        
                        // Configure button
                        self.configureButton(relationTitle: "Following")
                        
                        // Send following notification
                        let notifications = PFObject(className: "Notifications")
                        notifications["from"] = PFUser.current()!.username!
                        notifications["fromUser"] = PFUser.current()!
                        notifications["forObjectId"] = otherObject.last!.objectId!
                        notifications["to"] = otherName.last!
                        notifications["toUser"] = otherObject.last!
                        notifications["type"] = "followed"
                        notifications.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully sent notification: \(notifications)")
                                
                                // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                let rpHelpers = RPHelpers()
                                rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "started following you.")
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // Re-enable followButton
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                            }
                        })
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable followButton
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            }
        }
        
        // RELATION ACTIONS
        // (1) Following
        // (2) Follower
        // (3) Follow Requested
        // (3A) Received Follow Request
        // (3B) Sent Follow Request
        
        // FOLLOWING --> Unfollow
        if self.followButton.titleLabel?.text == "Following" {
            
            dialogController.addAction(AZDialogAction(title: "Unfollow", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // UNFOLLOW USER
                // FollowMe
                let unfollow = PFQuery(className: "FollowMe")
                unfollow.whereKey("follower", equalTo: PFUser.current()!)
                unfollow.whereKey("following", equalTo: otherObject.last!)
                unfollow.whereKey("isFollowing", equalTo: true)
                unfollow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()

                            // Configure Button
                            self.configureButton(relationTitle: "Follow")
                            
                            // Delete from Notifications
                            let notifications = PFQuery(className: "Notifications")
                            notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                            notifications.whereKey("toUser", equalTo: otherObject.last!)
                            notifications.whereKey("type", equalTo: "followed")
                            notifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteEventually()
                                    }
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            }))
            
            // Show
            dialogController.show(in: self.delegate!)
        }
        
        // FOLLOWER
        // • Follow Back
        // • Remove Follower
        if self.followButton.titleLabel?.text == "Follower" {
            // FOLLOW BACK
            dialogController.addAction(AZDialogAction(title: "Follow Back", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                if otherObject.last!.value(forKey: "private") as! Bool == true {
                    // PRIVATE ACCOUNT
                    let follow = PFObject(className: "FollowMe")
                    follow["followerUsername"] = PFUser.current()!.username!
                    follow["follower"] = PFUser.current()!
                    follow["followingUsername"] = otherName.last!
                    follow["following"] = otherObject.last!
                    follow["isFollowing"] = false
                    follow.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved follow: \(follow)")
                            
                            // Configure button
                            self.configureButton(relationTitle: "Requested")
                            
                            // Send notification
                            let notifications = PFObject(className: "Notifications")
                            notifications["from"] = PFUser.current()!.username!
                            notifications["fromUser"] = PFUser.current()!
                            notifications["to"] = otherName.last!
                            notifications["toUser"] = otherObject.last!
                            notifications["forObjectId"] = follow.objectId!
                            notifications["type"] = "follow requested"
                            notifications.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    print("Successfully sent notification: \(notifications)")
                                    
                                    // MARK: - RPHelpers; send push notification if user's apnsId
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "requested to follow you.")
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                        }
                    })
                } else {
                    // PUBLIC ACCOUNT
                    let follow = PFObject(className: "FollowMe")
                    follow["followerUsername"] = PFUser.current()!.username!
                    follow["follower"] = PFUser.current()!
                    follow["followingUsername"] = otherName.last!
                    follow["following"] = otherObject.last!
                    follow["isFollowing"] = true
                    follow.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // Configure button
                            self.configureButton(relationTitle: "Following")
                            
                            // Send notification
                            let notifications = PFObject(className: "Notifications")
                            notifications["from"] = PFUser.current()!.username!
                            notifications["fromUser"] = PFUser.current()!
                            notifications["to"] = otherName.last!
                            notifications["toUser"] = otherObject.last!
                            notifications["forObjectId"] = follow.objectId!
                            notifications["type"] = "followed"
                            notifications.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    print("Successfully sent notification: \(notifications)")
                                    
                                    // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "started following you.")
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                        }
                    })
                }
            }))
            // REMOVE FOLLOWER
            dialogController.addAction(AZDialogAction(title: "Remove Follower", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // Remove follower
                let follower = PFQuery(className: "FollowMe")
                follower.whereKey("follower", equalTo: otherObject.last!)
                follower.whereKey("following", equalTo: PFUser.current()!)
                follower.whereKey("isFollowing", equalTo: true)
                follower.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()
                            
                            // Configure button
                            self.configureButton(relationTitle: "Follow")
                            
                            // Delete from Notifications
                            let notifications = PFQuery(className: "Notifications")
                            notifications.whereKey("fromUser", equalTo: otherObject.last!)
                            notifications.whereKey("toUser", equalTo: PFUser.current()!)
                            notifications.whereKey("type", equalTo: "followed")
                            notifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteEventually()
                                    }
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            }))
            // Show
            dialogController.show(in: self.delegate!)
        }
        
        // FOLLOW REQUESTED
        // • Confirm
        // • Ignore
        // • Rescind
        if self.followButton.titleLabel?.text == "Requested" {
            
            // CONFIRM
            let confirm = AZDialogAction(title: "Confirm", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // Accept Follower's Follow Request
                let follow = PFQuery(className: "FollowMe")
                follow.whereKey("follower", equalTo: otherObject.last!)
                follow.whereKey("following", equalTo: PFUser.current()!)
                follow.whereKey("isFollowing", equalTo: false)
                follow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object["isFollowing"] = true
                            object.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    
                                    // Configure Button
                                    self.configureButton(relationTitle: "Follower")
                                    
                                    // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "confirmed your follow request")
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            })
            
            // IGNORE
            let ignore = AZDialogAction(title: "Ignore", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // Delete Follower
                let follower = PFQuery(className: "FollowMe")
                follower.whereKey("isFollowing", equalTo: false)
                follower.whereKey("follower", equalTo: otherObject.last!)
                follower.whereKey("following", equalTo: PFUser.current()!)
                follower.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    // Delete Notification
                                    let notifications = PFQuery(className: "Notifications")
                                    notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                    notifications.whereKey("fromUser", equalTo: otherObject.last!)
                                    notifications.whereKey("type", equalTo: "follow requested")
                                    notifications.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                object.deleteEventually()
                                                // Configure button
                                                self.configureButton(relationTitle: "Follow")
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // Re-enable buttons
                                            self.followButton.isUserInteractionEnabled = true
                                            self.followButton.isEnabled = true
                                        }
                                    })
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            })
            
            // RESCIND
            let rescind = AZDialogAction(title: "Rescind", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // UNFOLLOW
                let follow = PFQuery(className: "FollowMe")
                follow.whereKey("follower", equalTo: PFUser.current()!)
                follow.whereKey("following", equalTo: otherObject.last!)
                follow.whereKey("isFollowing", equalTo: false)
                follow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()
                            
                            // Configure UIButton
                            self.configureButton(relationTitle: "Follow")
                            
                            // Delete in Notifications
                            let notifications = PFQuery(className: "Notifications")
                            notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                            notifications.whereKey("toUser", equalTo: otherObject.last!)
                            notifications.whereKey("type", equalTo: "follow requested")
                            notifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteEventually()
                                    }
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                    }
                })
            })
            
            // CONFIRM/IGNORE REQUEST
            if currentRequestedFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                dialogController.addAction(confirm)
                dialogController.addAction(ignore)
                dialogController.show(in: self.delegate!)
            }
            
            // RESCIND
            if currentRequestedFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                dialogController.addAction(rescind)
                dialogController.show(in: self.delegate!)
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Show UIButton
        self.followButton.isHidden = false
        
        // (1) Center text
        numberOfPosts.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        // Make background color white
        self.contentView.backgroundColor = UIColor.white
        
        // COUNT POSTS
        let countPosts = PFQuery(className: "Posts")
        countPosts.whereKey("byUser", equalTo: otherObject.last!)
        countPosts.countObjectsInBackground(block: {
            (count: Int32, error: Error?) -> Void in
            if error == nil {
                if count == 1 {
                    self.numberOfPosts.setTitle("1\npost", for: .normal)
                } else {
                    self.numberOfPosts.setTitle("\(count)\nposts", for: .normal)
                }
            } else {
                self.numberOfPosts.setTitle("0\nposts", for: .normal)
            }
        })
        
        // (2)
        // COUNT FOLLOWERS
        let countFollowers = PFQuery(className: "FollowMe")
        countFollowers.whereKey("isFollowing", equalTo: true)
        countFollowers.whereKey("following", equalTo: otherObject.last!)
        countFollowers.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                self.numberOfFollowers.setTitle("\(count)\nfollowers", for: .normal)
            } else {
                self.numberOfFollowers.setTitle("0\nfollowers", for: .normal)
            }
        })
        
        // COUNT FOLLOWING
        let countFollowing = PFQuery(className: "FollowMe")
        countFollowing.whereKey("isFollowing", equalTo: true)
        countFollowing.whereKey("follower", equalTo: otherObject.last!)
        countFollowing.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                self.numberOfFollowing.setTitle("\(count)\nfollowing", for: .normal)
            } else {
                self.numberOfFollowing.setTitle("\(count)\nfollowing", for: .normal)
            }
        })
        
        // (3) Design buttons
        self.followButton.backgroundColor = UIColor.white
        self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.31, alpha: 1), for: .normal)
        self.followButton.layer.borderWidth = 3
        self.followButton.layer.cornerRadius = 22.00
        self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
        self.followButton.clipsToBounds = true
        
        // (5) Handle KILabel taps
        // MARK: - KILabel; @, #, and https://
        // @@@
        userBio.userHandleLinkTapHandler = { label, handle, range in
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: String(handle.characters.dropFirst()).lowercased())
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append data
                        otherName.append(String(handle.characters.dropFirst()).lowercased())
                        otherObject.append(object)
                        // Push VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.delegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
        // https://
        userBio.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.delegate?.present(webVC, animated: true, completion: nil)
        }
        
        
        
        // (5) Number of...
        // Add tap methods to show followers or following
        
        // (a) Followers
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(showFollowers))
        followersTap.numberOfTapsRequired = 1
        self.numberOfFollowers.isUserInteractionEnabled = true
        self.numberOfFollowers.addGestureRecognizer(followersTap)
        
        // (b) Following
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(showFollowing))
        followingTap.numberOfTapsRequired = 1
        self.numberOfFollowing.isUserInteractionEnabled = true
        self.numberOfFollowing.addGestureRecognizer(followingTap)
        
        
        // (6) Add tap method to show profile photo
        // Show Profile photo if... 
        // FOLLOWER && FOLLOWING
        if currentFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && currentFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && otherObject.last!.value(forKey: "proPicExists") as! Bool == true {
            let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProPic))
            proPicTap.numberOfTapsRequired = 1
            self.rpUserProPic.isUserInteractionEnabled = true
            self.rpUserProPic.addGestureRecognizer(proPicTap)
        } else {
            // Add tap gesture to zoom in
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.rpUserProPic.isUserInteractionEnabled = true
            self.rpUserProPic.addGestureRecognizer(zoomTap)
        }
        
        
        // TODO::
        // Count Best Friends!!!
    }
}
