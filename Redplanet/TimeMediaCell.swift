//
//  TimeMediaCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SimpleAlert
import SVProgressHUD

class TimeMediaCell: UITableViewCell {
    
    // Initialize delegate
    var delegate: UINavigationController?
    
    // Initialize posts' object: PFObject
    var postObject: PFObject?
    
    // Initialize user's object: PFObject
    var userObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    // Function to go to user's profile
    func goUser(sender: Any) {
        otherObject.append(self.userObject!)
        otherName.append(self.userObject!.value(forKey: "username") as! String)
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.delegate?.pushViewController(otherVC, animated: true)
    }
    
    // Function to like Photo, Profile Photo, or Video
    func like(sender: Any) {
        
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.image(for: .normal) == UIImage(named: "Like-100") {
            
            // Likes
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!
            likes["forObjectId"] = self.postObject?.objectId!
            likes["toUser"] = self.userObject!
            likes["to"] = self.rpUsername.text!
            likes.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    // Change button image
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
                    // Send Notification
                    NotificationCenter.default.post(name: timelineNotification, object: nil)
                    
                    // Animate like button
                    UIView.animate(withDuration: 0.6 ,
                                   animations: {
                                    self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                    },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.5){
                                        self.likeButton.transform = CGAffineTransform.identity
                                    }
                    })
                    
                    
                    
                    // Save to notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = self.rpUsername.text!
                    notifications["toUser"] = self.userObject!.value(forKey: "byUser") as! PFUser
                    notifications["forObjectId"] = self.postObject!.objectId!
                    notifications["type"] = "like \(self.postObject!.value(forKey: "contentType") as! String)"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.userObject!.value(forKey: "apnsId") != nil {
                                
                                if self.postObject!.value(forKey: "contentType") as! String == "ph" {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Photo"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else if self.postObject!.value(forKey: "contentType") as! String == "pp" {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Profile Photo"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                
                                } else if self.postObject!.value(forKey: "contentType") as! String == "vi" {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Video"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
                            }
                            
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
        } else {
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully deleted like: \(object)")
                                
                                // Re-enable buttons
                                self.likeButton.isUserInteractionEnabled = true
                                self.likeButton.isEnabled = true
                                
                                // Change button image
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
                                // Send Notification
                                NotificationCenter.default.post(name: timelineNotification, object: nil)
                                
                                // Animate like button
                                UIView.animate(withDuration: 0.6 ,
                                               animations: {
                                                self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                                },
                                               completion: { finish in
                                                UIView.animate(withDuration: 0.5){
                                                    self.likeButton.transform = CGAffineTransform.identity
                                                }
                                })
                                
                                // Delete "Notifications"
                                let notifications = PFQuery(className: "Notifications")
                                notifications.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                notifications.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            object.deleteInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully deleted notification: \(object)")
                                                    
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
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Tap for rpUserProPic and rpUsername
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        // Tap for rpUsername
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
