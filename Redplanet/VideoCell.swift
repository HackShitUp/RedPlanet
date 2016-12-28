//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/6/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import KILabel
import OneSignal

import SimpleAlert

class VideoCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Initialize content object
    var contentObject: PFObject?
    
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var videoPreview: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    
    @IBAction func showLikes(_ sender: Any) {
        // Append object
        likeObject.append(self.contentObject!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)

    }
    
    @IBOutlet weak var numberOfComments: UIButton!
    @IBAction func showComments(_ sender: Any) {
        // Append object
        commentsObject.append(self.contentObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)

    }
    
    @IBOutlet weak var numberOfShares: UIButton!
    @IBAction func showShares(_ sender: Any) {
        // Append object
        shareObject.append(videoObject.last!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(sharesVC, animated: true)
    }
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBAction func like(_ sender: Any) {
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: videoObject.last!.objectId!)
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
                                NotificationCenter.default.post(name: videoNotification, object: nil)
                                
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
                                notifications.whereKey("forObjectId", equalTo: videoObject.last!.objectId!)
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
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            // LIKE
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = videoObject.last!.value(forKey: "byUser") as! PFUser
            likes["to"] = self.rpUsername.text!
            likes["forObjectId"] = videoObject.last!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like \(likes)")
                    
                    
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    
                    // Change button title and image
                    self.likeButton.setTitle("liked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
                    // Send Notification
                    NotificationCenter.default.post(name: videoNotification, object: nil)
                    
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
                    notifications["toUser"] = videoObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["forObjectId"] = videoObject.last!.objectId!
                    notifications["type"] = "like vi"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.userObject!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Video"],
                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"]
                                    ]
                                )
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
    
    @IBAction func comment(_ sender: Any) {
        // Append object
        commentsObject.append(self.contentObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }

    
    @IBAction func share(_ sender: Any) {
        
        // MARK: - SimpleAlert
        let options = AlertController(title: "Share To",
                                        message: nil,
                                        style: .alert)
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.textColor = UIColor.black
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }

        
        
        // EVERYONE
        let publicShare = AlertAction(title: "All Friends",
                                        style: .default,
                                        handler: { (AlertAction) in

                                            
                                            // Share to public ***FRIENDS ONLY***
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
                                            newsfeeds["textPost"] = "shared @\(self.rpUsername.text!)'s Video: \(self.caption.text!)"
                                            newsfeeds["pointObject"] = videoObject.last!
                                            newsfeeds["videoAsset"] = videoObject.last!.value(forKey: "videoAsset") as! PFFile
                                            newsfeeds["contentType"] = "sh"
                                            newsfeeds.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if error == nil {
                                                    print("Successfully shared text post: \(newsfeeds)")
                                                    
                                                    
                                                    // Send Notification
                                                    let notifications = PFObject(className: "Notifications")
                                                    notifications["fromUser"] = PFUser.current()!
                                                    notifications["from"] = PFUser.current()!.username!
                                                    notifications["toUser"] = videoObject.last!.value(forKey: "byUser") as! PFUser
                                                    notifications["to"] = self.rpUsername.text!
                                                    notifications["type"] = "share vi"
                                                    notifications["forObjectId"] = videoObject.last!.objectId!
                                                    notifications.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Sent notification: \(notifications)")
                                                            
                                                            
                                                            // Handle optional chaining
                                                            if self.userObject!.value(forKey: "apnsId") != nil {
                                                                // MARK: - OneSignal
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!.uppercased()) shared your Video"],
                                                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"]
                                                                    ]
                                                                )
                                                            }
                                                            
                                                            
                                                            
                                                            
                                                            // Send notification
                                                            NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                            
                                                            // Show alert
                                                            let alert = UIAlertController(title: "Shared With Friends",
                                                                                          message: "Successfully shared \(self.rpUsername.text!)'s Video.",
                                                                preferredStyle: .alert)
                                                            
                                                            let ok = UIAlertAction(title: "ok",
                                                                                   style: .default,
                                                                                   handler: { (AlertAction) in
                                                                                    // Pop view controller
                                                                                    _ = self.delegate?.navigationController?.popViewController(animated: true)
                                                            })
                                                            
                                                            alert.addAction(ok)
                                                            alert.view.tintColor = UIColor.black
                                                            self.delegate?.present(alert, animated: true, completion: nil)
                                                            
                                                            
                                                        } else {
                                                            print(error?.localizedDescription as Any)
                                                        }
                                                    })
                                                    
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                            
                                            
        })
        
        // ONE FRIEND
        let privateShare = AlertAction(title: "One Friend",
                                         style: .default,
                                         handler: { (AlertAction) in
                                            
                                            // Append to contentObject
                                            shareObject.append(self.contentObject!)
                                            
                                            // Share to chats
                                            let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                            self.delegate?.navigationController?.pushViewController(shareToVC, animated: true)
        })
        
        let cancel = AlertAction(title: "Cancel",
                                   style: .destructive,
                                   handler: nil)
        
        options.addAction(publicShare)
        options.addAction(privateShare)
        options.addAction(cancel)
        options.view.tintColor = UIColor.black
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    // Function to present video
    func playVideo() {

        // Fetch video data
        if let video = self.contentObject!.value(forKey: "videoAsset") as? PFFile {
            // Traverse video url
            let videoUrl = NSURL(string: video.url!)
            // MARK: - Periscope Video View Controller
            let videoViewController = VideoViewController(videoURL: videoUrl as! URL)
            self.delegate?.present(videoViewController, animated: true, completion: nil)
        }
    }
    
    
    // Function to go to OtherUser
    func goOther() {
        
        // Append user's object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!.lowercased())
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add tap for playing video
        let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
        playTap.numberOfTapsRequired = 1
        self.videoPreview.isUserInteractionEnabled = true
        self.videoPreview.addGestureRecognizer(playTap)
        
        // Add user's profile photo tap to go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        userTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(userTap)
        
        // Add username tap to go to user's profile
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        usernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(usernameTap)
        
        // Handle @username tap
        caption.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: mention.lowercased())
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        
                        // Append user's username
                        otherName.append(mention)
                        // Append user object
                        otherObject.append(object)
                        
                        // Push VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        
        // Handle #object tap
        caption.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        
        // Handle http: tap
        caption.urlLinkTapHandler = { label, handle, range in
            // Open url
            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
            self.delegate?.present(modalWeb, animated: true, completion: nil)
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
