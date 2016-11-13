//
//  CommentsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/25/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel


class CommentsCell: UITableViewCell {
    
    // Variable to hold comment object
    var commentObject: PFObject?
    
    // Initialize parent VC
    var delegate: UIViewController?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var comment: KILabel!
    @IBOutlet weak var numberOfLikes: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    
    // Function to like comment
    func like(sender: UIButton) {
        // Disable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        // Determine title
        if self.likeButton.titleLabel!.text! == "liked" {
            // Unlike object
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.commentObject!.objectId!)
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
                                
                                
                                // Change button title and image
                                self.likeButton.setTitle("notLiked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
                                // Send Notification
                                NotificationCenter.default.post(name: commentNotification, object: nil)
                                
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
                                
                                
                                
                                // Delete from <Notifications>
                                let notifications = PFQuery(className: "Notifications")
                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                notifications.whereKey("forObjectId", equalTo: self.commentObject!.objectId!)
                                notifications.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            object.deleteInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Deleted notification: \(object)")

                                                    
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
            
            
        } else {
            // Like object
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = self.commentObject!.value(forKey: "byUser") as! PFUser
            likes["to"] = self.rpUsername.titleLabel!.text!
            likes["forObjectId"] = self.commentObject!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like: \(likes)")
                    
                    
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    
                    // Change button title and image
                    self.likeButton.setTitle("liked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
                    // Send Notification
                    NotificationCenter.default.post(name: commentNotification, object: nil)
                    
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
                    
                    
                    
                    // Send to <Notifications>
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = self.commentObject!.value(forKey: "byUser") as! PFUser
                    notifications["to"] = self.rpUsername.titleLabel!.text!
                    notifications["forObjectId"] = self.commentObject!.objectId!
                    notifications["type"]  = "like co"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Sent notification: \(notifications)")
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        
    }
    
    
    // Function to show likers
    func showLikes(sender: UIButton) {
        // Append object
        likeObject.append(self.commentObject!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Add comment like tap
        let commentLike = UITapGestureRecognizer(target: self, action: #selector(like))
        commentLike.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(commentLike)
        
        // Add number of likes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
