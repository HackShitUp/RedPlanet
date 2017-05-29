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
    
    // FUNCTION - Navigate to user's profile
    func goUser() {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append user's name
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    // FUNCTION - Show single story
    func showStory(withObject: PFObject?) {
        // Create storyVC, distinguish chatOrStory, and initialize PFObject
        let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
        storyVC.storyObject = withObject!
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
    }
    
    // FUNCTION - Manage which single story to show
    func viewPost() {
        
        DispatchQueue.main.async(execute: {
            // -------------------- L I K E ----------------------------------------------------------------------------------
            // -------------------- T A G ------------------------------------------------------------------------------------
            // -------------------- S P A C E --------------------------------------------------------------------------------
            // -------------------- C O M M E N T ----------------------------------------------------------------------------
            // -------------------- S C R E E N S H O T ----------------------------------------------------------------------
            if self.activity.text!.hasPrefix("liked") || self.activity.text!.hasPrefix("tagged you in a") || self.activity.text!.hasPrefix("wrote on your Space") || self.activity.text! == "commented on your post" || self.activity.text!.hasPrefix("screenshot your post") {
                // TEXT POST, PHOTO, PROFILE PHOTO, VIDEO, SPACE POST, or MOMENT
                let post = PFQuery(className: "Posts")
                post.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                post.includeKeys(["byUser", "toUser"])
                post.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        for object in objects! {
                            // Ephemeral and Saved Content Configuration
                            let components: NSCalendar.Unit = .hour
                            let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                            // Check if content has not expired OR if it's saved
                            if difference.hour! < 24 || object.value(forKey: "saved") as! Bool == true {
                                // Show Story
                                self.showStory(withObject: object)
                            } else {
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showAction(withTitle: "This post expired, and it wasn't saved...")
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

            // ----------L I K E D -----  C O M M E N T ------------------------------------------------------------------
            if self.activity.text! == "liked your comment" {
                // Disable buttons
                self.activity.isUserInteractionEnabled = false
                self.activity.isEnabled = false
                
                // Find Comments
                let comments = PFQuery(className: "Comments")
                comments.whereKey("objectId", equalTo: self.contentObject!.value(forKey: "forObjectId") as! String)
                comments.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        
                        for object in objects! {
                            let commentId = object.value(forKey: "forObjectId") as! String
                            // Find content
                            let postsClass = PFQuery(className: "Posts")
                            postsClass.whereKey("objectId", equalTo: commentId)
                            postsClass.includeKeys(["byUser", "toUser"])
                            postsClass.findObjectsInBackground(block: {
                                (objects: [PFObject]?, error: Error?) in
                                if error == nil {
                                    // PUSH VC
                                    for object in objects! {
                                        // Ephemeral and Saved Content Configuration
                                        let components: NSCalendar.Unit = .hour
                                        let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                                        // Check if content has not expired OR if it's saved
                                        if difference.hour! < 24 || object.value(forKey: "saved") as! Bool == true {
                                            // Show Story
                                            self.showStory(withObject: object)
                                        } else {
                                            // MARK: - RPHelpers
                                            let rpHelpers = RPHelpers()
                                            rpHelpers.showAction(withTitle: "This post expired, and it wasn't saved...")
                                        }
                                    }
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - RPHelpers
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.showError(withTitle: "Couldn't find post...")
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Re-enable buttons
                        self.activity.isUserInteractionEnabled = true
                        self.activity.isEnabled = true
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error")
                    }
                })
            }

            
            
            // -------------------- R E L A T I O N S H I P S ----------------------------------------------------------------
            // REQUESTED TO FOLLOW YOU
            if self.activity.text! == "requested to follow you" {
                // Push VC
                let rRequestsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followRequestsVC") as! FollowRequests
                self.delegate?.navigationController?.pushViewController(rRequestsVC, animated: true)
            }
            // STARTED FOLLOWING YOU
            if self.activity.text! == "started following you" {
                // Append user's object
                otherObject.append(self.userObject!)
                // Append user's username
                otherName.append(self.userObject!.value(forKey: "username") as! String)
                
                // Push VC
                let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                self.delegate?.navigationController?.pushViewController(otherVC, animated: true)
            }
        })
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
        // Configure UILabel
        self.activity.sizeToFit()
        self.activity.numberOfLines = 0
    }
}
