//
//  OtherUserHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

// Array to hold other user's relationships
var oFriends = [PFObject]()

var oFollowers = [PFObject]()

var oFollowing = [PFObject]()

class OtherUserHeader: UICollectionReusableView {
    
    
    // Initialize AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var numberOfFriends: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var relationType: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var userBio: KILabel!
    
    // Function to show friends
    func showFriends() {
        // Append to forFriends
        forFriends.append(otherObject.last!)
        
        // Push VC
        let friendsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFriendsVC") as! RFriends
        self.delegate?.navigationController?.pushViewController(friendsVC, animated: true)
    }
    
    
    // Function to show followers
    func showFollowers() {
        // Append to forFriends
        forFollowers.append(otherObject.last!)
        
        // Push VC
        let followersVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowersVC") as! RFollowers
        self.delegate?.navigationController?.pushViewController(followersVC, animated: true)
    }
    
    // Function to show followers
    func showFollowing() {
        // Append to forFriends
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
                    // Error?
                }
            }
        }
    }
    
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    
    
    
    // Function to friend
    func friendUser(sender: UIButton) {
        
        
        // TODO::
        // MixPanel Analytics
        
        // Disable connection buttons
        self.friendButton.isUserInteractionEnabled = false
        self.friendButton.isEnabled = false
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false
        
        
        let friend = PFObject(className: "FriendMe")
        friend["frontFriendName"] = PFUser.current()!.username!
        friend["frontFriend"] = PFUser.current()!
        friend["endFriendName"] = otherName.last!
        friend["endFriend"] = otherObject.last!
        friend["isFriends"] = false
        friend.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully saved friend request: \(friend)")
                
                // Show relationship button
                self.relationType.isHidden = false
                self.relationType.isUserInteractionEnabled = true
                self.relationType.isEnabled = true
                self.relationType.setTitle("Friend Requested", for: .normal)
                
                // Send notification
                let notifications = PFObject(className: "Notifications")
                notifications["from"] = PFUser.current()!.username!
                notifications["fromUser"] = PFUser.current()!
                notifications["to"] = otherName.last!
                notifications["forObjectId"] = friend.objectId!
                notifications["toUser"] = otherObject.last!
                notifications["type"] = "friend requested"
                notifications.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully sent notification: \(notifications)")
                        
                        // Re enable buttons
                        self.friendButton.isUserInteractionEnabled = true
                        self.friendButton.isEnabled = true
                        self.followButton.isUserInteractionEnabled = true
                        self.followButton.isEnabled = true
                        
                        
                        // Send push notification
//                        OneSignal.defaultClient().postNotification(
//                            ["contents":
//                                ["en": "\(PFUser.currentUser()!.username!) asked to be friends"],
//                             "include_player_ids": ["\(apnsId.last!)"]
//                            ]
//                        )
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        
        
        // Reload relationships
        appDelegate.queryRelationships()

    } // End Friend
    
    
    
    
    
    
    // Function to follow
    func followUser(sender: UIButton) {
        
        
        // TODO::
        // MixPanel Analytics
        
        
        // Disable connection buttons
        self.friendButton.isUserInteractionEnabled = false
        self.friendButton.isEnabled = false
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false
        
        if otherObject.last!.value(forKey: "private") as! Bool == true {
            
            // Private account
            let follow = PFObject(className: "FollowMe")
            follow["followerUsername"] = PFUser.current()!.username!
            follow["follower"] = PFUser.current()!
            follow["followingUsername"] = otherName.last!
            follow["following"] = otherObject.last!
            follow["isFollowing"] = false
            follow.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved follow request: \(follow)")
                    
                    // Show relationship button
                    self.relationType.isHidden = false
                    self.relationType.isUserInteractionEnabled = true
                    self.relationType.isEnabled = true
                    self.relationType.setTitle("Follow Requested", for: .normal)
                    
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
                            self.friendButton.isUserInteractionEnabled = true
                            self.friendButton.isEnabled = true
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                            
//                            // Send push notification
//                            OneSignal.defaultClient().postNotification(
//                                ["contents":
//                                    ["en": "\(PFUser.currentUser()!.username!) requested to follow you"],
//                                 "include_player_ids": ["\(apnsId.last!)"]
//                                ]
//                            )
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            
            // Public account
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
                            
                            // Send push notification
//                            OneSignal.defaultClient().postNotification(
//                                ["contents": ["en": "\(PFUser.currentUser()!.username!) is now following you"],
//                                 "include_player_ids": ["\(apnsId.last!)"]]
//                            )
                            
                            // Re enable buttons
                            self.friendButton.isUserInteractionEnabled = true
                            self.friendButton.isEnabled = true
                            self.followButton.isUserInteractionEnabled = true
                            self.followButton.isEnabled = true
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        
        
        // Reload relationships
        appDelegate.queryRelationships()

    } // End Follow
    
    
    
    // Function to undo relation
    func relationAction(sender: UIButton) {
        
        
        // TODO::
        // Disable buttons
        
        // **********************************************************************************************************************************
        // ==================================================================================================================================
        // ==================================================================================================================================
        // ======================================= F R I E N D S ============================================================================
        // ==================================================================================================================================
        // ==================================================================================================================================
        // **********************************************************************************************************************************
        if self.relationType.titleLabel!.text == "Friends" {
            // Unfriend user
            let alert = UIAlertController(title: "Unfriend?",
                                          message: "Are you sure you would like to unfriend \(otherName.last!)?",
                preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        
                                        let eFriend = PFQuery(className: "FriendMe")
                                        eFriend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                        eFriend.whereKey("endFriend", equalTo: otherObject.last!)
                                        
                                        let fFriend = PFQuery(className: "FriendMe")
                                        fFriend.whereKey("endFriend", equalTo: PFUser.current()!)
                                        fFriend.whereKey("frontFriend", equalTo: PFUser.current()!)
                                        
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
                                                                
                                                                // Hide and show buttons
                                                                self.relationType.isHidden = true
                                                                self.friendButton.isHidden = false
                                                                self.followButton.isHidden = false
                                                                
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
                                                                
                                                                // Hide and show buttons
                                                                self.relationType.isHidden = true
                                                                self.friendButton.isHidden = false
                                                                self.followButton.isHidden = false
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                    
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
        
        
        
        // **********************************************************************************************************************************
        // ==================================================================================================================================
        // ==================================================================================================================================
        // ======================================= F O L L O W I N G ========================================================================
        // ==================================================================================================================================
        // ==================================================================================================================================
        // **********************************************************************************************************************************
        if self.relationType.titleLabel!.text == "Following" {
            
            
            // UNFOLLOW
            let alert = UIAlertController(title: "Unfollow?",
                                          message: "Are you sure you would like to unfollow \(otherName.last!)?",
                preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        // Unfollow user
                                        let unfollow = PFQuery(className: "FollowMe")
                                        unfollow.whereKey("follower", equalTo: PFUser.current()!)
                                        unfollow.whereKey("following", equalTo: otherObject.last!)
                                        unfollow.whereKey("isFollowing", equalTo: true)
                                        unfollow.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Successfully deleted following: \(object)")
                                                            
                                                            // Send to Notification Center
                                                            NotificationCenter.default.post(name: otherNotification, object: nil)
                                                            
                                                            // Hide and show buttons
                                                            self.relationType.isHidden = true
                                                            self.friendButton.isHidden = false
                                                            self.followButton.isHidden = false
                                                            
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
            
            let cancel = UIAlertAction(title: "no",
                                       style: .destructive,
                                       handler: nil)
            alert.addAction(yes)
            alert.addAction(cancel)
            self.delegate?.present(alert, animated: true, completion: nil)
 

        }
        
        
        
        // **********************************************************************************************************************************
        // ==================================================================================================================================
        // ==================================================================================================================================
        // ======================================= F O L L O W E R  =========================================================================
        // ==================================================================================================================================
        // ==================================================================================================================================
        // **********************************************************************************************************************************
        
        
        if self.relationType.titleLabel!.text == "Follower" {
            // Block user from following you
            let options = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .alert)
            
            let friend = UIAlertAction(title: "Add Friend",
                                       style: .default,
                                       handler: { (alertAction: UIAlertAction!) in
                                        
                                        let alert = UIAlertController(title: "Friend?",
                                                                      message: "Would you like \(otherName.last!) to stop following you and be friends instead?",
                                            preferredStyle: .alert)
                                        
                                        let yes = UIAlertAction(title: "yes",
                                                                style: .default,
                                                                handler: { (alertAction: UIAlertAction!) in
                                                                    
                                                                    // Delete relationship in Parse: "FollowMe"
                                                                    let follow = PFQuery(className: "FollowMe")
                                                                    follow.whereKey("follower", equalTo: otherObject.last!)
                                                                    follow.whereKey("following", equalTo: PFUser.current()!)
                                                                    follow.findObjectsInBackground(block: {
                                                                        (objects: [PFObject]?, error: Error?) in
                                                                        if error == nil {
                                                                            for object in objects! {
                                                                                object.deleteInBackground(block: {
                                                                                    (success: Bool, error: Error?) in
                                                                                    if error == nil {
                                                                                        print("Successfully deleted follow: \(object)")
                                                                                        
                                                                                        // Send new friend request: "FriendMe"
                                                                                        let friends = PFObject(className: "FriendMe")
                                                                                        friends["endFriend"] = otherObject.last!
                                                                                        friends["endFriendName"] = otherName.last!
                                                                                        friends["frontFriend"] = PFUser.current()!
                                                                                        friends["frontFriendName"] = PFUser.current()!.username!
                                                                                        friends["isFriends"] = false
                                                                                        friends.saveInBackground(block: {
                                                                                            (success: Bool, error: Error?) in
                                                                                            if error == nil {
                                                                                                print("Successfully sent friend request: \(friends)")
                                                                                                
                                                                                                // Send notification to end user
                                                                                                let notifications = PFObject(className: "Notifications")
                                                                                                notifications["fromUser"] = PFUser.current()!
                                                                                                notifications["from"] = PFUser.current()!.username!
                                                                                                notifications["to"] = otherName.last!
                                                                                                notifications["toUser"] = otherObject.last!
                                                                                                notifications["type"] = "friend requested"
                                                                                                notifications["forObjectId"] = friends.objectId!
                                                                                                notifications.saveInBackground(block: {
                                                                                                    (success: Bool, error: Error?) in
                                                                                                    if success {
                                                                                                        print("Successfully sent notification: \(notifications)")
                                                                                                        
                                                                                                        // Change button title
                                                                                                        self.friendButton.isHidden = true
                                                                                                        self.followButton.isHidden = true
                                                                                                        self.relationType.setTitle("Friend Requested", for: .normal)
                                                                                                        
                                                                                                        // Send push notification
//                                                                                                        OneSignal.defaultClient().postNotification(
//                                                                                                            ["contents":
//                                                                                                                ["en": "\(PFUser.currentUser()!.username!) asked to be friends"],
//                                                                                                             "include_player_ids": ["\(apnsId.last!)"]
//                                                                                                            ]
//                                                                                                        )
                                                                                                        
                                                                                                    } else {
                                                                                                        print(error?.localizedDescription as Any)
                                                                                                    }
                                                                                                })
                                                                                                
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
            })
            
            let follow = UIAlertAction(title: "Follow",
                                       style: .default,
                                       handler: { (alertAction: UIAlertAction!) in
                                        
                                        let alert = UIAlertController(title: "Follow Back?",
                                                                      message: "Would you like to follow \(otherName.last!)?",
                                            preferredStyle: .alert)
                                        
                                        let yes = UIAlertAction(title: "yes",
                                                                style: .default,
                                                                handler: {(UIAlertAction) -> Void in
                                                                    
                                                                    if otherObject.last!.value(forKey: "private") as! Bool == true {
                                                                        // Private account
                                                                        
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
                                                                                        
                                                                                        // Change sender button title
                                                                                        self.relationType.setTitle("Follow Requested", for: .normal)
                                                                                        
                                                                                        
                                                                                        // Send push notification
//                                                                                        OneSignal.defaultClient().postNotification(
//                                                                                            ["contents":
//                                                                                                ["en": "\(PFUser.currentUser()!.username!) requested to follow you"],
//                                                                                             "include_player_ids": ["\(apnsId.last!)"]
//                                                                                            ]
//                                                                                        )
                                                                                        
                                                                                    } else {
                                                                                        print(error?.localizedDescription as Any)
                                                                                    }
                                                                                })
                                                                                
                                                                            } else {
                                                                                print(error?.localizedDescription as Any)
                                                                            }
                                                                        })
                                                                        
                                                                        
                                                                    } else {
                                                                        
                                                                        // Public account
                                                                        
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
                                                                                        
                                                                                        // Change sender button title
                                                                                        self.relationType.setTitle("Following", for: .normal)
                                                                                        
                                                                                        
                                                                                        // Send push notification
//                                                                                        OneSignal.defaultClient().postNotification(
//                                                                                            ["contents":
//                                                                                                ["en": "\(PFUser.currentUser()!.username!) is now following you"],
//                                                                                             "include_player_ids": ["\(apnsId.last!)"]
//                                                                                            ]
//                                                                                        )
                                                                                        
                                                                                    } else {
                                                                                        print(error?.localizedDescription as Any)
                                                                                    }
                                                                                })
                                                                                
                                                                            } else {
                                                                                print(error?.localizedDescription as Any)
                                                                            }
                                                                        })
                                                                        
                                                                    }
                                        })
                                        
                                        let no = UIAlertAction(title: "no",
                                                               style: .destructive,
                                                               handler: nil)
                                        
                                        alert.addAction(no)
                                        alert.addAction(yes)
                                        self.delegate?.present(alert, animated: true, completion: nil)
                                        
            })
            
            let cancel = UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: nil)
            
            options.addAction(follow)
            options.addAction(friend)
            options.addAction(cancel)
            self.delegate?.present(options, animated: true, completion: nil)
            
        }
        
        
        // **********************************************************************************************************************************
        // ==================================================================================================================================
        // ==================================================================================================================================
        // ======================================= F R I E N D     R E Q U E S T E D ========================================================
        // ==================================================================================================================================
        // ==================================================================================================================================
        // **********************************************************************************************************************************
        
        
        if self.relationType.titleLabel!.text! == "Friend Requested" {
            
            
            let options = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .alert)
            
            let confirm = UIAlertAction(title: "Confirm Friend Request",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
                                            // Confirm friend request
                                            let friends = PFQuery(className: "FriendMe")
                                            friends.whereKey("endFriend", equalTo: PFUser.current()!)
                                            friends.whereKey("frontFriend", equalTo: otherObject.last!)
                                            friends.whereKey("isFriends", equalTo: false)
                                            friends.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object["isFriends"] = true
                                                        object.saveInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully confirmed friend request: \(object)")
                                                                
                                                                
                                                                // Save to notification and send push notification
                                                                let notifications = PFObject(className: "Notifications")
                                                                notifications["fromUser"] = PFUser.current()!
                                                                notifications["from"] = PFUser.current()!.username!
                                                                notifications["to"] = otherName.last!
                                                                notifications["toUser"] = otherObject.last!
                                                                notifications["type"] = "friended"
                                                                notifications["forObjectId"] = otherObject.last!.objectId!
                                                                notifications.saveInBackground(block: {
                                                                    (success: Bool, error: Error?) in
                                                                    if success {
                                                                        print("Successfully saved notification: \(notifications)")
                                                                        
                                                                        // Change Button's Title
                                                                        self.relationType.setTitle("Friends", for: .normal)
                                                                        
                                                                        // Send push notification
//                                                                        OneSignal.defaultClient().postNotification(
//                                                                            ["contents":
//                                                                                ["en": "\(PFUser.currentUser()!.username!) confirmed your friend request"],
//                                                                             "include_player_ids": ["\(apnsId.last!)"]
//                                                                            ]
//                                                                        )
                                                                        
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
                                        // Delete Friend Request
                                        // Confirm friend request
                                        let friends = PFQuery(className: "FriendMe")
                                        friends.whereKey("endFriend", equalTo: PFUser.current()!)
                                        friends.whereKey("frontFriend", equalTo: otherObject.last!)
                                        friends.whereKey("isFriends", equalTo: false)
                                        friends.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object["isFriends"] = true
                                                    object.deleteInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Successfully ignored friend request: \(object)")
                                                            
                                                            
                                                            
                                                            // Delete from Notifications
                                                            let notifications = PFQuery(className:"Notifications")
                                                            notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                                            notifications.whereKey("fromUser", equalTo: otherObject.last!)
                                                            notifications.whereKey("type", equalTo: "friend requested")
                                                            notifications.findObjectsInBackground(block: {
                                                                (objects: [PFObject]?, error: Error?) in
                                                                if error == nil {
                                                                    for object in objects! {
                                                                        object.deleteInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully deleted notification: \(object)")
                                                                                
                                                                                // Hide and show buttons
                                                                                self.relationType.isHidden = true
                                                                                self.friendButton.isHidden = false
                                                                                self.followButton.isHidden = false
                                                                                
                                                                                
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
            
            
            let unfriend = UIAlertAction(title: "Rescind Friend Request",
                                         style: .default,
                                         handler: {(alertAction: UIAlertAction!) in
                                            // Rescind friend request
                                            let friends = PFQuery(className: "FriendMe")
                                            friends.whereKey("frontFriend", equalTo: PFUser.current()!)
                                            friends.whereKey("endFriend", equalTo: otherObject.last!)
                                            friends.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted friend: \(object)")
                                                                
                                                                // Delete notifications
                                                                let notifications = PFQuery(className: "Notifications")
                                                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                                                notifications.whereKey("toUser", equalTo: otherObject.last!)
                                                                notifications.whereKey("type", equalTo: "friend requested")
                                                                notifications.findObjectsInBackground(block: {
                                                                    (objects: [PFObject]?, error: Error?) in
                                                                    if error == nil {
                                                                        for object in objects! {
                                                                            object.deleteInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("Successfully deleted friend notification: \(object)")
                                                                                    
                                                                                    // Hide and show buttons
                                                                                    self.relationType.isHidden = true
                                                                                    self.friendButton.isHidden = false
                                                                                    self.followButton.isHidden = false
                                                                                    
                                                                                    
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
            
            
            
            
            // Set friend requests
            if myRequestedFriends.contains(otherObject.last!) {
                // "Rescind Friend Request"
                options.addAction(unfriend)
                // "Cancel"
                options.addAction(cancel)
                self.delegate!.present(options, animated: true, completion: nil)
            }
            
            if requestedToFriendMe.contains(otherObject.last!) {
                // "Confirm Friend Request"
                options.addAction(confirm)
                // "Ignore Friend Request"
                options.addAction(ignore)
                // "Cancel"
                options.addAction(cancel)
                self.delegate!.present(options, animated: true, completion: nil)
            }
            
            
            
            
        }
        
        
        
        
        // **********************************************************************************************************************************
        // ==================================================================================================================================
        // ==================================================================================================================================
        // ======================================= F O L L O W     R E Q U E S T E D ========================================================
        // ==================================================================================================================================
        // ==================================================================================================================================
        // **********************************************************************************************************************************
        
        
        if self.relationType.titleLabel!.text! == "Follow Requested" {
            
            
            let options = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .alert)
            
            // RECEIVED
            
            // Confirm
            let confirm = UIAlertAction(title: "Confirm Follow Request",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
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
                                                                print("Successfully accepted follower: \(object)")
                                                                
                                                                // Change button title
                                                                sender.setTitle("Follower", for: .normal)
                                                                
                                                                // Send push notification
//                                                                OneSignal.defaultClient().postNotification(
//                                                                    ["contents":
//                                                                        ["en": "\(PFUser.currentUser()!.username!) confirmed your follow request"],
//                                                                     "include_player_ids": ["\(apnsId.last!)"]
//                                                                    ]
//                                                                )
                                                                
                                                                
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
            
            
            // Ignore
            let ignore = UIAlertAction(title: "Ignore Follow Request",
                                       style: .destructive,
                                       handler: {(alertAction: UIAlertAction!) in
                                        
                                        // TODO::
                                        // Delete request
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
                                                            print("Successfully deleted object: \(object)")
                                                            
                                                            // Delete Notification
                                                            let notifications = PFQuery(className: "Notifications")
                                                            notifications.whereKey("toUser", equalTo: PFUser.current()!)
                                                            notifications.whereKey("fromUser", equalTo: otherObject.last!)
                                                            notifications.whereKey("type", equalTo: "follow requested")
                                                            notifications.findObjectsInBackground(block: {
                                                                (objects: [PFObject]?, error: Error?) in
                                                                if error == nil {
                                                                    for object in objects! {
                                                                        object.deleteInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully deleted notification: \(object)")
                                                                                
                                                                                
                                                                                // Hide button
                                                                                // Hide and show buttons
                                                                                self.relationType.isHidden = true
                                                                                self.friendButton.isHidden = false
                                                                                self.followButton.isHidden = false
                                                                                
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
            
            let rescind = UIAlertAction(title: "Rescind Follow Request",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction) in
                                            let follow = PFQuery(className: "FollowMe")
                                            follow.whereKey("follower", equalTo: PFUser.current()!)
                                            follow.whereKey("following", equalTo: otherObject.last!)
                                            follow.whereKey("isFollowing", equalTo: false)
                                            follow.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted follow request: \(object)")
                                                                
                                                                // Delete in notifications
                                                                let notifications = PFQuery(className: "Notifications")
                                                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                                                notifications.whereKey("toUser", equalTo: otherObject.last!)
                                                                notifications.whereKey("type", equalTo: "follow requested")
                                                                notifications.findObjectsInBackground(block: {
                                                                    (objects: [PFObject]?, error: Error?) in
                                                                    if error == nil {
                                                                        for object in objects! {
                                                                            object.deleteInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("Successfully deleted follow request notification: \(object)")
                                                                                    
                                                                                    // Send to Notification Center
                                                                                    NotificationCenter.default.post(name: otherNotification, object: nil)
                                                                                    
                                                                                    // Hide and show buttons
                                                                                    self.relationType.isHidden = true
                                                                                    self.friendButton.isHidden = false
                                                                                    self.followButton.isHidden = false
                                                                                    
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
            
            
            
            if myRequestedFollowers.contains(otherObject.last!) {
                options.addAction(confirm)
                options.addAction(ignore)
                options.addAction(cancel)
                self.delegate?.present(options, animated: true, completion: nil)
            }
            
            if myRequestedFollowing.contains(otherObject.last!) {
                options.addAction(rescind)
                options.addAction(cancel)
                self.delegate?.present(options, animated: true, completion: nil)
            }
            
            
        }
        
        
        
        // Reload relationships
        appDelegate.queryRelationships()
        
    }// End relation
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Center text
        numberOfFriends.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        
        // (2) Count relationships
        // COUNT FRIENDS
        let endFriend = PFQuery(className: "FriendMe")
        endFriend.whereKey("endFriend", equalTo: otherObject.last!)
        endFriend.whereKey("frontFriend", notEqualTo: otherObject.last!)
        
        let frontFriend = PFQuery(className: "FriendMe")
        frontFriend.whereKey("frontFriend", equalTo: otherObject.last!)
        frontFriend.whereKey("endFriend", notEqualTo: otherObject.last!)
        
        let countFriends = PFQuery.orQuery(withSubqueries: [endFriend, frontFriend])
        countFriends.whereKey("isFriends", equalTo: true)
        countFriends.countObjectsInBackground(block: {
            (count: Int32, error: Error?) -> Void in
            if error == nil {
                self.numberOfFriends.setTitle("\(count)\nfriends", for: .normal)
            } else {
                self.numberOfFriends.setTitle("0\nfriends", for: .normal)
            }
        })
        
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
        
        
        self.friendButton.backgroundColor = UIColor.white
        self.friendButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.friendButton.layer.borderWidth = 3.00
        self.friendButton.layer.cornerRadius = 22.00
        self.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.friendButton.clipsToBounds = true
        
        self.followButton.backgroundColor = UIColor.white
        self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.followButton.layer.borderWidth = 4.00
        self.followButton.layer.cornerRadius = 22.00
        self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.followButton.clipsToBounds = true
        
        
        
        // (4) Handle KILabel taps
        // Handle @username tap
        userBio.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            //            // Query data
            //            let user = PFUser.query()!
            //            user.whereKey("username", equalTo: mention.lowercaseString)
            //            user.findObjectsInBackgroundWithBlock({
            //                (objects: [PFObject]?, error: NSError?) in
            //                if error == nil {
            //                    for object in objects! {
            //                        // Append user's username
            //                        otherName.append(mention)
            //                        // Append user object
            //                        otherObject.append(object)
            //
            //
            //                        let otherUser = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("otherUser") as! OtherUserProfile
            //                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
            //                    }
            //                } else {
            //                    print(error?.localizedDescription as Any)
            //                }
            //            })
        }
        
        
        // Handle #object tap
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            //            var mention = handle
            //            mention = String(mention.characters.dropFirst())
            //            hashtags.append(mention.lowercaseString)
            //            let hashTags = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("hashTags") as! Hashtags
            //            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        // Handle http: tap
        userBio.urlLinkTapHandler = { label, handle, range in
            // Open url
            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
            self.delegate?.present(modalWeb, animated: true, completion: nil)
        }
        
        
        // (5) Number of... Number of... Number of...
        // Add tap methods to show friends, followers, and following
        // (a) Friends
        let friendsTap = UITapGestureRecognizer(target: self, action: #selector(showFriends))
        friendsTap.numberOfTapsRequired = 1
        self.numberOfFriends.isUserInteractionEnabled = true
        self.numberOfFriends.addGestureRecognizer(friendsTap)
        
        // (b) Followers
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(showFollowers))
        followersTap.numberOfTapsRequired = 1
        self.numberOfFollowers.isUserInteractionEnabled = true
        self.numberOfFollowers.addGestureRecognizer(followersTap)
        
        // (c) Following
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(showFollowing))
        followingTap.numberOfTapsRequired = 1
        self.numberOfFollowing.isUserInteractionEnabled = true
        self.numberOfFollowing.addGestureRecognizer(followingTap)
        
        
        
        
        // Relationship Actions
        // (6) Add Relation button tap
        let relationTap = UITapGestureRecognizer(target: self, action: #selector(relationAction))
        relationTap.numberOfTapsRequired = 1
        self.relationType.isUserInteractionEnabled = true
        self.relationType.addGestureRecognizer(relationTap)
        
        
        // (7) Add Friend Tap
        let doFriend = UITapGestureRecognizer(target: self, action: #selector(friendUser))
        doFriend.numberOfTapsRequired = 1
        self.friendButton.isUserInteractionEnabled = true
        self.friendButton.addGestureRecognizer(doFriend)
        
        
        // (8) Add Follow Tap
        let doFollow = UITapGestureRecognizer(target: self, action: #selector(followUser))
        doFollow.numberOfTapsRequired = 1
        self.followButton.isUserInteractionEnabled = true
        self.followButton.addGestureRecognizer(doFollow)
        
        
        
        
        // (9) Add tap method to show profile photo
        // Show Profile photo if friends
        if myFriends.contains(otherObject.last!) && otherObject.last!.value(forKey: "proPicExists") as! Bool == true {
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
        
        

    }
        
}
