//
//  RelationshipRequestsCell.swift
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

class RelationshipRequestsCell: UICollectionViewCell {
    
    
    // Variable to determine whether current user sent a friend or follow request
    var friendFollow: String?
    
    // Variable to hold user's object
    var userObject: PFObject?
    
    // Variable to set delegate
    var delegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
        
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var ignoreButton: UIButton!
    @IBOutlet weak var relationState: UIButton!
    
    
    // Function to confirm
    func confirm(sender: UIButton) {
        
        
        // FRIEND
        if requestType == "friends" {
            let friends = PFQuery(className: "FriendMe")
            friends.whereKey("endFriend", equalTo: PFUser.current()!)
            friends.whereKey("frontFriend", equalTo: self.userObject!)
            friends.whereKey("isFriends", equalTo: false)
            friends.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object["isFriends"] = true
                        object.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully accepted friend request")
                                
                                
                                // Delete from "Notifications"
                                let dnotifications = PFQuery(className: "Notifications")
                                dnotifications.whereKey("toUser", equalTo: PFUser.current()!)
                                dnotifications.whereKey("fromUser", equalTo: self.userObject!)
                                dnotifications.whereKey("type", equalTo: "friend requested")
                                dnotifications.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            object.deleteInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully deleted notification: \(object)")
                                                    
                                                    
                                                    // Send to Notifications: "friended" = accepted friend request
                                                    let notifications = PFObject(className: "Notifications")
                                                    notifications["from"] = PFUser.current()!.username!
                                                    notifications["fromUser"] = PFUser.current()!
                                                    notifications["forObjectId"] = self.userObject!.objectId!
                                                    notifications["to"] = self.rpUsername.text!
                                                    notifications["toUser"] = self.userObject!
                                                    notifications["type"] = "friended"
                                                    notifications.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if error == nil {
                                                            print("Successfully sent notification: \(notifications)")
                                                            
                                                            // Hide block button
                                                            self.ignoreButton.isHidden = true
                                                            self.confirmButton.isHidden = true
                                                            
                                                            // Unhide currentState button
                                                            // Set title to "CONFIRMED"
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
                                                                        ["en": "\(PFUser.current()!.username!.uppercased()) accepted your friend request"],
                                                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"]
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
        }
    
    
    
    
    
    
    
    
        // FOLLOW
        if requestType == "follow" {
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
                                print("Succesfully accepted follow request: \(object)")
                                
                                
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
                                                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"]
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
        }
        
        
        
    } // end Confirmation
    
    
    
    
    
    
    
    
    // Function to ignore
    func ignore(sender: UIButton) {
        
        
        
        // (1) Delete Parse Object
        // (2) Delete from "Notifications"
        
        // D E L E T E --->    F R I E N D  R E Q U E S T
        if requestType == "friends" {
            let friends = PFQuery(className: "FriendMe")
            friends.whereKey("isFriends", equalTo: false)
            friends.whereKey("endFriend", equalTo: PFUser.current()!)
            friends.whereKey("frontFriend", equalTo: self.userObject!)
            friends.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully deleted friend request: \(object)")
                                
                                // Delete from notifications
                                let notifications = PFQuery(className: "Notifications")
                                notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                notifications.whereKey("fromUser", equalTo: self.userObject!)
                                notifications.whereKey("type", equalTo: "friend requested")
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
                                                    
                                                    // Post Notification
                                                    // NotificationCenter.default.post(name: requestsNotification, object: nil)
                                                    
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
        }
        
        
        // I G N O R E --->    F O L L O W  R E Q U E S T
        if requestType == "followers" {
            
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
                                                    
                                                    // Post Notification
                                                    // NotificationCenter.default.post(name: requestsNotification, object: nil)
                                                    
                                                    
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
        }
        
        
        
    }
    
    
    
    
    
    
    
    // Function to rescind requests
    func rescind(sender: UIButton) {
        
        
        
        // R E S C I N D      F R I E N D      R E Q U E S T
        if self.relationState.titleLabel!.text == "Rescind Friend Request" {
            let alert = UIAlertController(title: "Rescind Friend Request?",
                                          message: "Are you sure you'd like to unfriend \(self.rpFullName.text!)?",
                preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        // Delete from parse: "FriendMe"
                                        let friend = PFQuery(className: "FriendMe")
                                        friend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                        friend.whereKey("endFriend", equalTo: self.userObject!)
                                        friend.whereKey("isFriends", equalTo: false)
                                        friend.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Successfully rescinded friend request: \(object)")
                                                            
                                                            // Delete from "Notifcations": "type" == "friend requested"
                                                            let notifications = PFQuery(className: "Notifications")
                                                            notifications.whereKey("toUser", equalTo: self.userObject!)
                                                            notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                                            notifications.whereKey("type", equalTo: "friend requested")
                                                            notifications.findObjectsInBackground(block: {
                                                                (objects: [PFObject]?, error: Error?) in
                                                                if error == nil {
                                                                    for object in objects! {
                                                                        object.deleteInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully deleted notification: \(object)")
                                                                                
                                                                                // Hide buttons
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
            })
            
            let no = UIAlertAction(title: "no",
                                   style: .destructive,
                                   handler: nil)
            
            alert.addAction(yes)
            alert.addAction(no)
            self.delegate?.present(alert, animated: true, completion: nil)
        }
        
        
        // R E S C I N D     F O L L O W     R E Q U E S T
        if self.relationState.titleLabel!.text! == "Rescind Follow Request" {
            let alert = UIAlertController(title: "Rescind Follow Request?",
                                          message: "Are you sure you'd like to unfollow \(self.rpUsername.text!)?",
                preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
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
                                        
            })
            
            let no = UIAlertAction(title: "no",
                                   style: .destructive,
                                   handler: nil)
            
            alert.addAction(yes)
            alert.addAction(no)
            self.delegate?.present(alert, animated: true, completion: nil)
        }

    }
    
    
    
    // Function to go to user's profile
    func goUser() {
        // Append object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide button
        self.relationState.isHidden = true
        
        // Stylize buttons
        self.confirmButton.setTitle("confirm", for: .normal)
        self.confirmButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.confirmButton.layer.cornerRadius = 22.00
        self.confirmButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.confirmButton.layer.borderWidth = 1.50
        self.confirmButton.clipsToBounds = true
        
        // Stylize buttons
        self.ignoreButton.setTitle("ignore", for: .normal)
        self.ignoreButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.ignoreButton.layer.cornerRadius = 22.00
        self.ignoreButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.ignoreButton.layer.borderWidth = 1.50
        self.ignoreButton.clipsToBounds = true
        
        
        // Stylize buttons
        self.relationState.layer.cornerRadius = 22.00
        self.relationState.clipsToBounds = true
        
        
        // Add button tap to confirm
        let confirmTap = UITapGestureRecognizer(target: self, action: #selector(confirm))
        confirmTap.numberOfTapsRequired = 1
        self.confirmButton.isUserInteractionEnabled = true
        self.confirmButton.addGestureRecognizer(confirmTap)
        
        
        // Add button tap to ignore
        let ignoreTap = UITapGestureRecognizer(target: self, action: #selector(ignore))
        ignoreTap.numberOfTapsRequired = 1
        self.ignoreButton.isUserInteractionEnabled = true
        self.ignoreButton.addGestureRecognizer(ignoreTap)
        
        
        // Add button tap to rescind
        let rescindTap = UITapGestureRecognizer(target: self, action: #selector(rescind))
        rescindTap.numberOfTapsRequired = 1
        self.relationState.isUserInteractionEnabled = true
        self.relationState.addGestureRecognizer(rescindTap)
        
        
        
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
