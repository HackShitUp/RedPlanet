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



class ActivityCell: UITableViewCell {
    
    
    // Instantiate parent view controller
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Inialize content object
    var contentObject: PFObject?

    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var activity: UILabel!
    @IBOutlet weak var time: UILabel!
    
    
    // Function to go to user's profile
    func goUser() {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append user's name
        otherName.append(self.rpUsername.titleLabel!.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    func viewPost() {
        DispatchQueue.main.async {
            // ---------------------------------------------------------------------------------------------------------------
            // -------------------- L I K E ----------------------------------------------------------------------------------
            // ---------------------------------------------------------------------------------------------------------------
            
            // (A) LIKED POST
            if self.activity.text!.hasPrefix("liked") {
                
                // I
                // TEXT POST
                if self.activity.text!.hasSuffix("Text Post") {
                    // Check TextPosts
                    let texts = PFQuery(className: "Newsfeeds")
                    texts.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                    texts.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("your Photo") {
                    // Check "Photos_Videos"
                    let photos = PFQuery(className: "Newsfeeds")
                    photos.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Profile Photo") {
                    let profilePhoto = PFQuery(className: "Newsfeeds")
                    profilePhoto.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // Append other object
                                otherObject.append(PFUser.current()!)
                                otherName.append(PFUser.current()!.username!)
                                // Push ProfilePhoto view controller
                                let proPicVC = self.delegate!.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                self.delegate!.navigationController!.pushViewController(proPicVC, animated: true)
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
                if self.activity.text!.hasSuffix("Shared Post") {
                    let share = PFQuery(className: "Newsfeeds")
                    share.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Space Post") {
                    let spacePost = PFQuery(className: "Newsfeeds")
                    spacePost.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Moment") {
                    let moment = PFQuery(className: "Newsfeeds")
                    moment.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // PHOTO
                                if object.value(forKey: "photoAsset") != nil {
                                    // Push to VC
                                    let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                    self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                                } else {
                                    // VIDEO
                                    // Push VC
                                    let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                                    self.delegate?.navigationController?.pushViewController(momentVideoVC, animated: true)
                                }
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
                if self.activity.text!.hasSuffix("Video") {
                    let video = PFQuery(className: "Newsfeeds")
                    video.includeKeys(["byUser", "toUser", "pointObject"])
                    video.whereKey("byUser", equalTo: PFUser.current()!)
                    video.whereKey("contentType", equalTo: "vi")
                    video.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                    video.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                            
                            for object in objects! {
                                // Append object
                                videoObject.append(object)
                                // Push VC
                                let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
            } // End Liked Content
            
            
            // (B) LIKED COMMENT
            if self.activity.text! == "liked your comment" {
                
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
                            
                            let commentId = object.value(forKey: "forObjectId") as! String
                            
                            // Find content
                            let newsfeeds = PFQuery(className: "Newsfeeds")
                            newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
                            newsfeeds.whereKey("objectId", equalTo: commentId)
                            newsfeeds.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    
                                    // PUSH VC
                                    for object in objects! {
                                        
                                        // I TEXT POST
                                        if object.value(forKey: "contentType") as! String  == "tp" {
                                            // Append object
                                            textPostObject.append(object)
                                            
                                            // Push VC
                                            let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                                            self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                                        }
                                        
                                        // II PHOTO
                                        if object.value(forKey: "contentType") as! String  == "ph" {
                                            // Append object
                                            photoAssetObject.append(object)
                                            
                                            // Push VC
                                            let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                                            self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                                        }
                                        
                                        // III SHARED POST
                                        if object.value(forKey: "contentType") as! String == "sh" {
                                            // Append object
                                            sharedObject.append(object)
                                            
                                            // Push VC
                                            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                                            self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                                        }
                                        
                                        // IV PROFILE PHOTO
                                        if object.value(forKey: "contentType") as! String == "pp" {
                                            // Append object
                                            proPicObject.append(object)
                                            
                                            // Push VC
                                            let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                            self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                                        }
                                        
                                        // V SPACE POST
                                        if object.value(forKey: "contentType") as! String == "sp" {
                                            // Append object
                                            spaceObject.append(object)
                                            
                                            // Append to otherObject
                                            otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                            // Append to otherName
                                            otherName.append(object.value(forKey: "toUsername") as! String)
                                            
                                            // Push VC
                                            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                                            self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                                        }
                                        
                                        // VI MOMENT
                                        if object.value(forKey: "contentType") as! String == "itm" {
                                            // Append object
                                            itmObject.append(object)
                                            
                                            // PHOTO
                                            if object.value(forKey: "photoAsset") != nil {
                                                // Push to VC
                                                let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                                self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                                            } else {
                                                // VIDEO
                                                // Push VC
                                                let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                                                self.delegate?.navigationController?.pushViewController(momentVideoVC, animated: true)
                                            }
                                        }
                                        
                                        // VII VIDEO
                                        if object.value(forKey: "contentType") as! String == "vi" {
                                            // Append object
                                            videoObject.append(object)
                                            
                                            // Push VC
                                            let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                            self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
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
                
            }
            
            
            
            
            // --------------------------------------------------------------------------------------------------------------
            // -------------------- C O M M E N T ---------------------------------------------------------------------------
            // --------------------------------------------------------------------------------------------------------------
            
            if self.activity.text! == "commented on your post" {
                
                // Disable buttons
                self.activity.isUserInteractionEnabled = false
                self.activity.isEnabled = false
                
                // Find Comment
                // Find in Newsfeed
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                            if object.value(forKey: "contentType") as! String  == "tp" {
                                // Append object
                                textPostObject.append(object)
                                
                                // Push VC
                                let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                                self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                            }
                            
                            // II PHOTO
                            if object.value(forKey: "contentType") as! String  == "ph" {
                                // Append object
                                photoAssetObject.append(object)
                                
                                // Push VC
                                let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                                self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                            }
                            
                            // III SHARED POST
                            if object.value(forKey: "contentType") as! String == "sh" {
                                // Append object
                                sharedObject.append(object)
                                // Push VC
                                let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                                self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                            }
                            
                            // IV PROFILE PHOTO
                            if object.value(forKey: "contentType") as! String == "pp" {
                                // Append object
                                proPicObject.append(object)
                                otherObject.append(object.object(forKey: "byUser") as! PFUser)
                                otherName.append((object.object(forKey: "byUser") as! PFUser).username!)
                                // Push VC
                                let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                            }
                            
                            // V SPACE POST
                            if object.value(forKey: "contentType") as! String == "sp" {
                                // Append object
                                spaceObject.append(object)
                                
                                // Append to otherObject
                                otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                // Append to otherName
                                otherName.append(object.value(forKey: "toUsername") as! String)
                                
                                // Push VC
                                let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                                self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                            }
                            
                            // VI MOMENT
                            if object.value(forKey: "contentType") as! String == "itm" {
                                // Append object
                                itmObject.append(object)
                                
                                // PHOTO
                                if object.value(forKey: "photoAsset") != nil {
                                    // Push to VC
                                    let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                    self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                                } else {
                                    // VIDEO
                                    // Push VC
                                    let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                                    self.delegate?.navigationController?.pushViewController(momentVideoVC, animated: true)
                                }
                            }
                            
                            // VII VIDEO
                            if object.value(forKey: "contentType") as! String == "vi" {
                                // Append object
                                videoObject.append(object)
                                
                                // Push VC
                                let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
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
            
            
            
            // ------------------------------------------------------------------------------------------------------------
            // -------------------- S H A R E D ---------------------------------------------------------------------------
            // ------------------------------------------------------------------------------------------------------------
            
            if self.activity.text!.hasPrefix("shared your") || self.activity.text!.hasPrefix("re-shared your") {
                
                // Disable buttons
                self.activity.isUserInteractionEnabled = false
                self.activity.isEnabled = false
                
                // (1) Text Post
                if self.activity.text!.hasSuffix("Text Post") {
                    // Find Text Post
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Photo") {
                    // Find Photo
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Profile Photo") {
                    // Find Profile Photo
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Shared Post") {
                    // Find Shared Post
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                if self.activity.text!.hasSuffix("Space Post") {
                    // Find Moment
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                                otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                // Append otherName
                                otherName.append(object.value(forKey: "toUsername") as! String)
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
                if self.activity.text!.hasSuffix("Moment") {
                    // Find Moment
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // PHOTO
                                if object.value(forKey: "photoAsset") != nil {
                                    // Push to VC
                                    let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                    self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                                } else {
                                    // VIDEO
                                    // Push VC
                                    let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                                    self.delegate?.navigationController?.pushViewController(momentVideoVC, animated: true)
                                }
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
                if self.activity.text!.hasSuffix("Video") {
                    // Find Moment
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
                    newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                    newsfeeds.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                            
                            for object in objects! {
                                // Append object
                                videoObject.append(object)
                                
                                // Push to VC
                                let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
            }
            
            
            
            
            
            // ----------------------------------------------------------------------------------------------------------------
            // -------------------- T A G -------------------------------------------------------------------------------------
            // ----------------------------------------------------------------------------------------------------------------
            
            if self.activity.text!.hasPrefix("tagged you in a") {
                // Disable buttons
                self.activity.isUserInteractionEnabled = false
                self.activity.isEnabled = false
                
                
                // I Text Post
                if self.activity.text!.hasSuffix("Text Post"){
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                
                // II Photo
                if self.activity.text!.hasSuffix("Photo") {
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // Push VC
                                let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                                self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // III Profile Photo
                if self.activity.text!.hasSuffix("Profile Photo") {
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // Append to otherObject
                                otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                // Append to otherName
                                otherName.append(object.value(forKey: "toUsername") as! String)
                                // Push VC
                                let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // IV Space Post
                if self.activity.text!.hasSuffix("Space Post") {
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
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
                                // Append to otherObject
                                otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                // Append to otherName
                                otherName.append(object.value(forKey: "toUsername") as! String)
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
                
                
                // V VIDEO
                if self.activity.text!.hasSuffix("Video") {
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
                    newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                    newsfeeds.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                            
                            for object in objects! {
                                // Append object
                                videoObject.append(object)
                                // Push VC
                                let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // VI Comment
                if self.activity.text!.hasSuffix("comment") {
                    // Find in Newsfeeds
                    let newsfeeds = PFQuery(className: "Newsfeeds")
                    newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
                    newsfeeds.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                    newsfeeds.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            // Find Content
                            for object in objects! {
                                // TEXT POST
                                if object.value(forKey: "contentType") as! String == "tp" {
                                    // Append object
                                    textPostObject.append(object)
                                    // Push VC
                                    let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                                    self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                                } else if object.value(forKey: "contentType") as! String == "ph" {
                                    // PHOTO
                                    // Append object
                                    photoAssetObject.append(object)
                                    // Push VC
                                    let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                                    self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                                } else if object.value(forKey: "contentType") as! String == "sh" {
                                    // SHARED POST
                                    // Append object
                                    sharedObject.append(object)
                                    // Push VC
                                    let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                                    self.delegate?.navigationController?.pushViewController(sharedPostVC, animated: true)
                                } else if object.value(forKey: "contentType") as! String == "pp" {
                                    // PROFILE PHOTO
                                    // Append object
                                    proPicObject.append(object)
                                    // Push VC
                                    let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                                    self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                                } else if object.value(forKey: "contentType") as! String == "sp" {
                                    // SPACE POST
                                    // Append object
                                    spaceObject.append(object)
                                    // otherUser
                                    otherObject.append(object.object(forKey: "toUser") as! PFUser)
                                    otherName.append(object.value(forKey: "toUsername") as! String)
                                    // Push VC
                                    let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                                    self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                                } else if object.value(forKey: "contentType") as! String == "itm" {
                                    // MOMENT
                                    // Append object
                                    itmObject.append(object)
                                    
                                    // PHOTO MOMENT
                                    if object.value(forKey: "photoAsset") != nil {
                                        let itmVC = self.delegate?.storyboard!.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                                        self.delegate?.navigationController!.pushViewController(itmVC, animated: true)
                                    } else {
                                        // VIDEO MOMENT
                                        let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                                        self.delegate?.navigationController?.pushViewController(momentVideoVC, animated: true)
                                    }
                                    
                                } else if object.value(forKey: "contentType") as! String == "vi" {
                                    // VIDEO
                                    // Append object
                                    videoObject.append(object)
                                    // Push VC
                                    let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                                    self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
                                }
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                
            }
            
            
            
            // ---------------------------------------------------------------------------------------------------------------
            // -------------------- R E L A T I O N S H I P S ----------------------------------------------------------------
            // ---------------------------------------------------------------------------------------------------------------
            
            // requested to follow you
            if self.activity.text! == "requested to follow you" {
                // Push VC
                let rRequestsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followRequestsVC") as! FollowRequests
                self.delegate?.navigationController?.pushViewController(rRequestsVC, animated: true)
            }
            
            
            // started following you
            if self.activity.text! == "started following you" {
                // Append user's object
                otherObject.append(self.userObject!)
                // Append user's username
                otherName.append(self.userObject!.value(forKey: "username") as! String)
                
                // Push VC
                let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                self.delegate?.navigationController?.pushViewController(otherVC, animated: true)
            }
            
            
            
            
            // --------------------------------------------------------------------------------------------------------------
            // -------------------- S P A C E -------------------------------------------------------------------------------
            // --------------------------------------------------------------------------------------------------------------
            if self.activity.text!.hasPrefix("wrote on your Space") {
                // Space Post
                
                let spacePost = PFQuery(className: "Newsfeeds")
                spacePost.includeKeys(["byUser", "toUser", "pointObject"])
                spacePost.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                spacePost.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            // Append object
                            spaceObject.append(object)
                            
                            // Append to otherObject
                            otherObject.append(PFUser.current()!)
                            
                            // Append to otherName
                            otherName.append(PFUser.current()!.username!)
                            
                            // Push VC
                            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                            self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add username tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        
        // Add profile photo tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // Add viewPost tap
        let postTap = UITapGestureRecognizer(target: self, action: #selector(viewPost))
        postTap.numberOfTapsRequired = 1
        self.activity.isUserInteractionEnabled = true
        self.activity.addGestureRecognizer(postTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
