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
import SimpleAlert
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
            
            // MARK: - SimpleAlert
            let options = AlertController(title: "Unfollow?",
                                          message: "Are you sure you'd like to unfollow \(self.userObject!.value(forKey: "realNameOfUser") as! String)?",
                style: .alert)
            
            // Design content view
            options.configContentView = { view in
                if let view = view as? AlertContentView {
                    view.backgroundColor = UIColor.white
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                    view.titleLabel.textColor = UIColor.black
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                    let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                    let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                    attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                    view.titleLabel.attributedText = attributedText
                    view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                    view.messageLabel.textColor = UIColor.black
                    view.textBackgroundView.layer.cornerRadius = 3.00
                    view.textBackgroundView.clipsToBounds = true
                }
            }
            
            // Design corner radius
            options.configContainerCornerRadius = {
                return 14.00
            }
            
            let yes = AlertAction(title: "yes",
                                    style: .default,
                                    handler: { (AlertAction) in
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
            })
            let no = AlertAction(title: "no",
                                   style: .default,
                                   handler: { (AlertAction) in
                                    // Enable buttons
                                    self.followButton.isUserInteractionEnabled = true
                                    self.followButton.isEnabled = true
            })
            
            options.addAction(no)
            options.addAction(yes)
            options.view.tintColor = UIColor.black
            no.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            no.button.setTitleColor(UIColor.black, for: .normal)
            yes.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            yes.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            self.delegate?.present(options, animated: true, completion: nil)
        }

        // ========================================================================================================================
        // FOLLOWER ===============================================================================================================
        // ========================================================================================================================
        if self.followButton.title(for: .normal) == "Follower" {
            
            // Disable buttons to prevent duplicate data entry
            self.followButton.isUserInteractionEnabled = false
            self.followButton.isEnabled = false
            
            // MARK: - SimpleAlert
            let options = AlertController(title: "Follower",
                                          message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)",
                style: .alert)
            
            // Design content view
            options.configContentView = { view in
                if let view = view as? AlertContentView {
                    view.backgroundColor = UIColor.white
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                    view.titleLabel.textColor = UIColor.black
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                    let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                    let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                    attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                    view.titleLabel.attributedText = attributedText
                    view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                    view.messageLabel.textColor = UIColor.black
                    view.textBackgroundView.layer.cornerRadius = 3.00
                    view.textBackgroundView.clipsToBounds = true
                }
            }
            
            // Design corner radius
            options.configContainerCornerRadius = {
                return 14.00
            }

            let removeFollower = AlertAction(title: "Remove Follower",
                                             style: .default,
                                             handler: { (AlertAction) in
                                                
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
            
            let followBack = AlertAction(title: "Follow Back",
                                         style: .default,
                                         handler: { (AlertAction) in
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
            
            let cancel = AlertAction(title: "Cancel",
                                     style: .cancel,
                                     handler: { (AlertAction) in
                                        // CANCEL
                                        self.followButton.isUserInteractionEnabled = true
                                        self.followButton.isEnabled = true
            })
            
            if !myFollowing.contains(where: { $0.objectId! == self.userObject!.objectId! }) {
                // IF NOT FOLLOWING
                options.addAction(removeFollower)
                options.addAction(followBack)
                options.addAction(cancel)
                removeFollower.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                removeFollower.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
                followBack.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                followBack.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0), for: .normal)
                cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                cancel.button.setTitleColor(UIColor.black, for: .normal)
                self.delegate?.present(options, animated: true, completion: nil)
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
                
                // MARK: - SimpleAlert
                let options = AlertController(title: "Sent Follow Request",
                                              message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)",
                    style: .alert)
                
                // Design content view
                options.configContentView = { view in
                    if let view = view as? AlertContentView {
                        view.backgroundColor = UIColor.white
                        view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                        view.titleLabel.textColor = UIColor.black
                        view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                        let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                        let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                        attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                        view.titleLabel.attributedText = attributedText
                        view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                        view.messageLabel.textColor = UIColor.black
                        view.textBackgroundView.layer.cornerRadius = 3.00
                        view.textBackgroundView.clipsToBounds = true
                    }
                }
                
                // Design corner radius
                options.configContainerCornerRadius = {
                    return 14.00
                }
                
                let rescind = AlertAction(title: "Rescind",
                                            style: .default,
                                            handler: {(AlertAction) in
                                                
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
                                                
                                                
                })
                
                let cancel = AlertAction(title: "Cancel",
                                           style: .cancel,
                                           handler: { (AlertAction) in
                                            // Enable buttons
                                            self.followButton.isUserInteractionEnabled = true
                                            self.followButton.isEnabled = true
                })
                
                options.addAction(cancel)
                options.addAction(rescind)
                options.view.tintColor = UIColor.black
                rescind.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                rescind.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
                self.delegate!.present(options, animated: true, completion: nil)
            }
            
            
            
            // ========================================================================================================================
            // RECEIVED FOLLOW REQUEST ================================================================================================
            // ========================================================================================================================
            if myRequestedFollowers.contains(where: {$0.objectId! == self.userObject!.objectId!}) {
                
                // Disable buttons to prevent duplicate data entry
                self.followButton.isUserInteractionEnabled = false
                self.followButton.isEnabled = false
                
                // MARK: - SimpleAlert
                let options = AlertController(title: "Follow Requested",
                                              message: "\(self.userObject!.value(forKey: "realNameOfUser") as! String)",
                    style: .alert)
                
                // Design content view
                options.configContentView = { view in
                    if let view = view as? AlertContentView {
                        view.backgroundColor = UIColor.white
                        view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                        view.titleLabel.textColor = UIColor.black
                        view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                        let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                        let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                        attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                        view.titleLabel.attributedText = attributedText
                        view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                        view.messageLabel.textColor = UIColor.black
                        view.textBackgroundView.layer.cornerRadius = 3.00
                        view.textBackgroundView.clipsToBounds = true
                    }
                }
                // Design corner radius
                options.configContainerCornerRadius = {
                    return 14.00
                }
                
                let confirm = AlertAction(title: "Confirm",
                                          style: .default,
                                          handler: { (AlertAction) in
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
                })
                
                let ignore = AlertAction(title: "Ignore",
                                         style: .default,
                                         handler: { (AlertAction) in
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
                })
                

                let cancel = AlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: { (AlertAction) in
                                            // Enable buttons
                                            self.followButton.isUserInteractionEnabled = true
                                            self.followButton.isEnabled = true
                })
                
                options.addAction(confirm)
                options.addAction(ignore)
                options.addAction(cancel)
                confirm.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                confirm.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
                ignore.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                ignore.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
                cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                cancel.button.setTitleColor(UIColor.black, for: .normal)
                self.delegate!.present(options, animated: true, completion: nil)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
