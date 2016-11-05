//
//  ActivityCell.swift
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



// KEEP IN MIND


/*
    That when saving things to Notifications, the dataSet
 
            <"forObjectId"> is set as a STRING
    
    SO, the fastest way to is check for the prefix and suffix of the button,
    // Then search for the objectId 
    // liked
    // commented
    // 
 
 */





class ActivityCell: UITableViewCell {
    
    
    // Instantiate parent view controller
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Inialize content object
    var contentObject: PFObject?

    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var activity: UIButton!
    @IBOutlet weak var time: UILabel!
    
    
    // Function to go to user's profile
    func goUser() {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append user's name
        otherName.append(self.rpUsername.titleLabel!.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    
    // Function to go to content
    func goContent(sender: UIButton) {
        
        // LIKE
        if self.activity.titleLabel!.text!.hasPrefix("liked") {
            if self.activity.titleLabel!.text!.hasSuffix("text post") {
                // Check TextPosts
                let texts = PFQuery(className: "Newsfeeds")
                texts.whereKey("objectId", equalTo: self.userObject!.objectId!)
                texts.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            
                            
                            // Append text post object
                            textPostObject.append(object)
                            
                            // Push VC
                            let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                            self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
                
            }
            
            // L I K E D:     P H O T O S
            if self.activity.titleLabel!.text!.hasSuffix("photo") {
                // Check "Photos_Videos"
                let photos = PFQuery(className: "Newsfeeds")
                photos.whereKey("objectId", equalTo: self.contentObject!.objectId!)
                photos.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        // Check Photos
                        for object in objects! {
                            
                            // Append object
                            photoAssetObject.append(object)
                            
                            
                            // Push VC
                            let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                            self.delegate?.navigationController!.pushViewController(photoVC, animated: true)
                            
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            // L I K E D:     P R O F I L E     P H O T O
            if self.activity.titleLabel!.text!.hasSuffix("profile photo") {
                // Check "ProfilePhoto"
                let profilePhoto = PFQuery(className: "Newsfeeds")
                profilePhoto.includeKey("byUser")
                profilePhoto.whereKey("objectId", equalTo: self.contentObject!.objectId!)
                profilePhoto.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            
                            // Append necessary data for ProfilePhoto
                            proPicObject.append(object)
                            
                            // Push ProfilePhoto view controller
                            let proPicVC = self.delegate!.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                            self.delegate!.navigationController!.pushViewController(proPicVC, animated: false)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            
            // L I K E D:     W A L L     P O S T
            // L I K E D:     S P A C E     P O S T
            if self.activity.titleLabel!.text!.hasSuffix("space post") {
            
            }
            
        }
        //////// E N D ------> L I K E
        
        
        
        // L I K E D     Y O U R      C O M M E N T
        if self.activity.titleLabel!.text! == "liked your comment" {
            let comments = PFQuery(className: "Comments")
            comments.whereKey("objectId", equalTo: self.contentObject!.objectId!)
            comments.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // Re-enable buttons
                    self.activity.isUserInteractionEnabled = true
                    self.activity.isEnabled = true
                    
                    for object in objects! {
                        
                        let commentId = object["forObjectId"] as! String
                        
                        // Find content
                        let newsfeeds = PFQuery(className: "Newsfeeds")
                        newsfeeds.whereKey("objectId", equalTo: commentId)
                        newsfeeds.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // TODO::
                                // PUSH VC
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.activity.isUserInteractionEnabled = true
                    self.activity.isEnabled = true
                }
            })
        }
        // END: LIKED COMMENT
        
        
        
        // C O M M E N T E D     O N     Y O U R      C O N T E N T
        if self.activity.titleLabel!.text! == "commented on your content" {
            // TODO:: 
            // Find Comment
            // Find in Newsfeed
            
        }
        // END: COMMENTED ON YOUR CONTENT
        
        
        
        // T A G
        if self.activity.titleLabel!.text!.hasPrefix("tagged you") {
            
        }
        // END: "tagged you in a comment"
        
        
        /////////////////////////////////
        // R E L A T I O N S H I P S   //
        /////////////////////////////////
        // R E Q U E S T E D     T O     F O L L O W     Y O U
        // A S K E D     T O     B E     F R I E N D S
        if self.activity.titleLabel!.text! == "requested to follow you" || activity.titleLabel!.text! == "asked to be friends" {
            
        }
        
        // L E V E L    3
        // I S     N O W     F R I E N D S     W I T H     Y O U
        if self.activity.titleLabel!.text! == "is now friends with you" {
            
        }
        
        // L E V E L    3
        // S T A R T E D     F O L L O W I N G     Y O U
        if self.activity.titleLabel!.text! == "started following you" {

        } ////////// E N D -----> R E L A T I O N S H I P S
        
        
        
        // L E V E L    3
        // V I E W E D      Y O U R     P R O F I L E
        if self.activity.titleLabel!.text! == "viewed your profile" {
            // GONE
        }
        
        // L E V E L    3
        // W R O T E      O N     Y O U R     W A L L
        if self.activity.titleLabel!.text!.hasPrefix("wrote on") {
            // TODO
        }

    }
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Add usernam tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)

        // Add username tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
