
//
//  TextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage

class TextPostCell: UITableViewCell {
    
    
    var postObject: PFObject?
    
    var likes = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    
    // Function to like object
    func like(sender: UIButton) {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        if self.likeButton.image(for: .normal) == UIImage(named: "LikeFilled") {
            // Unlike object
            rpHelpers.unlikeObject(forObject: self.postObject!, activeButton: self.likeButton)
        } else if self.likeButton.image(for: .normal) == UIImage(named: "Like") {
            // Like object/send push notification
            rpHelpers.likeObject(forObject: self.postObject, notificationType: "like tp", activeButton: self.likeButton)
            rpHelpers.pushNotification(toUser: self.postObject!.value(forKey: "byUser") as! PFUser, activityType: "liked your Text Post")
        }
    }
    
    
    // Function to bind data
    func updateView(postObject: PFObject?) {
        // (1) Get user's object
        if let user = postObject!.value(forKey: "byUser") as? PFUser {
            // Get realNameOfUser
            self.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
            // Set profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPExtensions
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            }
        }
        
        // (2) Set text post
        self.textPost.text = (self.postObject!.value(forKey: "textPost") as! String)
        
        // (3) Set time
        let from = self.postObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: postObject!.objectId!)
        likes.includeKeys(["fromUser", "toUser"])
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                }
                
                // Set button
                if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.likeButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
                } else {
                    self.likeButton.setImage(UIImage(named: "Like"), for: .normal)
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
        // Initialization code
        
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
