//
//  OnBoardFollowCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import OneSignal

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
    
    @IBAction func followAction(_ sender: Any) {
        // Disable buttons to prevent duplicate data entry
        self.followButton.isUserInteractionEnabled = false
        self.followButton.isEnabled = false
        
        // ============================================================================================================================
        // ======================== FOLLOW ============================================================================================
        // ============================================================================================================================
        if self.followButton.title(for: .normal) == "Follow" {
            // Begin Following
            let follow = PFObject(className: "FollowMe")
            follow["follower"] = PFUser.current()!
            follow["following"] = self.userObject!
            follow["followerUsername"] = PFUser.current()!.username!
            follow["followingUsername"] = self.name.text!
            follow["isFollowing"] = true
            follow.saveInBackground()
            
            // Handle optional chaining for user's apnsId
            if self.userObject!.value(forKey: "apnsId") != nil {
                // MARK: - OneSignal
                // Send push notificaiton
                OneSignal.postNotification(
                    ["contents":
                        ["en": "\(PFUser.current()!.username!.uppercased()) started following you."],
                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                     "ios_badgeType": "Increase",
                     "ios_badgeCount": 1
                    ]
                )
            }
            
            // Change button's title and design
            self.followButton.setTitle("Following", for: .normal)
            self.followButton.setTitleColor(UIColor.white, for: .normal)
            self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            self.followButton.layer.cornerRadius = 22.00
            self.followButton.clipsToBounds = true
            
            // Re-enable buttons
            self.followButton.isUserInteractionEnabled = true
            self.followButton.isEnabled = true
        }
        // ============================================================================================================================
        // ======================== FOLLOWING =========================================================================================
        // ============================================================================================================================
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
                                // Change button's title and design
                                self.followButton.setTitle("Follow", for: .normal)
                                self.followButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                                self.followButton.backgroundColor = UIColor.white
                                self.followButton.layer.cornerRadius = 22.00
                                self.followButton.layer.borderWidth = 2.0
                                self.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                                self.followButton.clipsToBounds = true
                                
                                // Re-enable buttons
                                self.followButton.isUserInteractionEnabled = true
                                self.followButton.isEnabled = true
                                
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
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
