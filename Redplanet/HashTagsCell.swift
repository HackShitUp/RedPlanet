//
//  HashTagsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/13/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal


class HashTagsCell: UITableViewCell {
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Set contentObject
    var contentObject: PFObject?
    
    // Initizlize Parent VC
    var delegate: UIViewController?
    

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var photoAsset: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!

    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBAction func comment(_ sender: Any) {
        // Append object
        commentsObject.append(self.contentObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    // Function to go to user's profile
    func goUser(sender: UIButton) {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!.lowercased())
        
        // Push VC
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    
    // Function to share
    func shareOptions() {
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        // TODO:
        // Add option to share to followers
        
        let publicShare = UIAlertAction(title: "Everyone",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
                                            
                                            // Share to public ***FRIENDS ONLY***
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
                                            newsfeeds["textPost"] = "shared @\(self.rpUsername.text!)'s Post: \(self.textPost.text!)"
                                            newsfeeds["pointObject"] = self.contentObject!
                                            newsfeeds["contentType"] = "sh"
                                            newsfeeds["saved"] = false
                                            newsfeeds.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if error == nil {
                                                    print("Successfully shared text post: \(newsfeeds)")
                                                    
                                                    
                                                    // Send Notification
                                                    let notifications = PFObject(className: "Notifications")
                                                    notifications["fromUser"] = PFUser.current()!
                                                    notifications["from"] = PFUser.current()!.username!
                                                    notifications["toUser"] = self.contentObject!.value(forKey: "byUser") as! PFUser
                                                    notifications["to"] = self.rpUsername.text!
                                                    if self.contentObject!.value(forKey: "contentType") as! String == "ph" {
                                                        notifications["type"] = "share ph"
                                                    } else if self.contentObject!.value(forKey: "contentType") as! String == "vi" {
                                                        notifications["type"] = "share vi"
                                                    } else {
                                                        notifications["type"] = "share tp"
                                                    }
                                                    notifications["forObjectId"] = self.contentObject!.objectId!
                                                    notifications.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Sent notification: \(notifications)")
                                                            
                                                            
                                                            // Handle optional chaining
                                                            if self.userObject!.value(forKey: "apnsId") != nil {
                                                                if self.contentObject!.value(forKey: "contentType") as! String == "ph" {
                                                                    // MARK: - OneSignal
                                                                    // Send push notification
                                                                    OneSignal.postNotification(
                                                                        ["contents":
                                                                            ["en": "\(PFUser.current()!.username!.uppercased()) shared your Photo"],
                                                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                                                         "ios_badgeType": "Increase",
                                                                         "ios_badgeCount": 1
                                                                        ]
                                                                    )
                                                                } else if self.contentObject!.value(forKey: "contentType") as! String == "vi" {
                                                                    
                                                                    // MARK: - OneSignal
                                                                    // Send push notification
                                                                    OneSignal.postNotification(
                                                                        ["contents":
                                                                            ["en": "\(PFUser.current()!.username!.uppercased()) shared your Video"],
                                                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                                                         "ios_badgeType": "Increase",
                                                                         "ios_badgeCount": 1
                                                                        ]
                                                                    )
                                                                    
                                                                } else {
                                                                    // MARK: - OneSignal
                                                                    // Send push notification
                                                                    OneSignal.postNotification(
                                                                        ["contents":
                                                                            ["en": "\(PFUser.current()!.username!.uppercased()) shared your Text Post"],
                                                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                                                         "ios_badgeType": "Increase",
                                                                         "ios_badgeCount": 1
                                                                        ]
                                                                    )
                                                                }
                                                            }
                                                            
                                                            
                                                            
                                                            
                                                            // Send notification
                                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                                            
                                                            // Show alert
                                                            let alert = UIAlertController(title: "Shared With Friends",
                                                                                          message: "Successfully shared \(self.rpUsername.text!.uppercased())'s Post.",
                                                                preferredStyle: .alert)
                                                            
                                                            let ok = UIAlertAction(title: "ok",
                                                                                   style: .default,
                                                                                   handler: {(alertAction: UIAlertAction!) in
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
        
        let privateShare = UIAlertAction(title: "One Person",
                                         style: .default,
                                         handler: {(alertAction: UIAlertAction!) in
                                            
                                            // Append to contentObject
                                            shareObject.append(self.contentObject!)
                                            
                                            // Share to chats
                                            let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                            self.delegate?.navigationController?.pushViewController(shareToVC, animated: true)
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        options.addAction(publicShare)
        options.addAction(privateShare)
        options.addAction(cancel)
        options.view.tintColor = UIColor.black
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    
    // Function to like content
    func like(sender: UIButton) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.contentObject!.objectId!)
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
                                NotificationCenter.default.post(name: hashtagNotification, object: nil)
                                
                                
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
                                notifications.whereKey("forObjectId", equalTo: self.contentObject!.objectId!)
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
            likes["toUser"] = self.userObject!
            likes["to"] = self.rpUsername.text!
            likes["forObjectId"] = self.contentObject!.objectId!
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
                    NotificationCenter.default.post(name: hashtagNotification, object: nil)
                    
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
                    notifications["toUser"] = self.userObject!
                    notifications["forObjectId"] = self.contentObject!.objectId!
                    notifications["type"] = "like tp"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.userObject!.value(forKey: "apnsId") != nil {
                                if self.contentObject!.value(forKey: "contentType") as! String == "ph" {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Photo"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else if self.contentObject!.value(forKey: "contentType") as! String == "vi" {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Video"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else {
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) liked your Text Post"],
                                         "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
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
    
    
    // Function to show number of shares
    func showShares() {
        // Append object
        shareObject.append(self.contentObject!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(sharesVC, animated: true)
    }
    
    
    
    // Function to show number of likes
    func showLikes() {
        // Append object
        likeObject.append(self.contentObject!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.photoAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    
    
    // Function to play video
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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Add user's profile photo tap to go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(userTap)
        
        // (2) Add username tap to go to user's profile
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        usernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(usernameTap)
        
        
        // (4) Add Share tap
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        
        // (5) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        
        // (6) Add like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        
        // (7) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        
        // (8) Add numberOfShares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (9)
        if self.contentObject?.value(forKey: "photoAsset") != nil {
            // (A) Zoom for Photo
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.photoAsset.isUserInteractionEnabled = true
            self.photoAsset.addGestureRecognizer(zoomTap)
        } else if self.contentObject?.value(forKey: "videoAsset") != nil {
            // (B) Play for Videos
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.photoAsset.isUserInteractionEnabled = true
            self.photoAsset.addGestureRecognizer(playTap)
        }
        
        
        // Handle @username tap
        textPost.userHandleLinkTapHandler = { label, handle, range in
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
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        
        // Handle http: tap
        textPost.urlLinkTapHandler = { label, handle, range in
            // MARK: - SwiftWebVC
            let webVC = SwiftModalWebVC(urlString: handle)
            self.delegate?.navigationController?.present(webVC, animated: true, completion: nil)
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
