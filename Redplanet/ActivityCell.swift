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
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var activity: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // Function to go to user's profile
    func goUser() {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append user's name
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    func viewPost() {
        DispatchQueue.main.async {
            // -------------------- L I K E ----------------------------------------------------------------------------------
            // (A) LIKED POST
            if self.activity.text!.hasPrefix("liked") {

                // I: TEXT POST
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }

                // II: PHOTO
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // III: PROFILE PHOTO
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }

                // IV: SPACE POST
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // V: MOMENT
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // VI: VIDEO
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                        // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                        let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                        storyVC.chatOrStory = "Story"
                                        storyVC.singleStory = object
                                        // MARK: - RPPopUpVC
                                        let rpPopUpVC = RPPopUpVC()
                                        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
            // -------------------- C O M M E N T ---------------------------------------------------------------------------
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
                            // Create storyVC, distinguish chatOrStory, and initialize PFObject
                            let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                            storyVC.chatOrStory = "Story"
                            storyVC.singleStory = object
                            // MARK: - RPPopUpVC
                            let rpPopUpVC = RPPopUpVC()
                            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                            self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                    }
                })
            }
            // -------------------- S H A R E D ---------------------------------------------------------------------------
            if self.activity.text!.hasPrefix("shared your") {
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
                
                // (4) Space Post
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // (5) Moment
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // Re-enable buttons
                            self.activity.isUserInteractionEnabled = true
                            self.activity.isEnabled = true
                        }
                    })
                }
                
                // (6) VIDEO
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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

            // -------------------- T A G -------------------------------------------------------------------------------------
            
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
                                // Create storyVC, distinguish chatOrStory, and initialize PFObject
                                let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                                storyVC.chatOrStory = "Story"
                                storyVC.singleStory = object
                                // MARK: - RPPopUpVC
                                let rpPopUpVC = RPPopUpVC()
                                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                                self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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

            // -------------------- R E L A T I O N S H I P S ----------------------------------------------------------------
            
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
            
            // -------------------- S P A C E -------------------------------------------------------------------------------
            if self.activity.text!.hasPrefix("wrote on your Space") {
                // Space Post
                
                let spacePost = PFQuery(className: "Newsfeeds")
                spacePost.includeKeys(["byUser", "toUser", "pointObject"])
                spacePost.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                spacePost.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            // Create storyVC, distinguish chatOrStory, and initialize PFObject
                            let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                            storyVC.chatOrStory = "Story"
                            storyVC.singleStory = object
                            // MARK: - RPPopUpVC
                            let rpPopUpVC = RPPopUpVC()
                            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                            self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
        
        self.activity.sizeToFit()
        self.activity.numberOfLines = 0
    }
}
