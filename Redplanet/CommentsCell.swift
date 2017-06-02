//
//  CommentsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/7/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import Parse
import ParseUI
import Bolts
import KILabel

/*
 UITableViewCell class that displays the comments of a post.
 The comments for a given post, and its data are binded in this class, instead of its parent class, including any actions
 possible (ie: delete, reply, like, and reporting a comment).
 Parent class is fixed to "Reactions.swift."
 */

class CommentsCell: UITableViewCell {
    
    // Initialize parent UIViewController
    var delegate: UIViewController?
    // Initialize PFObject
    var commentObject: PFObject?
    
    // Array to hold likers for each comment
    var likers = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var comment: KILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfLikes: UIButton!
    
    // FUNCTION - Navigate to user's profile
    func showProfile(sender: AnyObject) {
        otherObject.append(self.commentObject!.object(forKey: "byUser") as! PFUser)
        otherName.append(self.rpUsername.text!)
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Like/Unlike Comment
    func likeComment(sender: AnyObject) {
        // UNLIKE POST and reload likes
        if self.likeButton.image(for: .normal) == UIImage(named: "HeartFilled") {
            // Disable button
            likeButton.isUserInteractionEnabled = false
            // Query PFObject
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.commentObject!.objectId!)
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground()
                        
                        // Re-enable button
                        self.likeButton.isUserInteractionEnabled = true
                        // Set Button Image
                        self.likeButton.setImage(UIImage(named: "Like"), for: .normal)
                        // Animate like button
                        UIView.animate(withDuration: 0.6 ,
                                       animations: { self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                                       completion: { finish in
                                        UIView.animate(withDuration: 0.5) {
                                            self.likeButton.transform = CGAffineTransform.identity
                                        }
                        })
                        
                        // Remove from Notifications
                        let notifications = PFQuery(className: "Notifications")
                        notifications.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
                        notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                        notifications.whereKey("type", equalTo: "like co")
                        notifications.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                for object in objects! {
                                    object.deleteInBackground()
                                    // Send to reactNotifications to reload data and count likes
                                    NotificationCenter.default.post(name: reactNotification, object: nil)
                                }
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showError(withTitle: "Network Error")
                            }
                        })
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })

        } else {
            // LIKE POST and reload likes
            // Disable button
            likeButton.isUserInteractionEnabled = false
            // SAVE Likes
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = commentObject!.object(forKey: "byUser") as! PFUser
            likes["to"] = (commentObject!.object(forKey: "byUser") as! PFUser).username!
            likes["forObjectId"] = commentObject!.objectId!
            likes.saveInBackground(block: { (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved object: \(likes)")
                    
                    // Re-enable button
                    self.likeButton.isUserInteractionEnabled = true
                    // Set Button Image
                    self.likeButton.setImage(UIImage(named: "HeartFilled"), for: .normal)
                    // Animate like button
                    UIView.animate(withDuration: 0.6 ,
                                   animations: { self.likeButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.5) {
                                        self.likeButton.transform = CGAffineTransform.identity
                                    }
                    })
                    
                    // Send to reactNotifications to reload data and count likes
                    NotificationCenter.default.post(name: reactNotification, object: nil)
                    
                    // SAVE to Notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = self.commentObject!.object(forKey: "byUser") as! PFUser
                    notifications["to"] = (self.commentObject!.object(forKey: "byUser") as! PFUser).username!
                    notifications["forObjectId"] = self.commentObject!.objectId!
                    notifications["type"] = "like co"
                    notifications.saveInBackground()
                    
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.pushNotification(toUser: self.commentObject!.object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your comment")
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })

        }
        
    }
    
    // FUNCTION - Get likes for comment
    func countLikes(forObject: PFObject) {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: forObject.objectId!)
        likes.includeKey("fromUser")
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.likers.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likers.append(object)
                }
                
                // Set numberOfLikes
                if self.likers.count == 0 {
                    self.numberOfLikes.isHidden = true
                } else {
                    self.numberOfLikes.isHidden = false
                    self.numberOfLikes.setTitle("\(self.likers.count)", for: .normal)
                    // Add tap method to numberOfLikes
                    self.numberOfLikes.addTarget(self, action: #selector(self.showLikes), for: .touchUpInside)
                }
                
                // Set likeButton image
                if self.likers.map({ $0.object(forKey: "fromUser") as! PFUser}).contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.likeButton.setImage(UIImage(named: "HeartFilled"), for: .normal)
                } else {
                    self.likeButton.setImage(UIImage(named: "Like"), for: .normal)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject) {
        // Get and set user's data
        if let user = withObject.object(forKey: "byUser") as? PFUser {
            // (1) Set rpUsername
            self.rpUsername.text = (user.value(forKey: "username") as! String)
            // (2) Get and set userProfilePicture
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setIndicatorStyle(.gray)
                self.rpUserProPic.sd_showActivityIndicatorView()
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPExtensions
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            }
        }
        
        // (2) Set time
        let from = withObject.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (3) Set comment
        self.comment.text = (withObject.value(forKey: "commentOfContent") as! String)
    }
    
    // FUNCTION - Show likes for comments
    func showLikes(sender: AnyObject) {
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likesVC") as! Likes
        likesVC.fetchObject = self.commentObject
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // rpUserProPic tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProfile))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        // rpUsername tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(showProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        
        // Add tap method to like button
        self.numberOfLikes.isHidden = true
        self.likeButton.addTarget(self, action: #selector(likeComment), for: .touchUpInside)
        
        
        // MARK: - KILabel; @, #, and https://
        // @@@
        comment.userHandleLinkTapHandler = { label, handle, range in
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: String(handle.characters.dropFirst()).lowercased())
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append data
                        otherName.append(String(handle.characters.dropFirst()).lowercased())
                        otherObject.append(object)
                        // Push VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        comment.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.delegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
        // https://
        comment.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
