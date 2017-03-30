//
//  FollowRequestsCell.swift
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

import KILabel
import OneSignal
import SVProgressHUD

class FollowRequestsCell: UICollectionViewCell {
    
    
    // Variable to determine whether current user sent a friend or follow request
    var friendFollow: String?
    
    // Variable to hold user's object
    var userObject: PFObject?
    
    // Variable to set delegate
    var delegate: UIViewController?
    
    // AppDelegate
    let appDelegate = AppDelegate()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
        
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var ignoreButton: UIButton!
    @IBOutlet weak var relationState: UIButton!
    
    
    // Function to show prompt to follow back
    func followBack() {
/*
        // MARK: - SimpleAlert
        let alert = AlertController(title: "Follow Back?",
                                    message: "Would you like to follow \(self.rpUsername.text!) back?",
            style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                view.titleLabel.textColor = UIColor.black
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                view.messageLabel.textColor = UIColor.black
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        let yes = AlertAction(title: "yes",
                              style: .destructive,
                              handler: { (AlertAction) in
                                // FOLLOW BACK
                                if self.userObject!.value(forKey: "private") as! Bool == true {
                                // PRIVATE ACCOUNT
                                    // FollowMe
                                    let follow = PFObject(className: "FollowMe")
                                    follow["followerUsername"] = PFUser.current()!.username!
                                    follow["follower"] = PFUser.current()!
                                    follow["followingUsername"] = self.rpUsername.text!
                                    follow["following"] = self.userObject!
                                    follow["isFollowing"] = false
                                    follow.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            
                                            // Send "follow requested" Notification
                                            let notifications = PFObject(className: "Notifications")
                                            notifications["from"] = PFUser.current()!.username!
                                            notifications["fromUser"] = PFUser.current()!
                                            notifications["forObjectId"] = follow.objectId!
                                            notifications["to"] = self.rpUsername.text!
                                            notifications["toUser"] = self.userObject!
                                            notifications["type"] = "follow requested"
                                            notifications.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully sent follow notification: \(notifications)")
                                                    
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                                    SVProgressHUD.showSuccess(withStatus: "Sent")
                                                    
                                                    // Handle optional chaining for user's apnsId
                                                    if self.userObject!.value(forKey: "apnsId") != nil {
                                                        // MARK: - OneSignal
                                                        // Send push notificaiton
                                                        OneSignal.postNotification(
                                                            ["contents":
                                                                ["en": "\(PFUser.current()!.username!.uppercased()) requested to follow you"],
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
                                    // FollowMe
                                    let follow = PFObject(className: "FollowMe")
                                    follow["followerUsername"] = PFUser.current()!.username!
                                    follow["follower"] = PFUser.current()!
                                    follow["followingUsername"] = self.rpUsername.text!
                                    follow["following"] = self.userObject!
                                    follow["isFollowing"] = true
                                    follow.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            print("Successfully saved follow: \(follow)")

                                            // Send following notification
                                            let notifications = PFObject(className: "Notifications")
                                            notifications["from"] = PFUser.current()!.username!
                                            notifications["fromUser"] = PFUser.current()!
                                            notifications["forObjectId"] = self.userObject!.objectId!
                                            notifications["to"] = self.rpUsername.text!
                                            notifications["toUser"] = self.userObject!
                                            notifications["type"] = "followed"
                                            notifications.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully sent notification: \(notifications)")
                                                    
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                                    SVProgressHUD.setForegroundColor(UIColor.black)
                                                    SVProgressHUD.showSuccess(withStatus: "Sent")
                                                    
                                                    // Handle optional chaining for user's apnsId
                                                    if self.userObject!.value(forKey: "apnsId") != nil {
                                                        // MARK: - OneSignal
                                                        // Send push notificaiton
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
        
        let no = AlertAction(title: "no",
                             style: .cancel,
                             handler: nil)
        
        
        alert.addAction(no)
        alert.addAction(yes)
        alert.view.tintColor = UIColor.black
        self.delegate?.present(alert, animated: true, completion: nil)
 */
    }
    
    // Function to confirm
    // ================================================================================================================================
    // ================================================= C O N F I R M ================================================================
    // ================================================================================================================================
    @IBAction func confirm(_ sender: Any) {
        // Disable buttons
        self.confirmButton.isUserInteractionEnabled = false
        self.confirmButton.isEnabled = false
        self.ignoreButton.isUserInteractionEnabled = false
        self.ignoreButton.isEnabled = false

        // FOLLOW
        let followers = PFQuery(className: "FollowMe")
        followers.whereKey("isFollowing", equalTo: false)
        followers.whereKey("follower", equalTo: self.userObject!)
        followers.whereKey("following", equalTo: PFUser.current()!)
        followers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object["isFollowing"] = true
                    object.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // Delete from "Notifications"
                            let dnotifications = PFQuery(className: "Notifications")
                            dnotifications.whereKey("toUser", equalTo: PFUser.current()!)
                            dnotifications.whereKey("fromUser", equalTo: self.userObject!)
                            dnotifications.whereKey("type", equalTo: "follow requested")
                            dnotifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully deleted notification: \(object)")
                                                
                                                // Send to Notifications: "followed" == started following
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["from"] = self.rpUsername.text!
                                                notifications["fromUser"] = self.userObject!
                                                notifications["toUser"] = PFUser.current()!
                                                notifications["to"] = PFUser.current()!.username!
                                                notifications["forObjectId"] = PFUser.current()!.objectId!
                                                notifications["type"] = "followed"
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if error == nil {
                                                        print("Successfully sent notification: \(notifications)")
                                                        
                                                        // Hide block button
                                                        // Hide confirm button
                                                        self.ignoreButton.isHidden = true
                                                        self.confirmButton.isHidden = true
                                                        
                                                        // Unhide currentState button
                                                        // Change title: "CONFIRMED"
                                                        self.relationState.isHidden = false
                                                        self.relationState.setTitle("Confirmed", for: .normal)
                                                        
                                                        // Post Notification
                                                        // NotificationCenter.default.post(name: requestsNotification, object: nil)
                                                        
                                                        // Send Push Notification
                                                        // Handle optional chaining for user's apnsId
                                                        if self.userObject!.value(forKey: "apnsId") != nil {
                                                            // MARK: - OneSignal
                                                            // Send push notificaiton
                                                            OneSignal.postNotification(
                                                                ["contents":
                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) confirmed your follow request"],
                                                                 "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
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
        
    }// end CONFIRM
    
    
    
    
    @IBAction func ignore(_ sender: Any) {
        // Disable buttons
        self.confirmButton.isUserInteractionEnabled = false
        self.confirmButton.isEnabled = false
        self.ignoreButton.isUserInteractionEnabled = false
        self.ignoreButton.isEnabled = false
 
        // I G N O R E --->    F O L L O W  R E Q U E S T
        // Delete Follow Request: "FollowMe"
        let follow = PFQuery(className: "FollowMe")
        follow.whereKey("isFollowing", equalTo: false)
        follow.whereKey("following", equalTo: PFUser.current()!)
        follow.whereKey("follower", equalTo: self.userObject!)
        follow.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object.deleteInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully deleted follow request: \(object)")
                            
                            // Delete notifications: "Notifications"
                            let notifications = PFQuery(className: "Notifications")
                            notifications.whereKey("toUser", equalTo: PFUser.current()!)
                            notifications.whereKey("fromUser", equalTo: self.userObject!)
                            notifications.whereKey("type", equalTo: "follow requested")
                            notifications.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    for object in objects! {
                                        object.deleteInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully deleted notification: \(object)")
                                                
                                                // Change button
                                                self.relationState.isHidden = false
                                                self.relationState.setTitle("Ignored", for: .normal)
                                                
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
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })

    }// end IGNORE
    

    @IBAction func rescind(_ sender: Any) {
        // Disable buttons
        self.relationState.isUserInteractionEnabled = false
        self.relationState.isEnabled = false

        // R E S C I N D     F O L L O W     R E Q U E S T
        if self.relationState.titleLabel!.text! == "Rescind Follow Request" {
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Sent Follow Request",
                                                          message: "\(self.rpUsername.text!)")
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
            
            // RESCIND
            dialogController.addAction(AZDialogAction(title: "Rescind", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                
                // Delete from parse: "FollowMe"
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
                                    print("Succesfully deleted follow request: \(object)")
                                    
                                    // Delete from "Notifications": "type" == "follow requested"
                                    let notifications = PFQuery(className: "Notifications")
                                    notifications.whereKey("toUser", equalTo: self.userObject!)
                                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                    notifications.whereKey("type", equalTo: "follow requested")
                                    notifications.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                object.deleteInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully deleted notificaiton: \(object)")
                                                        
                                                        // Change Button's Title
                                                        self.relationState.setTitle("Rescinded", for: .normal)
                                                        
                                                        
                                                        // Post Notification
                                                        NotificationCenter.default.post(name: requestsNotification, object: nil)
                                                        
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

    }// end RESCIND OR UNDO
    
    
    // Function to go to user's profile
    func goUser() {
        // Append object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!)
        // Push VC
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide button
        self.relationState.isHidden = true
        
        // Stylize buttons
        self.confirmButton.setTitle("confirm", for: .normal)
        self.confirmButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        self.confirmButton.layer.cornerRadius = 22.00
        self.confirmButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        self.confirmButton.layer.borderWidth = 1.50
        self.confirmButton.clipsToBounds = true
        
        // Stylize buttons
        self.ignoreButton.setTitle("ignore", for: .normal)
        self.ignoreButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        self.ignoreButton.layer.cornerRadius = 22.00
        self.ignoreButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        self.ignoreButton.layer.borderWidth = 1.50
        self.ignoreButton.clipsToBounds = true
        
        // Stylize buttons
        self.relationState.layer.cornerRadius = 22.00
        self.relationState.clipsToBounds = true
        
        // Add proPicTap to go to user's profile
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        profileTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(profileTap)
        
        // "" to user's username
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        usernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(profileTap)
        
        // "" to user's full name
        let fullNameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        fullNameTap.numberOfTapsRequired = 1
        self.rpFullName.isUserInteractionEnabled = true
        self.rpFullName.addGestureRecognizer(profileTap)

    }
    
}
