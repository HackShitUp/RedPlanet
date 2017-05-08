
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
    
    // Initialized PFObject
    var postObject: PFObject?
    // Initialized parent UIViewController
    var superDelegate: UIViewController?
    // Array to hold likes
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

    // More button function
    func doMore(sender: UIButton) {
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: nil)
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        
        // (1) Views
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            
        })
        
        // (2) Delete
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Deleting Text Post...")
            // Delete from Newsfeeds
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
            newsfeeds.whereKey("objectId", equalTo: self.postObject!)
            newsfeeds.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground()
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Deleted Text Post")
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Failed to Deleted Text Post")
                }
            })
        })
        
        // (3) Report
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> Void in
            // Dismiss
            dialog.dismiss()
        })

        // Show options depending on user
        if (self.postObject!.value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(delete)
            dialogController.show(in: self.superDelegate!)
        } else {
            dialogController.addAction(report)
            dialogController.show(in: self.superDelegate!)
        }
    }
    
    // Function to go to user's profile
    func visitProfile(sender: UIButton) {
        otherObject.append(self.postObject?.value(forKey: "byUser") as! PFUser)
        otherName.append(self.postObject?.value(forKey: "username") as! String)
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // Function to like object
    func like() {
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
        
        DispatchQueue.main.async {
            // Reload data
//            self.updateView(postObject: self.postObject!)
            // (4) Set likes
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.likes.removeAll(keepingCapacity: false)
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
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
            })
        }
    }
    
    // Function to show likers
    func likers(sender: UIButton) {
//        likeObject.append(self.postObject!)
//        let likersVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
//        self.superDelegate?.navigationController?.pushViewController(likersVC, animated: true)
        reactionObject.append(self.postObject!)
        let reactionsVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "reactionsVC") as! Reactions
        self.superDelegate?.navigationController?.pushViewController(reactionsVC, animated: true)
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
        likes.includeKey("fromUser")
        likes.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                }
                
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
        })
        
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
        // Add more button tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        // Add numberOfLikestap
        let numberLikesTap = UITapGestureRecognizer(target: self, action: #selector(likers))
        numberLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numberLikesTap)
    }
    
}
