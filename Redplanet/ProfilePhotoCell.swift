//
//  ProfilePhotoCell.swift
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

import KILabel

class ProfilePhotoCell: UITableViewCell {
    
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    
    
    // Like function button
    func likePP(sender: UIButton) {
        
        // Disable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        
        // Like or unlike depending on state
        if self.likeButton.title(for: .normal) == "liked" {
            // Unlike Profile Photo
            let likes = PFQuery(className: "Likes")
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.whereKey("forObjectId", equalTo: proPicObject.last!.objectId!)
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if error == nil {
                                print("Successfully deleted like: \(object)")
                                
                                // Re-enable buttons
                                self.likeButton.isUserInteractionEnabled = true
                                self.likeButton.isEnabled = true
                                
                                // Change button title and image
                                self.likeButton.setTitle("notLiked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
                                // Send notification
                                NotificationCenter.default.post(name: profileNotification, object: nil)
                                
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
                                
                                // Save to notification
                                let notifications = PFObject(className: "Notifications")
                                notifications["fromUser"] = PFUser.current()!
                                notifications["from"] = PFUser.current()!.username!
                                notifications["to"] = self.rpUsername.text!
                                notifications["toUser"] = otherObject.last!
                                notifications["forObjectId"] = proPicObject.last!.objectId!
                                notifications["type"] = "like pp"
                                notifications.saveInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        print("Successfully saved notificaiton: \(notifications)")
                                        
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
            // Like Profile Photo
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = otherObject.last!
            likes["to"] = otherName.last!
            likes["forObjectId"] = proPicObject.last!.objectId!
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
                    NotificationCenter.default.post(name: profileNotification, object: nil)
                    
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


                    // Delete "Notifications"
                    let notifications = PFQuery(className: "Notifications")
                    notifications.whereKey("forObjectId", equalTo: proPicObject.last!.objectId!)
                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                    notifications.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object.deleteInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        print("Successfully deleted notification: \(object)")
                                        
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
    }
    
    
    // Function to load comments
    func comment() {
        // Append object
        commentsObject.append(proPicObject.last!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    
    // Function to show sharers
    func sharers() {
        // Append object
        shareObject.append(proPicObject.last!)
        
        // Push VC
        let shareVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(shareVC, animated: true)
    }
    

    // Function to share 
    func shareContent() {
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        // TODO::
        // For now, share only to one friend
        // Sharing this publicly causes problem because if it were shared in the newsfeeds,
        // then you'd have to run through 2 data sets when viewing the content
        let share = UIAlertAction(title: "Share With Friend",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
                                            
                                            // Share privately only
                                            // Append to contentObject
                                            shareObject.append(proPicObject.last!)
                                            
                                            // Share to chats
                                            let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                            self.delegate?.navigationController?.pushViewController(shareToVC, animated: true)
                                            
        })

        
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        options.addAction(share)
        options.addAction(cancel)
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    
    // Function to show number of likes
    func showLikes() {
        // Append object
        likeObject.append(proPicObject.last!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()


        // (1) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)
        
        // (2) Like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(likePP))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (3) Comment button tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        commentTap.numberOfTapsRequired = 1
        self.commentButton.isUserInteractionEnabled = true
        self.commentButton.addGestureRecognizer(commentTap)
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (4) Number of likes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (5) Share options
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareContent))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
