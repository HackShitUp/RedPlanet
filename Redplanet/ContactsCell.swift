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
    
    
    // Friend button
    func friendButton(sender: UIButton) {
        // Disable buttons to prevent duplicate data entry
        self.friendButton.isUserInteractionEnabled = false
        self.friendButton.isEnabled = false
        
        if sender.title(for: .normal) == "Friend" {
            let friend = PFObject(className: "FriendMe")
            friend["frontFriend"] = PFUser.current()!
            friend["endFriend"] = self.friend
            friend["frontFriendName"] = PFUser.current()!.username!
            friend["endFriendName"] = self.rpUsername.text!
            friend["isFriends"] = false
            friend.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully sent friend request: \(friend)")
                    
                    // Re-enable buttons
                    self.friendButton.isUserInteractionEnabled = true
                    self.friendButton.isEnabled = true
                    
                    
                    // Send to Notifications
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["toUser"] = self.friend
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = self.rpUsername.text!
                    notifications["type"] = "friend requested"
                    notifications["forObjectId"] = PFUser.current()!.objectId!
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved to Notifications: \(notifications)")
                            

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
        
        
        if sender.title(for: .normal) == "Friend Requested" {
            
            if myRequestedFriends.contains(self.friend!) {
                let alert = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .actionSheet)
                
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
                self.delegate!.present(alert, animated: true, completion: nil)
            }
            
            
            if requestedToFriendMe.contains(self.friend!) {
                let alert = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .actionSheet)
                
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
                                                                    
                                                                    // Re-enable buttons
                                                                    self.friendButton.isUserInteractionEnabled = true
                                                                    self.friendButton.isEnabled = true
                                                                    
                                                                    
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
