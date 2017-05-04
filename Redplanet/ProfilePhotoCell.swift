//
//  ProfilePhotoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/1/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage

class ProfilePhotoCell: UITableViewCell {
    
    // Initialie PFObject to bind data
    var postObject: PFObject?
    // StoryScrollCell's "parentDelegate"
    var superDelegate: UIViewController?
    // Array to hold likes
    var likes = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var largeProPic: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    // Function to go to user's profile
    func visitProfile(sender: UIButton) {
        otherObject.append(self.postObject?.value(forKey: "byUser") as! PFUser)
        otherName.append(self.postObject?.value(forKey: "username") as! String)
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // Function to like object
    func like(sender: UIButton) {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        if self.likeButton.image(for: .normal) == UIImage(named: "LikeFilled") {
            // Unlike object
            rpHelpers.unlikeObject(forObject: self.postObject!, activeButton: self.likeButton)
        } else if self.likeButton.image(for: .normal) == UIImage(named: "Like") {
            // Like object/send push notification
            rpHelpers.likeObject(forObject: self.postObject, notificationType: "like pp", activeButton: self.likeButton)
            rpHelpers.pushNotification(toUser: self.postObject!.value(forKey: "byUser") as! PFUser, activityType: "liked your Profile Photo")
        }
        // Reload data
        self.updateView(postObject: self.postObject!)
    }
    
    // Function to update view
    func updateView(postObject: PFObject?) {
        // (1) Get user's object
        if let user = postObject?.value(forKey: "byUser") as? PFUser {
            // Set username
            self.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
            // Set profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPHelpers
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                // MARK: - SDWebImage
                self.largeProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPHelpers
                self.largeProPic.makeCircular(forView: self.largeProPic, borderWidth: 3.50, borderColor: UIColor.darkGray)
            }
        }
        
        // (2) Set textPost
        if let textPost = postObject?.value(forKey: "textPost") as? String {
            self.textPost.text = textPost
        }
        
        // (3) Set time
        let from = postObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        self.time.text = "Updated their profile photo \(difference.getFullTime(difference: difference, date: from))"
        
        // (4) Get likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: self.postObject!)
        likes.includeKey("fromUser")
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                }
                
                // Set like button
                if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.likeButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
                } else {
                    self.likeButton.setImage(UIImage(named: "Like"), for: .normal)
                }
                
                // Count likes
                if self.likes.count == 0 {
                    self.numberOfLikes.setTitle("likes", for: .normal)
                } else if self.likes.count == 1 {
                    self.numberOfLikes.setTitle("1 like", for: .normal)
                } else {
                    self.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // (5) Count Comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
        comments.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                if count == 0 {
                    self.numberOfComments.setTitle("comments", for: .normal)
                } else if count == 1 {
                    self.numberOfComments.setTitle("1 comment", for: .normal)
                } else {
                    self.numberOfComments.setTitle("\(count) comments", for: .normal)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        // (6) Count Shares
        let shares = PFQuery(className: "Newsfeeds")
        shares.whereKey("contentType", equalTo: "sh")
        shares.whereKey("pointObject", equalTo: self.postObject!)
        shares.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                if count == 0 {
                    self.numberOfShares.setTitle("shares", for: .normal)
                } else if count == 1 {
                    self.numberOfShares.setTitle("1 share", for: .normal)
                } else {
                    self.numberOfShares.setTitle("\(count) shares", for: .normal)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add Profile Tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        // Add like tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
    }
    
}
