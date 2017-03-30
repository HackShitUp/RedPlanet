//
//  ContactsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/10/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import OneSignal
import SVProgressHUD

class ContactsCell: UITableViewCell {
    
    // Initialize Parent VC
    var delegate: UIViewController?
    
    // User's object
    var userObject: PFObject?

    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBAction func followAction(_ sender: Any) {
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FOLLOW /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.followButton.title(for: .normal) == "Follow" {
            
            // Disable buttons to prevent duplicate data entry
            self.followButton.isUserInteractionEnabled = false
            self.followButton.isEnabled = false

            // SEND FOLLOW REQUEST
            if self.userObject!.value(forKey: "private") as! Bool == true {
            // PRIVATE ACCOUNT
                let follow = PFObject(className: "FollowMe")
                follow["follower"] = PFUser.current()!
                follow["followerUsername"] = PFUser.current()!.username!
                follow["following"] = self.userObject!
                follow["followingUsername"] = self.rpUsername.text!
                follow["isFollowing"] = false
                follow.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showSuccess(withStatus: "Requested")
                        
                        // Change button's title and design
                        self.followButton.setTitle("Requested", for: .normal)
                        self.followButton.setTitleColor(UIColor.white, for: .normal)
                        self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                        self.followButton.layer.cornerRadius = 22.00
                        self.followButton.clipsToBounds = true
                        
                        // Send to NotificationCenter
                        NotificationCenter.default.post(name: contactsNotification, object: nil)
                        
                        // (2) Notifications
                        let notifications = PFObject(className: "Notifications")
                        notifications["fromUser"] = PFUser.current()!
                        notifications["toUser"] = self.userObject
                        notifications["from"] = PFUser.current()!.username!
                        notifications["to"] = self.rpUsername.text!
                        notifications["type"] = "follow requested"
                        notifications["forObjectId"] = PFUser.current()!.objectId!
                        notifications.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                
                                // Re-enable buttons
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                                
                                // Send push notificaiton
                                if self.userObject!.value(forKey: "apnsId") != nil {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) sent you a follow request"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.showError(withStatus: "Error")
                            }
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showError(withStatus: "Error")
                    }
                })
                

            } else {
            // PUBLIC ACCOUNT
                let follow = PFObject(className: "FollowMe")
                follow["follower"] = PFUser.current()!
                follow["followerUsername"] = PFUser.current()!.username!
                follow["following"] = self.userObject!
                follow["followingUsername"] = self.rpUsername.text!
                follow["isFollowing"] = true
                follow.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showSuccess(withStatus: "Following")
                        
                        // Change button's title and design
                        self.followButton.setTitle("Following", for: .normal)
                        self.followButton.setTitleColor(UIColor.white, for: .normal)
                        self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                        self.followButton.layer.cornerRadius = 22.00
                        self.followButton.clipsToBounds = true
                        
                        // Send to NotificationCenter
                        NotificationCenter.default.post(name: contactsNotification, object: nil)
                        
                        // (2) Notifications
                        let notifications = PFObject(className: "Notifications")
                        notifications["fromUser"] = PFUser.current()!
                        notifications["toUser"] = self.userObject
                        notifications["from"] = PFUser.current()!.username!
                        notifications["to"] = self.rpUsername.text!
                        notifications["type"] = "followed"
                        notifications["forObjectId"] = PFUser.current()!.objectId!
                        notifications.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                
                                // Re-enable buttons
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                                
                                // MARK: - OneSignal
                                if self.userObject!.value(forKey: "apnsId") != nil {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) started following you"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.showError(withStatus: "Error")
                            }
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showError(withStatus: "Error")
                    }
                })
            }
        }

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FOLLOWING //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.followButton.title(for: .normal) == "Following" {
            
            // Disable buttons to prevent duplicate data entry
            self.followButton.isUserInteractionEnabled = false
            self.followButton.isEnabled = false
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Unfollow?", message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Add proPic
            dialogController.imageHandler = { (imageView) in
                if let proPic = self.userObject!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            imageView.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else {
                    imageView.image = UIImage(named: "Gender Neutral User-100")
                }
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

            // (1) UNFOLLOW
            dialogController.addAction(AZDialogAction(title: "Unfollow", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // UNFOLLOW USER
                let unfollow = PFQuery(className: "FollowMe")
                unfollow.whereKey("follower", equalTo: PFUser.current()!)
                unfollow.whereKey("following", equalTo: self.userObject!)
                unfollow.whereKey("isFollowing", equalTo: true)
                unfollow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                    SVProgressHUD.showSuccess(withStatus: "Unfollowed")
                                    
                                    // Set user's friends button
                                    self.followButton.setTitle("Follow", for: .normal)
                                    self.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                                    self.followButton.backgroundColor = UIColor.white
                                    self.followButton.layer.cornerRadius = 22.00
                                    self.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                                    self.followButton.layer.borderWidth = 2.00
                                    self.followButton.clipsToBounds = true
                                    
                                    // Delete Notifcations
                                    let notifications = PFQuery(className: "Notifications")
                                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                    notifications.whereKey("toUser", equalTo: self.userObject!)
                                    notifications.whereKey("type", equalTo: "followed")
                                    notifications.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                object.deleteEventually()
                                                
                                                // Enable buttons
                                                self.followButton.isUserInteractionEnabled = true
                                                self.followButton.isEnabled = true
                                                
                                                // Send to NotificationCenter
                                                NotificationCenter.default.post(name: contactsNotification, object: nil)
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            SVProgressHUD.setForegroundColor(UIColor.black)
                                            SVProgressHUD.showError(withStatus: "Error")
                                        }
                                    })
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                    SVProgressHUD.showError(withStatus: "Error")
                                }
                            })
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showError(withStatus: "Error")
                    }
                })

            }))
            
            // Show
            dialogController.show(in: self.delegate!)
        }

        // ========================================================================================================================
        // FOLLOWER ===============================================================================================================
        // ========================================================================================================================
        if self.followButton.title(for: .normal) == "Follower" {
            
            // Disable buttons to prevent duplicate data entry
            self.followButton.isUserInteractionEnabled = false
            self.followButton.isEnabled = false
            
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Follower", message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Add proPic
            dialogController.imageHandler = { (imageView) in
                if let proPic = self.userObject!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            imageView.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else {
                    imageView.image = UIImage(named: "Gender Neutral User-100")
                }
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
            
            // (1) FOLLOW BACK
            let followBack = AZDialogAction(title: "Follow Back", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // SEND FOLLOW REQUEST
                if self.userObject!.value(forKey: "private") as! Bool == true {
                    // PRIVATE ACCOUNT
                    let follow = PFObject(className: "FollowMe")
                    follow["follower"] = PFUser.current()!
                    follow["followerUsername"] = PFUser.current()!.username!
                    follow["following"] = self.userObject!
                    follow["followingUsername"] = self.rpUsername.text!
                    follow["isFollowing"] = false
                    follow.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // Change button's title and design
                            self.followButton.setTitle("Requested", for: .normal)
                            self.followButton.setTitleColor(UIColor.white, for: .normal)
                            self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                            self.followButton.layer.cornerRadius = 22.00
                            self.followButton.clipsToBounds = true
                            
                            // (2) Notifications
                            let notifications = PFObject(className: "Notifications")
                            notifications["fromUser"] = PFUser.current()!
                            notifications["toUser"] = self.userObject
                            notifications["from"] = PFUser.current()!.username!
                            notifications["to"] = self.rpUsername.text!
                            notifications["type"] = "follow requested"
                            notifications["forObjectId"] = PFUser.current()!.objectId!
                            notifications.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                    
                                    // Send push notificaiton
                                    if self.userObject!.value(forKey: "apnsId") != nil {
                                        OneSignal.postNotification(
                                            ["contents":
                                                ["en": "\(PFUser.current()!.username!.uppercased()) sent you a follow request"],
                                             "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                             "ios_badgeType": "Increase",
                                             "ios_badgeCount": 1
                                            ]
                                        )
                                    }
                                    
                                    // Send to NotificationCenter
                                    NotificationCenter.default.post(name: contactsNotification, object: nil)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                    SVProgressHUD.showError(withStatus: "Error")
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                } else {
                    // PUBLIC ACCOUNT
                    let follow = PFObject(className: "FollowMe")
                    follow["follower"] = PFUser.current()!
                    follow["followerUsername"] = PFUser.current()!.username!
                    follow["following"] = self.userObject!
                    follow["followingUsername"] = self.rpUsername.text!
                    follow["isFollowing"] = true
                    follow.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // Change button's title and design
                            self.followButton.setTitle("Following", for: .normal)
                            self.followButton.setTitleColor(UIColor.white, for: .normal)
                            self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                            self.followButton.layer.cornerRadius = 22.00
                            self.followButton.clipsToBounds = true
                            
                            // (2) Notifications
                            let notifications = PFObject(className: "Notifications")
                            notifications["fromUser"] = PFUser.current()!
                            notifications["toUser"] = self.userObject
                            notifications["from"] = PFUser.current()!.username!
                            notifications["to"] = self.rpUsername.text!
                            notifications["type"] = "followed"
                            notifications["forObjectId"] = PFUser.current()!.objectId!
                            notifications.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    
                                    // Re-enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                    
                                    // MARK: - OneSignal
                                    if self.userObject!.value(forKey: "apnsId") != nil {
                                        OneSignal.postNotification(
                                            ["contents":
                                                ["en": "\(PFUser.current()!.username!.uppercased()) started following you"],
                                             "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                             "ios_badgeType": "Increase",
                                             "ios_badgeCount": 1
                                            ]
                                        )
                                    }
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                    SVProgressHUD.showError(withStatus: "Error")
                                }
                            })
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor.black)
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                }
            })
            
            // (2) REMOVE FOLLOWER
            let removeFollower = AZDialogAction(title: "Remove Follower", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // REMOVE FOLLOWER
                let follower = PFQuery(className: "FollowMe")
                follower.whereKey("following", equalTo: PFUser.current()!)
                follower.whereKey("follower", equalTo: self.userObject!)
                follower.whereKey("isFollowing", equalTo: true)
                follower.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteEventually()
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor.black)
                            SVProgressHUD.showSuccess(withStatus: "Removed")
                            
                            // Send to NotificationCenter
                            NotificationCenter.default.post(name: contactsNotification, object: nil)
                        }
                        
                        // Delete Notifation
                        let notifications = PFQuery(className: "Notifications")
                        notifications.whereKey("fromUser", equalTo: self.userObject!)
                        notifications.whereKey("toUser", equalTo: PFUser.current()!)
                        notifications.whereKey("type", equalTo: "followed")
                        notifications.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                for object in objects! {
                                    object.deleteEventually()
                                    
                                    // Enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
                                }
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.showError(withStatus: "Error")
                            }
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setBackgroundColor(UIColor.white)
                        SVProgressHUD.setForegroundColor(UIColor.black)
                        SVProgressHUD.showError(withStatus: "Error")
                    }
                })
            })
            
            // Show options dependent if user is following
            if !myFollowing.contains(where: { $0.objectId! == self.userObject!.objectId! }) {
                // IF NOT FOLLOWING
                dialogController.addAction(removeFollower)
                dialogController.addAction(followBack)
                dialogController.show(in: self.delegate!)
            }
        }
        
        
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FOLLOW REQUESTED ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.followButton.title(for: .normal) == "Requested" {
            
            // Disable buttons to prevent duplicate data entry
            self.followButton.isUserInteractionEnabled = false
            self.followButton.isEnabled = false
            
            // ========================================================================================================================
            // SENT FOLLOW REQUEST ====================================================================================================
            // ========================================================================================================================
            if myRequestedFollowing.contains(where: {$0.objectId! == self.userObject!.objectId!}) {
                
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Sent Follow Request", message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Add proPic
                dialogController.imageHandler = { (imageView) in
                    if let proPic = self.userObject!.value(forKey: "userProfilePicture") as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                imageView.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    } else {
                        imageView.image = UIImage(named: "Gender Neutral User-100")
                    }
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
                
                
                // RESCIND
                dialogController.addAction(AZDialogAction(title: "Rescind", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    
                    // Rescind Follow Request
                    let follow = PFQuery(className: "FollowMe")
                    follow.whereKey("follower", equalTo: PFUser.current()!)
                    follow.whereKey("following", equalTo: self.userObject!)
                    follow.whereKey("isFollowing", equalTo: false)
                    follow.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object.deleteInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.setBackgroundColor(UIColor.white)
                                        SVProgressHUD.setForegroundColor(UIColor.black)
                                        SVProgressHUD.showSuccess(withStatus: "Rescinded")
                                        
                                        // Set user's friends button
                                        self.followButton.setTitle("Follow", for: .normal)
                                        self.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                                        self.followButton.backgroundColor = UIColor.white
                                        self.followButton.layer.cornerRadius = 22.00
                                        self.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                                        self.followButton.layer.borderWidth = 2.00
                                        self.followButton.clipsToBounds = true
                                        
                                        // Send to NotificationCenter
                                        NotificationCenter.default.post(name: contactsNotification, object: nil)
                                        
                                        // Delete from "Notifications"
                                        let notifications = PFQuery(className: "Notifications")
                                        notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                        notifications.whereKey("toUser", equalTo: self.userObject!)
                                        notifications.whereKey("type", equalTo: "follow requested")
                                        notifications.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            
                                                            // Enable buttons
                                                            self.followButton.isUserInteractionEnabled = true
                                                            self.followButton.isEnabled = true
                                                            
                                                        } else {
                                                            print(error?.localizedDescription as Any)
                                                            // MARK: - SVProgressHUD
                                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                                            SVProgressHUD.setForegroundColor(UIColor.black)
                                                            SVProgressHUD.showError(withStatus: "Error")
                                                        }
                                                    })
                                                }
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                                SVProgressHUD.setForegroundColor(UIColor.black)
                                                SVProgressHUD.showError(withStatus: "Error")
                                            }
                                        })
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.setBackgroundColor(UIColor.white)
                                        SVProgressHUD.setForegroundColor(UIColor.black)
                                        SVProgressHUD.showError(withStatus: "Error")
                                    }
                                })
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor.black)
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                }))
                
                // Show
                dialogController.show(in: self.delegate!)
            }
            
            
            
            // ========================================================================================================================
            // RECEIVED FOLLOW REQUEST ================================================================================================
            // ========================================================================================================================
            if myRequestedFollowers.contains(where: {$0.objectId! == self.userObject!.objectId!}) {
                
                // Disable buttons to prevent duplicate data entry
                self.followButton.isUserInteractionEnabled = false
                self.followButton.isEnabled = false
                
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Follow Requested", message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Add proPic
                dialogController.imageHandler = { (imageView) in
                    if let proPic = self.userObject!.value(forKey: "userProfilePicture") as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                imageView.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    } else {
                        imageView.image = UIImage(named: "Gender Neutral User-100")
                    }
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
                
                // (1) CONFIRM
                dialogController.addAction(AZDialogAction(title: "Confirm", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    
                    // Confirm Follow Request
                    let follower = PFQuery(className: "FollowMe")
                    follower.whereKey("isFollowing", equalTo: false)
                    follower.whereKey("following", equalTo: PFUser.current()!)
                    follower.whereKey("follower", equalTo: self.userObject!)
                    follower.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object["isFollowing"] = true
                                object.saveInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        
                                        // Delete Notification
                                        let notifications = PFQuery(className: "Notifications")
                                        notifications.whereKey("fromUser", equalTo: self.userObject!)
                                        notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                        notifications.whereKey("type", equalTo: "follow requested")
                                        notifications.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteEventually()
                                                    
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                                    SVProgressHUD.showSuccess(withStatus: "Confirmed")
                                                    
                                                    // Change button's title and design
                                                    self.followButton.setTitle("Follower", for: .normal)
                                                    self.followButton.setTitleColor(UIColor.white, for: .normal)
                                                    self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                                                    self.followButton.layer.cornerRadius = 22.00
                                                    self.followButton.clipsToBounds = true
                                                    
                                                    // Re-enable buttons
                                                    self.followButton.isUserInteractionEnabled = true
                                                    self.followButton.isEnabled = true
                                                    
                                                    // Save new Notification
                                                    let notify = PFObject(className: "Notifications")
                                                    notify["fromUser"] = self.userObject!
                                                    notify["from"] = self.rpUsername.text!
                                                    notify["toUser"] = PFUser.current()!
                                                    notify["to"] = PFUser.current()!.username!
                                                    notify["type"] = "followed"
                                                    notify["forObjectId"] = PFUser.current()!.objectId!
                                                    notify.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            // MARK: - OneSignal
                                                            if self.userObject!.value(forKey: "apnsId") != nil {
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!.uppercased()) started following you"],
                                                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                                                     "ios_badgeType": "Increase",
                                                                     "ios_badgeCount": 1
                                                                    ]
                                                                )
                                                            }
                                                        } else {
                                                            print(error?.localizedDescription as Any)
                                                            // MARK: - SVProgressHUD
                                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                                            SVProgressHUD.setForegroundColor(UIColor.black)
                                                            SVProgressHUD.showError(withStatus: "Error")
                                                        }
                                                    })
                                                    
                                                }
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                                SVProgressHUD.setForegroundColor(UIColor.black)
                                                SVProgressHUD.showError(withStatus: "Error")
                                            }
                                        })
                                        
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.setBackgroundColor(UIColor.white)
                                        SVProgressHUD.setForegroundColor(UIColor.black)
                                        SVProgressHUD.showError(withStatus: "Error")
                                    }
                                })
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor.black)
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                }))
                
                // (2) IGNORE
                dialogController.addAction(AZDialogAction(title: "Ignore", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    
                    // Confirm Follow Request
                    let follower = PFQuery(className: "FollowMe")
                    follower.whereKey("isFollowing", equalTo: false)
                    follower.whereKey("following", equalTo: PFUser.current()!)
                    follower.whereKey("follower", equalTo: self.userObject!)
                    follower.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object.deleteInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if error == nil {
                                        
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.setBackgroundColor(UIColor.white)
                                        SVProgressHUD.setForegroundColor(UIColor.black)
                                        SVProgressHUD.showSuccess(withStatus: "Ignored")
                                        
                                        // Delete Notification
                                        let notifications = PFQuery(className: "Notifications")
                                        notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                        notifications.whereKey("fromUser", equalTo: self.userObject!)
                                        notifications.whereKey("type", equalTo: "follow requested")
                                        notifications.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteEventually()
                                                    
                                                    // Change button's title and design
                                                    self.followButton.setTitle("Follow", for: .normal)
                                                    self.followButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                                                    self.followButton.backgroundColor = UIColor.white
                                                    self.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                                                    self.followButton.layer.borderWidth = 2.00
                                                    self.followButton.layer.cornerRadius = 22.00
                                                    self.followButton.clipsToBounds = true
                                                    
                                                    // Re-enable buttons
                                                    self.followButton.isUserInteractionEnabled = true
                                                    self.followButton.isEnabled = true
                                                }
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                                SVProgressHUD.setForegroundColor(UIColor.black)
                                                SVProgressHUD.showError(withStatus: "Error")
                                            }
                                        })
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.setBackgroundColor(UIColor.white)
                                        SVProgressHUD.setForegroundColor(UIColor.black)
                                        SVProgressHUD.showError(withStatus: "Error")
                                    }
                                })
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setBackgroundColor(UIColor.white)
                            SVProgressHUD.setForegroundColor(UIColor.black)
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                }))
                
                // Show
                dialogController.show(in: self.delegate!)
            }
        }
    }// end followAction

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
