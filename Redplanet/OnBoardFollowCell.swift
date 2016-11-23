//
//  OnBoardFollowCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class OnBoardFollowCell: UITableViewCell {
    
    // Set user's object
    var userObject: PFObject?
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var bio: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    // Function to follow
    func followUser(sender: UIButton) {
        // Disable buttons to prevent duplicate data entry
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false
        
        if self.followButton.title(for: .normal) == "Follow" {
            // Begin Following
            let follow = PFObject(className: "FollowMe")
            follow["follower"] = PFUser.current()!
            follow["following"] = self.userObject!
            follow["followerUsername"] = PFUser.current()!.username!
            follow["followingUsername"] = self.name.text!
            follow["isFollowing"] = true
            follow.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully followed: \(follow)")
                    
                    // Change button's title and design
                    self.followButton.setTitle("Following", for: .normal)
                    self.followButton.setTitleColor(UIColor.white, for: .normal)
                    self.followButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                    self.followButton.layer.cornerRadius = 22.00
                    self.followButton.clipsToBounds = true
                    
                    // Re-enable buttons
                    self.followButton.isUserInteractionEnabled = true
                    self.followButton.isEnabled = true
                    
                    // Trigger relationship function
                    self.appDelegate.queryRelationships()
                    
                    // Reload data
                    NotificationCenter.default.post(name: onBoardNotification, object: nil)
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        

        if self.followButton.title(for: .normal) == "Following" {
            // Unfollow user
            let follow = PFQuery(className: "FollowMe")
            follow.whereKey("follower", equalTo: PFUser.current()!)
            follow.whereKey("following", equalTo: self.userObject!)
            follow.whereKey("isFollowing", equalTo: true)
            follow.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully unfollowed user: \(object)")
                                
                                // Change button's title and design
                                self.followButton.setTitle("Follow", for: .normal)
                                self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
                                self.followButton.backgroundColor = UIColor.white
                                self.followButton.layer.cornerRadius = 22.00
                                self.followButton.layer.borderWidth = 2.0
                                self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
                                self.followButton.clipsToBounds = true
                                
                                
                                // Re-enable buttons
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                                
                                
                                // Trigger relationship function
                                self.appDelegate.queryRelationships()
                                
                                // Reload data
                                NotificationCenter.default.post(name: onBoardNotification, object: nil)
                                
                                
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
        
        
        
        if self.followButton.title(for: .normal) == "Friend" {
            let friendMe = PFObject(className: "FriendMe")
            friendMe["frontFriend"] = PFUser.current()!
            friendMe["frontFriendName"] = PFUser.current()!.username!
            friendMe["endFriend"] = self.userObject!
            friendMe["endFriendName"] = self.name.text!
            friendMe["isFriends"] = true
            friendMe.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    print("Friended \(friendMe)")
                    
                    // Change button's title and design
                    self.followButton.setTitle("Friend Requested", for: .normal)
                    self.followButton.setTitleColor(UIColor.white, for: .normal)
                    self.followButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                    self.followButton.layer.cornerRadius = 22.00
                    self.followButton.clipsToBounds = true
                    
                    // Re-enable buttons
                    self.followButton.isUserInteractionEnabled = true
                    self.followButton.isEnabled = true
                    
                    // Trigger relationship function
                    self.appDelegate.queryRelationships()
                    
                    // Reload data
                    NotificationCenter.default.post(name: onBoardNotification, object: nil)

                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        
        
        if self.followButton.title(for: .normal) == "Friend Requested" {
            let friends = PFQuery(className: "FriendMe")
            friends.whereKey("frontFriend", equalTo: PFUser.current()!)
            friends.whereKey("endFriend", equalTo: self.userObject!)
            friends.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                
                                print("UnFriended \(object)")
                                
                                // Change button's title and design
                                self.followButton.setTitle("Friend", for: .normal)
                                self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
                                self.followButton.backgroundColor = UIColor.white
                                self.followButton.layer.cornerRadius = 22.00
                                self.followButton.layer.borderWidth = 2.0
                                self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
                                self.followButton.clipsToBounds = true
                                
                                // Re-enable buttons
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                                
                                // Trigger relationship function
                                self.appDelegate.queryRelationships()
                                
                                // Reload data
                                NotificationCenter.default.post(name: onBoardNotification, object: nil)
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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set button design
        followButton.setTitle("Follow", for: .normal)
        followButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        followButton.backgroundColor = UIColor.white
        self.followButton.layer.cornerRadius = 22.00
        self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.followButton.layer.borderWidth = 2.00
        self.followButton.clipsToBounds = true
        
        // Add follow method
        let buttonTap = UITapGestureRecognizer(target: self, action: #selector(followUser))
        buttonTap.numberOfTapsRequired = 1
        self.followButton.isUserInteractionEnabled = true
        self.followButton.addGestureRecognizer(buttonTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
