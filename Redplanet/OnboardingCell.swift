//
//  OnboardingCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 6/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

/*
 UITableViewCell Class; Part of "Onboarding.swift"
 • Binds the user's data to this class when allowing new users to follow public accounts.
 • Manages the actions to follow/unfollow these public accounts.
 */


class OnboardingCell: UITableViewCell {

    // Set user's object
    var userObject: PFObject?
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var bio: KILabel!
    @IBOutlet weak var followButton: UIButton!
    
    
    @IBAction func follow(_ sender: Any) {
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
            follow["followingUsername"] = self.rpUsername.text!
            follow["isFollowing"] = true
            follow.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                    let rpHelpers = RPHelpers()
                    rpHelpers.pushNotification(toUser: self.userObject!, activityType: "started following you")
                    
                    // Change button's title and design
                    self.followButton.setTitle("Following", for: .normal)
                    self.followButton.setTitleColor(UIColor.white, for: .normal)
                    self.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                    self.followButton.layer.cornerRadius = self.followButton.frame.size.height/2
                    self.followButton.clipsToBounds = true
                    
                    // Re-enable buttons
                    self.followButton.isUserInteractionEnabled = true
                    self.followButton.isEnabled = true
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
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
                                self.followButton.layer.cornerRadius = self.followButton.frame.size.height/2
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


}
