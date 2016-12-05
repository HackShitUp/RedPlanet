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

class ContactsCell: UITableViewCell {
    
    // Initialize Parent VC
    var delegate: UIViewController?
    
    // User's object
    var friend: PFObject?

    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var friendButton: UIButton!
    @IBAction func friendAction(_ sender: Any) {
        
        // Disable buttons to prevent duplicate data entry
        self.friendButton.isUserInteractionEnabled = false
        self.friendButton.isEnabled = false
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FRIEND /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.friendButton.titleLabel!.text! == "Friend" {
            
            // (1) Friends
            let friend = PFObject(className: "FriendMe")
            friend["frontFriend"] = PFUser.current()!
            friend["endFriend"] = self.friend
            friend["frontFriendName"] = PFUser.current()!.username!
            friend["endFriendName"] = self.rpUsername.text!
            friend["isFriends"] = false
            // (2) Notifications
            let notifications = PFObject(className: "Notifications")
            notifications["fromUser"] = PFUser.current()!
            notifications["toUser"] = self.friend
            notifications["from"] = PFUser.current()!.username!
            notifications["to"] = self.rpUsername.text!
            notifications["type"] = "friend requested"
            notifications["forObjectId"] = PFUser.current()!.objectId!
            // (3) Objects to save
            var saveObjects = [PFObject]()
            saveObjects.removeAll(keepingCapacity: false)
            saveObjects.append(friend)
            saveObjects.append(notifications)
            // (4) Save both objects simultaneously
            PFObject.saveAll(inBackground: saveObjects, block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    print("Successfully saved objects: \(saveObjects)")
                    
                    // Change button's title and design
                    self.friendButton.setTitle("Friend Requested", for: .normal)
                    self.friendButton.setTitleColor(UIColor.white, for: .normal)
                    self.friendButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                    self.friendButton.layer.cornerRadius = 22.00
                    self.friendButton.clipsToBounds = true
                    
                    
                    // Re-enable buttons
                    self.friendButton.isUserInteractionEnabled = true
                    self.friendButton.isEnabled = true
                    
                    
                    // Send push notificaiton
                    if self.friend!.value(forKey: "apnsId") != nil {
                        OneSignal.postNotification(
                            ["contents":
                                ["en": "\(PFUser.current()!.username!.uppercased()) sent you a friend request"],
                             "include_player_ids": ["\(self.friend!.value(forKey: "apnsId") as! String)"]
                            ]
                        )
                    }
                    
                    
                    // Send to NotificationCenter
                    NotificationCenter.default.post(name: contactsNotification, object: nil)

                } else {
                    print(error?.localizedDescription as Any)
                }
            })

            
        }
        
        
        
        
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FRIENDS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.friendButton.titleLabel!.text! == "Friends" {
            let alert = UIAlertController(title: "Unfriend?",
                                          message: "Are you sure you would like to unfriend \(self.friend!.value(forKey: "realNameOfUser") as! String)?",
                preferredStyle: .alert)
            let yes = UIAlertAction(title: "yes",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        let eFriend = PFQuery(className: "FriendMe")
                                        eFriend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                        eFriend.whereKey("endFriend", equalTo: otherObject.last!)
                                        
                                        let fFriend = PFQuery(className: "FriendMe")
                                        fFriend.whereKey("endFriend", equalTo: PFUser.current()!)
                                        fFriend.whereKey("frontFriend", equalTo: otherObject.last!)
                                        
                                        let friend = PFQuery.orQuery(withSubqueries: [eFriend, fFriend])
                                        friend.whereKey("isFriends", equalTo: true)
                                        friend.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    // If frontFriend
                                                    if object["frontFriend"] as! PFUser == PFUser.current()! && object["endFriend"] as! PFUser ==  otherObject.last! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted friend: \(object)")
                                                                
                                                                
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                        
                                                    }
                                                    
                                                    // If endFriend
                                                    if object["endFriend"] as! PFUser == PFUser.current()! && object["frontFriend"] as! PFUser == otherObject.last! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted friend: \(object)")
                                                                
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                    
                                                }
                                                
                                                
                                                // Set user's friends button
                                                self.friendButton.setTitle("Friend", for: .normal)
                                                self.friendButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
                                                self.friendButton.backgroundColor = UIColor.white
                                                self.friendButton.layer.cornerRadius = 22.00
                                                self.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
                                                self.friendButton.layer.borderWidth = 2.00
                                                self.friendButton.clipsToBounds = true
                                                
                                                // Re-enable buttons
                                                self.friendButton.isUserInteractionEnabled = true
                                                self.friendButton.isEnabled = true
                                                
                                                // Post Notification
                                                NotificationCenter.default.post(name: contactsNotification, object: nil)
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
            })
            let no = UIAlertAction(title: "no",
                                   style: .destructive,
                                   handler: nil)
            
            alert.addAction(no)
            alert.addAction(yes)
            alert.view.tintColor = UIColor.black
            self.delegate?.present(alert, animated: true, completion: nil)
        }
        
        
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // FRIEND REQUESTED ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if self.friendButton.titleLabel!.text! == "Friend Requested" {
            
            
            
            // ========================================================================================================================
            // SENT FRIEND REQUEST ====================================================================================================
            // ========================================================================================================================
            if myRequestedFriends.contains(self.friend!) {
                let alert = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .alert)
                
                let rescind = UIAlertAction(title: "Rescind Friend Request",
                                            style: .default,
                                            handler: {(alertAction: UIAlertAction!) in
                                                // Delete friend request
                                                let friend = PFQuery(className: "FriendMe")
                                                friend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                                friend.whereKey("endFriend", equalTo: self.friend!)
                                                friend.findObjectsInBackground(block: {
                                                    (objects: [PFObject]?, error: Error?) in
                                                    if error == nil {
                                                        for object in objects! {
                                                            object.deleteInBackground(block: {
                                                                (success: Bool, error: Error?) in
                                                                if error == nil {
                                                                    print("Successfully deleted friend request: \(object)")
                                                                    
                                                                    
                                                                    // Delete from "Notifications"
                                                                    let notifications = PFQuery(className: "Notifications")
                                                                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                                                    notifications.whereKey("toUser", equalTo: self.friend!)
                                                                    notifications.whereKey("type", equalTo: "friend requested")
                                                                    notifications.findObjectsInBackground(block: {
                                                                        (objects: [PFObject]?, error: Error?) in
                                                                        if error == nil {
                                                                            for object in objects! {
                                                                                object.deleteInBackground(block: {
                                                                                    (success: Bool, error: Error?) in
                                                                                    if success {
                                                                                        print("Successfully deleted notifications: \(object)")
                                                                                        
                                                                                        // Set user's friends button
                                                                                        self.friendButton.setTitle("Friend", for: .normal)
                                                                                        self.friendButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
                                                                                        self.friendButton.backgroundColor = UIColor.white
                                                                                        self.friendButton.layer.cornerRadius = 22.00
                                                                                        self.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
                                                                                        self.friendButton.layer.borderWidth = 2.00
                                                                                        self.friendButton.clipsToBounds = true
                                                                                        
                                                                                        
                                                                                        
                                                                                        // Re-enable buttons
                                                                                        self.friendButton.isUserInteractionEnabled = true
                                                                                        self.friendButton.isEnabled = true
                                                                                        
                                                                                        
                                                                                        // Send to NotificationCenter
                                                                                        NotificationCenter.default.post(name: contactsNotification, object: nil)
                                                                                        
                                                                                        
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
                
                let cancel = UIAlertAction(title: "Cancel",
                                           style: .cancel,
                                           handler: nil)
                alert.addAction(rescind)
                alert.addAction(cancel)
                alert.view.tintColor = UIColor.black
                self.delegate!.present(alert, animated: true, completion: nil)
            }
            
            
            
            // ========================================================================================================================
            // RECEIVED FRIEND REQUEST ================================================================================================
            // ========================================================================================================================
            if requestedToFriendMe.contains(self.friend!) {
                let alert = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .alert)
                
                let confirm = UIAlertAction(title: "Confirm Friend Request",
                                            style: .default,
                                            handler: {(alertAction: UIAlertAction!) in
                                                // Confirm
                                                // Delete in Notifications
                                                // Send new notification
                                                let friend = PFQuery(className: "FriendMe")
                                                friend.whereKey("isFriends", equalTo: false)
                                                friend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                                friend.whereKey("endFriend", equalTo: self.friend!)
                                                friend.findObjectsInBackground(block: {
                                                    (objects: [PFObject]?, error: Error?) in
                                                    if error == nil {
                                                        for object in objects! {
                                                            object["isFriends"] = true
                                                            object.saveInBackground(block: {
                                                                (success: Bool, error: Error?) in
                                                                if success {
                                                                    print("Successfully confirmed friend request: \(object)")
                                                                    
                                                                    
                                                                    // Delete "Notifications"
                                                                    let notifications = PFQuery(className: "Notifications")
                                                                    notifications.whereKey("fromUser", equalTo: self.friend!)
                                                                    notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                                                    notifications.whereKey("type", equalTo: "friend requested")
                                                                    notifications.findObjectsInBackground(block: {
                                                                        (objects: [PFObject]?, error: Error?) in
                                                                        if error == nil {
                                                                            for object in objects! {
                                                                                object.deleteInBackground(block: {
                                                                                    (succes: Bool, error: Error?) in
                                                                                    if success {
                                                                                        print("Successfully deleted notification: \(object)")
                                                                                        
                                                                                        
                                                                                        // Send new "Notifications"
                                                                                        let notifications = PFObject(className: "Notifications")
                                                                                        notifications["fromUser"] = PFUser.current()!
                                                                                        notifications["from"] = PFUser.current()!.username!
                                                                                        notifications["to"] = self.rpUsername.text!
                                                                                        notifications["toUser"] = self.friend!
                                                                                        notifications["forObjectId"] = self.friend!
                                                                                        notifications["type"] = "friended"
                                                                                        notifications.saveInBackground(block: {
                                                                                            (success: Bool, error: Error?) in
                                                                                            if success {
                                                                                                print("Succesfully sent new notification: \(notifications)")
                                                                                                
                                                                                                // Change button's title and design
                                                                                                self.friendButton.setTitle("Friends", for: .normal)
                                                                                                self.friendButton.setTitleColor(UIColor.white, for: .normal)
                                                                                                self.friendButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                                                                                                self.friendButton.layer.cornerRadius = 22.00
                                                                                                self.friendButton.clipsToBounds = true
                                                                                                
                                                                                                
                                                                                                // Re-enable buttons
                                                                                                self.friendButton.isUserInteractionEnabled = true
                                                                                                self.friendButton.isEnabled = true
                                                                                                
                                                                                                // Send to NotificationCenter
                                                                                                NotificationCenter.default.post(name: contactsNotification, object: nil)
                                                                                                
                                                                                                
                                                                                                // Send push notificaiton
                                                                                                if self.friend!.value(forKey: "apnsId") != nil {
                                                                                                    OneSignal.postNotification(
                                                                                                        ["contents":
                                                                                                            ["en": "\(PFUser.current()!.username!.uppercased()) accepted your friend request"],
                                                                                                         "include_player_ids": ["\(self.friend!.value(forKey: "apnsId") as! String)"]
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
                })
                
                
                let ignore = UIAlertAction(title: "Ignore Friend Request",
                                           style: .destructive,
                                           handler: {(alertAction: UIAlertAction!) in
                                            // Delete friend request
                                            let friend = PFQuery(className: "FriendMe")
                                            friend.whereKey("frontFriend", equalTo: self.friend!)
                                            friend.whereKey("endFriend", equalTo: PFUser.current()!)
                                            friend.whereKey("isFriends", equalTo: false)
                                            friend.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully ignored friend request: \(object)")
                                                                
                                                                // Delete from "Notifications"
                                                                let notifications = PFQuery(className: "Notifications")
                                                                notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                                                notifications.whereKey("fromUser", equalTo: self.friend!)
                                                                notifications.whereKey("type", equalTo: "friend requested")
                                                                notifications.findObjectsInBackground(block: {
                                                                    (objects: [PFObject]?, error: Error?) in
                                                                    if error == nil {
                                                                        for object in objects! {
                                                                            object.deleteInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("Successfully deleted notification: \(object)")
                                                                                    
                                                                                    
                                                                                    
                                                                                    // Set user's friends button
                                                                                    self.friendButton.setTitle("Friend", for: .normal)
                                                                                    self.friendButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
                                                                                    self.friendButton.backgroundColor = UIColor.white
                                                                                    self.friendButton.layer.cornerRadius = 22.00
                                                                                    self.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
                                                                                    self.friendButton.layer.borderWidth = 2.00
                                                                                    self.friendButton.clipsToBounds = true
                                                                                    

                                                                                    
                                                                                    // Re-enable buttons
                                                                                    self.friendButton.isUserInteractionEnabled = true
                                                                                    self.friendButton.isEnabled = true
                                                                                    
                                                                                    
                                                                                    
                                                                                    // Send to NotificationCenter
                                                                                    NotificationCenter.default.post(name: contactsNotification, object: nil)
                                                                                    
                                                                                    
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
                
                
                let cancel = UIAlertAction(title: "Cancel",
                                           style: .cancel,
                                           handler: nil)
                
                
                alert.addAction(confirm)
                alert.addAction(ignore)
                alert.addAction(cancel)
                alert.view.tintColor = UIColor.black
                self.delegate?.present(alert, animated: true, completion: nil)
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
