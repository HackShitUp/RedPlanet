//
//  OtherUserHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/31/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal

class OtherUserHeader: UITableViewHeaderFooterView {
    
    // Initialize parent VC
    var delegate: UIViewController?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var numberOfPosts: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var relationType: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var userBio: KILabel!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var newSpaceButton: UIButton!
    
    // Function to show followers
    func showFollowers() {
        // Append to forFollowers
        forFollowers.append(otherObject.last!)
        
        // Push VC
        let followersVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowersVC") as! RFollowers
        self.delegate?.navigationController?.pushViewController(followersVC, animated: true)
    }
    
    // Function to show followers
    func showFollowing() {
        // Append to forFollowing
        forFollowing.append(otherObject.last!)
        
        // Push VC
        let followingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowingVC") as! RFollowing
        self.delegate?.navigationController?.pushViewController(followingVC, animated: true)
    }
    
    
    // Function to show profile photo
    func showProPic() {
        
        if otherObject.last!.value(forKey: "proPicExists") as! Bool == true {    
            // Get user's profile photo
            let proPic = PFQuery(className: "Newsfeeds")
            proPic.whereKey("byUser", equalTo: otherObject.last!)
            proPic.whereKey("contentType", equalTo: "pp")
            proPic.order(byDescending: "createdAt")
            proPic.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // Append object
                    proPicObject.append(object!)
                    
                    // Push VC
                    let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                    self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                    
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
    
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    // FOLLOW ACTION
    @IBAction func followAction(_ sender: Any) {
        // MARK: - HEAP
        Heap.track("FollowedUser", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Disable Follow Button
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false
        
        if otherObject.last!.value(forKey: "private") as! Bool == true {
        // PRIVATE ACCOUNT
            // FollowMe
            let follow = PFObject(className: "FollowMe")
            follow["followerUsername"] = PFUser.current()!.username!
            follow["follower"] = PFUser.current()!
            follow["followingUsername"] = otherName.last!
            follow["following"] = otherObject.last!
            follow["isFollowing"] = false
            follow.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Show relationship button
                    self.relationType.isHidden = false
                    self.relationType.isUserInteractionEnabled = true
                    self.relationType.isEnabled = true
                    self.relationType.setTitle("Requested", for: .normal)
                    
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
                            
                            // Re enable buttons
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                            
                            // Handle optional chaining for user's apnsId
                            if otherObject.last!.value(forKey: "apnsId") != nil {
                                // MARK: - OneSignal
                                // Send push notificaiton
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) requested to follow you"],
                                     "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                     "ios_badgeType": "Increase",
                                     "ios_badgeCount": 1
                                    ]
                                )
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Enable Follow Button
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // Enable Follow Button
                    self.followButton.isUserInteractionEnabled = true
                    self.followButton.isEnabled = true
                }
            })
            
        } else {
        // PUBLIC ACCOUNT
            // FollowMe
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
                    
                    // Show relationship button
                    self.relationType.isHidden = false
                    self.relationType.setTitle("Following", for: .normal)
                    
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
                            
                            // Enable Follow Button
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                            
                            // Handle optional chaining for user's apnsId
                            if otherObject.last!.value(forKey: "apnsId") != nil {
                                // MARK: - OneSignal
                                // Send push notificaiton
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) started following you"],
                                     "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                     "ios_badgeType": "Increase",
                                     "ios_badgeCount": 1
                                    ]
                                )
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
    }// end followAction

    
    // RELATION ACTIONS
    // (1) Following
    // (2) Follower
    // (3) Follow Requested
    // (3A) Received Follow Request
    // (3B) Sent Follow Request
    @IBAction func relationAction(_ sender: Any) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options",
                                                      message: "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)")
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
        

        // (1)
        // ============================================================================================================================
        // ============================================================================================================================
        // ======================================= F O L L O W I N G ==================================================================
        // ============================================================================================================================
        // ============================================================================================================================
        // UNFOLLOW ===================================================================================================================
        if self.relationType.titleLabel!.text! == "Following" {
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
                            
                            // Hide and show buttons
                            self.relationType.isHidden = true
                            self.followButton.isHidden = false
                            
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
                                }
                            })
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }))
            
            // Show
            dialogController.show(in: self.delegate!)
        }
        
        
        // (2)
        // ============================================================================================================================
        // ============================================================================================================================
        // ======================================= F O L L O W E R  ===================================================================
        // ============================================================================================================================
        // ============================================================================================================================
        // FOLLOW BACK =============================================================================================================***
        // REMOVE FOLLOWER =========================================================================================================***
        if self.relationType.titleLabel!.text == "Follower" {
        // (2A) FOLLOW BACK
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

                            // Change sender button title
                            self.relationType.isHidden = false
                            self.relationType.setTitle("Requested", for: .normal)
                            
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
                                    
                                    // Send push notification
                                    // Handle optional chaining for user's apnsId
                                    if otherObject.last!.value(forKey: "apnsId") != nil {
                                        // MARK: - OneSignal
                                        // Send push notificaiton
                                        OneSignal.postNotification(
                                            ["contents":
                                                ["en": "\(PFUser.current()!.username!.uppercased()) requested to follow you"],
                                             "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                             "ios_badgeType": "Increase",
                                             "ios_badgeCount": 1
                                            ]
                                        )
                                    }
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
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
                            
                            // Change sender button title
                            self.relationType.isHidden = false
                            self.relationType.setTitle("Following", for: .normal)
                            
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
                                    
                                    // Handle optional chaining for user's apnsId
                                    if otherObject.last!.value(forKey: "apnsId") != nil {
                                        // MARK: - OneSignal
                                        // Send push notificaiton
                                        OneSignal.postNotification(
                                            ["contents":
                                                ["en": "\(PFUser.current()!.username!.uppercased()) started following you"],
                                             "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                             "ios_badgeType": "Increase",
                                             "ios_badgeCount": 1
                                            ]
                                        )
                                    }
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
            }))
            
        // (2B) REMOVE FOLLOWER
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
                            
                            // Not following
                            self.relationType.isHidden = true
                            self.followButton.isUserInteractionEnabled = true
                            
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
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }))
            
            // Show
            dialogController.show(in: self.delegate!)
        }
        
        
        // (3)
        // ============================================================================================================================
        // ============================================================================================================================
        // ======================================= F O L L O W     R E Q U E S T E D ==================================================
        // ============================================================================================================================
        // ============================================================================================================================
        // CONFIRM =================================================================================================================***
        // IGNORE ==================================================================================================================***
        // RESCIND =================================================================================================================***
        
        if self.relationType.titleLabel!.text! == "Requested" {
            
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

                                    // Change button title
                                    self.relationType.isHidden = false
                                    self.relationType.setTitle("Follower", for: .normal)
                                    
                                    // Send push notification
                                    // Handle optional chaining for user's apnsId
                                    if otherObject.last!.value(forKey: "apnsId") != nil {
                                        // MARK: - OneSignal
                                        // Send push notificaiton
                                        OneSignal.postNotification(
                                            ["contents":
                                                ["en": "\(PFUser.current()!.username!.uppercased()) confirmed your follow request"],
                                             "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                             "ios_badgeType": "Increase",
                                             "ios_badgeCount": 1
                                            ]
                                        )
                                    }
                                    
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
                                                // Hide button
                                                // Hide and show buttons
                                                self.relationType.isHidden = true
                                                self.followButton.isHidden = false
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                    
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
            
            // RESCIND
            let rescind = AZDialogAction(title: "Rescind", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // UNFOLLOW
                // FollowMe
                let follow = PFQuery(className: "FollowMe")
                follow.whereKey("follower", equalTo: PFUser.current()!)
                follow.whereKey("following", equalTo: otherObject.last!)
                follow.whereKey("isFollowing", equalTo: false)
                follow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()
                            
                            // Hide and show buttons
                            self.relationType.isHidden = true
                            self.followButton.isHidden = false
                            
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
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            })
            

            // CONFIRM/IGNORE REQUEST
            if myRequestedFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                dialogController.addAction(confirm)
                dialogController.addAction(ignore)
                dialogController.show(in: self.delegate!)
            }
            
            // RESCIND
            if myRequestedFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) {
                dialogController.addAction(rescind)
                dialogController.show(in: self.delegate!)
            }
        }
        
        
        
    } // end RelationAction
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Center text
        numberOfPosts.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        // Make background color white
        self.contentView.backgroundColor = UIColor.white
        
        // COUNT POSTS
        let countPosts = PFQuery(className: "Newsfeeds")
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
        self.relationType.layer.cornerRadius = 22.00
        self.relationType.clipsToBounds = true
        
        self.followButton.backgroundColor = UIColor.white
        self.followButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        self.followButton.layer.borderWidth = 4.00
        self.followButton.layer.cornerRadius = 22.00
        self.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        self.followButton.clipsToBounds = true
        
        // (5) Handle KILabel taps
        // Handle @username tap
        userBio.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: mention.lowercased())
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append user's username
                        otherName.append(mention)
                        // Append user object
                        otherObject.append(object)
                        
                        
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Show alert
                    let alert = UIAlertController(title: "Unknown Account",
                                                  message: "Looks like this account doesn't exist.",
                                                  preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: nil)
                    
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.delegate?.present(alert, animated: true)
                }
            })
            
        }
        
        
        // Handle #object tap
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        
        // Handle http: tap
        userBio.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: true)
            webVC.view.layer.cornerRadius = 8.00
            webVC.view.clipsToBounds = true
            self.delegate?.navigationController?.present(webVC, animated: true, completion: nil)
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
        if myFollowing.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && myFollowers.contains(where: {$0.objectId! == otherObject.last!.objectId!}) && otherObject.last!.value(forKey: "proPicExists") as! Bool == true {
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

    } // end awakeFromNib

}
