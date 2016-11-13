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
        
        
        // A
        // LIKED
        if self.activity.titleLabel!.text!.hasPrefix("liked") {
            
            
            // I
            // TEXT POST
            if self.activity.titleLabel!.text!.hasSuffix("text post") {
                // Check TextPosts
                let texts = PFQuery(className: "Newsfeeds")
                texts.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
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
            
            
            // II
            // PHOTO
            if self.activity.titleLabel!.text!.hasSuffix("photo") {
                // Check "Photos_Videos"
                let photos = PFQuery(className: "Newsfeeds")
                photos.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
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
            
            
            
            // III
            // PROFILE PHOTO
            if self.activity.titleLabel!.text!.hasSuffix("profile photo") {
                let profilePhoto = PFQuery(className: "Newsfeeds")
                profilePhoto.includeKey("byUser")
                profilePhoto.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
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
            

            // IV
            // SHARE
            if self.activity.titleLabel!.text!.hasSuffix("shared post") {
                let share = PFQuery(className: "Newsfeeds")
                share.includeKey("byUser")
                share.whereKey("contentType", equalTo: "sh")
                share.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                share.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            
                            // Append object
                            sharedObject.append(object)
                            
                            // Push VC
                            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                            self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            
            
            // V
            // SPACE POST
            if self.activity.titleLabel!.text!.hasSuffix("space post") {
                let spacePost = PFQuery(className: "Newsfeeds")
                spacePost.whereKey("toUser", equalTo: PFUser.current()!)
                spacePost.whereKey("contentType", equalTo: "sp")
                spacePost.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                spacePost.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            spaceObject.append(object)
                            
                            // Push VC
                            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                            self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            // VI
            // MOMENT
            if self.activity.titleLabel!.text!.hasSuffix("moment") {
                let moment = PFQuery(className: "Newsfeeds")
                moment.whereKey("byUser", equalTo: PFUser.current()!)
                moment.whereKey("contentType", equalTo: "itm")
                moment.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                moment.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            itmObject.append(object)
                            
                            // Push VC
                            let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                            self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            
            // VII
            // VIDEO
            if self.activity.titleLabel!.text!.hasSuffix("video") {
                
            }
            
        } // End Liked Content
        
        
        // B
        // LIKED COMMENT
        if self.activity.titleLabel!.text! == "liked your comment" {

            // Disable buttons
            self.activity.isUserInteractionEnabled = false
            self.activity.isEnabled = false
            
            // Find content
            let comments = PFQuery(className: "Comments")
            comments.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
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
                                
                                // PUSH VC
                                for object in objects! {

                                    // I TEXT POST
                                    if object["contentType"] as! String  == "tp" {
                                        // Append object
                                        textPostObject.append(object)
                                        
                                        // Push VC
                                        let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                                        self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                                    }
                                    
                                    // II PHOTO
                                    if object["contentType"] as! String  == "ph" {
                                        // Append object
                                        photoAssetObject.append(object)
                                        
                                        // Push VC
                                        let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                                        self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                                    }

                                    // III SHARED POST
                                    if object["contentType"] as! String == "sh" {
                                        // Append object
                                        sharedObject.append(object)
                                        
                                        // Push VC
                                        let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                                        self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                                    }
                                    
                                    // IV PROFILE PHOTO
                                    if object["contentType"] as! String == "pp" {
                                        // Append object
                                        proPicObject.append(object)
                                        
                                        // Push VC
                                        let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                        self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                                    }
                                    
                                    // VI SPACE POST
                                    if object["contentType"] as! String == "sp" {
                                        // Append object
                                        spaceObject.append(object)
                                        
                                        // Append to otherObject
                                        otherObject.append(object["toUser"] as! PFUser)
                                        // Append to otherName
                                        otherName.append(object["toUsername"] as! String)
                                        
                                        // Push VC
                                        let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                                        self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                                    }
                                    
                                    // VII MOMENT
                                    if object["contentType"] as! String == "itm" {
                                        // Append object
                                        itmObject.append(object)
                                        
                                        // Push VC
                                        let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                        self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                                    }
                                    
                                }
                                
                                
                                
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

        }// End liked comment

        
        
        
        
        // C
        // COMMENT
        if self.activity.titleLabel!.text! == "commented on your post" {

            // Disable buttons
            self.activity.isUserInteractionEnabled = false
            self.activity.isEnabled = false
            
            // Find Comment
            // Find in Newsfeed
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
            newsfeeds.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // Re-enable buttons
                    self.activity.isUserInteractionEnabled = true
                    self.activity.isEnabled = true
                    
                    // PUSH VC
                    for object in objects! {
                        
                        // I TEXT POST
                        if object["contentType"] as! String  == "tp" {
                            // Append object
                            textPostObject.append(object)
                            
                            // Push VC
                            let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                            self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                        }
                        
                        // II PHOTO
                        if object["contentType"] as! String  == "ph" {
                            // Append object
                            photoAssetObject.append(object)
                            
                            // Push VC
                            let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                            self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                        }
                        
                        // III SHARED POST
                        if object["contentType"] as! String == "sh" {
                            // Append object
                            sharedObject.append(object)
                            
                            // Push VC
                            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                            self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                        }
                        
                        // IV PROFILE PHOTO
                        if object["contentType"] as! String == "pp" {
                            // Append object
                            proPicObject.append(object)
                            
                            // Push VC
                            let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                            self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                        }
                        
                        // VI SPACE POST
                        if object["contentType"] as! String == "sp" {
                            // Append object
                            spaceObject.append(object)
                            
                            // Append to otherObject
                            otherObject.append(object["toUser"] as! PFUser)
                            // Append to otherName
                            otherName.append(object["toUsername"] as! String)
                            
                            // Push VC
                            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                            self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                        }
                        
                        // VII MOMENT
                        if object["contentType"] as! String == "itm" {
                            // Append object
                            itmObject.append(object)
                            
                            // Push VC
                            let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                            self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                        }
                        
                    }
                    
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.activity.isUserInteractionEnabled = true
                    self.activity.isEnabled = true
                }
            })

            
        }// End commented on your content
        
        
        
        // D
        // SHARE
        if self.activity.titleLabel!.text!.hasPrefix("shared your") || self.activity.titleLabel!.text!.hasPrefix("re-shared your") {
            
            // Disable buttons
            self.activity.isUserInteractionEnabled = false
            self.activity.isEnabled = false
            
            // (1) Text Post
            if self.activity.titleLabel!.text!.hasSuffix("text post") {
                // Find Text Post
                let newsfeeds = PFQuery(className: "Newsfeed")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            textPostObject.append(object)
                            
                            // Push to VC
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
            

            // (2) Photo
            if self.activity.titleLabel!.text!.hasSuffix("photo") {
                // Find Photo
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                           // Append object
                            photoAssetObject.append(object)
                            
                            // Push to VC
                            let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                            self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            // (3) Profile Photo
            if self.activity.titleLabel!.text!.hasSuffix("profile photo") {
                // Find Profile Photo
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            proPicObject.append(object)
                            
                            // Push to VC
                            let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                            self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                        }
                        
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            
            // (4) Shared Post
            if self.activity.titleLabel!.text!.hasSuffix("shared post") {
                // Find Shared Post
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            sharedObject.append(object)
                            
                            // Push to VC
                            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                            self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            // (5) Space Post
            if self.activity.titleLabel!.text!.hasSuffix("space post") {
                // Find Moment
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            spaceObject.append(object)
                            
                            // Append otherObject
                            otherObject.append(object["toUser"] as! PFUser)
                            // Append otherName
                            otherName.append(object["toUsername"] as! String)
                            
                            // Push to VC
                            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                            self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            // (6) Moment
            if self.activity.titleLabel!.text!.hasSuffix("moment") {
                // Find Moment
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            // Append object
                            itmObject.append(object)
                            
                            // Push to VC
                            let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                            self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            
            // (7) VIDEO
            // TODO::
            
        }// End Shared
        
        
        
        
        
        // T A G
        if self.activity.titleLabel!.text!.hasPrefix("tagged you in a") {
            // TODO::
            
            
            
            // I Text Post
            if self.activity.titleLabel!.text!.hasSuffix("text post"){
                
            }
            
            // II Photo
            if self.activity.titleLabel!.text!.hasSuffix("photo") {
                
            }
            
            // III Profile Photo
            if self.activity.titleLabel!.text!.hasSuffix("profile photo") {
                
            }
            
            // IV Space Post
            if self.activity.titleLabel!.text!.hasSuffix("space post") {
                
            }
            
            // V Comment
            if self.activity.titleLabel!.text!.hasSuffix("comment") {
                
            }
        
        
        }// end TAG
 
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////////////   R E L A T I O N S H I P S   R E Q U E S T S   ////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        // requested to follow you
        // asked to be friends
        if self.activity.titleLabel!.text! == "requested to follow you" || activity.titleLabel!.text! == "asked to be friends" {
            // Push VC
            let rRequestsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "relationshipsVC") as! RelationshipRequests
            self.delegate?.navigationController?.pushViewController(rRequestsVC, animated: true)
        }
        
        
        // is now friends with you
        if self.activity.titleLabel!.text! == "is now friends with you" {
            // Append user's object
            otherObject.append(self.userObject!)
            // Append user's username
            otherName.append(self.userObject!.value(forKey: "username") as! String)
            
            // Push VC
            let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
            self.delegate?.navigationController?.pushViewController(otherVC, animated: true)

        }


        // started following you
        if self.activity.titleLabel!.text! == "started following you" {
            // Append user's object
            otherObject.append(self.userObject!)
            // Append user's username
            otherName.append(self.userObject!.value(forKey: "username") as! String)
            
            // Push VC
            let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
            self.delegate?.navigationController?.pushViewController(otherVC, animated: true)

        }
        ////////// E N D -----> R E L A T I O N S H I P S
        
        
        

        // WRote in Your Space
        if self.activity.titleLabel!.text!.hasPrefix("wrote in") {
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
        
        
        // Content tap
        let activeTap = UITapGestureRecognizer(target: self, action: #selector(goContent))
        activeTap.numberOfTapsRequired = 1
        self.activity.isUserInteractionEnabled = true
        self.activity.addGestureRecognizer(activeTap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
