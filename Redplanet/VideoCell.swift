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
import SVProgressHUD
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
    @IBOutlet weak var moreButton: UIButton!
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
                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                     "ios_badgeType": "Increase",
                                     "ios_badgeCount": 1
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
        let options = AlertController(title: "Share With",
                                        message: nil,
                                        style: .alert)
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
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
                                                                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                                                                     "ios_badgeType": "Increase",
                                                                     "ios_badgeCount": 1
                                                                    ]
                                                                )
                                                            }
                                                            
                                                            
                                                            
                                                            
                                                            // Reload data
                                                            NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                            NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                            
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
        publicShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        publicShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        privateShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        privateShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
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
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    // Function for moreButton
    func doMore(sender: UIButton) {
        // MARK: - SimpleAlert
        let options = AlertController(title: "Options",
                                      message: nil,
                                      style: .alert)
        
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
            }
        }
        
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }
        
        
        // (1) Views
//        let views = AlertAction(title: "🙈 Views",
//                                style: .default,
//                                handler: { (AlertAction) in
//                                    // Append object
//                                    viewsObject.append(videoObject.last!)
//                                    
//                                    // Push VC
//                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
//                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
//
//        })
        
        // (2) Edit
        let edit = AlertAction(title: "🔩 Edit",
                               style: .default,
                               handler: { (AlertAction) in
                                    
                                    // Append object
                                    editObjects.append(videoObject.last!)
                                    
                                    // Push VC
                                    let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                    self.delegate?.navigationController?.pushViewController(editVC, animated: true)
        })
        
        // (3) Delete
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    
                                    // Show Progress
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.show(withStatus: "Deleting")
                                    
                                    // Delete content
                                    let content = PFQuery(className: "Newsfeeds")
                                    content.whereKey("byUser", equalTo: PFUser.current()!)
                                    content.whereKey("objectId", equalTo: videoObject.last!.objectId!)
                                    
                                    let shares = PFQuery(className: "Newsfeeds")
                                    shares.whereKey("pointObject", equalTo: videoObject.last!)
                                    
                                    let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                    newsfeeds.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                // Delete object
                                                object.deleteInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully deleted object: \(object)")
                                                        
                                                        // Dismiss
                                                        SVProgressHUD.dismiss()
                                                        
                                                        
                                                        // Reload data
                                                        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                        NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                        
                                                        // Pop view controller
                                                        _ = self.delegate?.navigationController?.popViewController(animated: true)
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                    
        })
        
        // (4) Report
        let report = AlertAction(title: "Report",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    
                                    let alert = UIAlertController(title: "Report",
                                                                  message: "Please provide your reason for reporting \(videoObject.last!.value(forKey: "username") as! String)'s Text Post",
                                        preferredStyle: .alert)
                                    
                                    let report = UIAlertAction(title: "Report", style: .destructive) {
                                        [unowned self, alert] (action: UIAlertAction!) in
                                        
                                        let answer = alert.textFields![0]
                                        
                                        // Save to <Block_Reported>
                                        let report = PFObject(className: "Block_Reported")
                                        report["from"] = PFUser.current()!.username!
                                        report["fromUser"] = PFUser.current()!
                                        report["to"] = videoObject.last!.value(forKey: "username") as! String
                                        report["toUser"] = videoObject.last!.value(forKey: "byUser") as! PFUser
                                        report["forObjectId"] = videoObject.last!.objectId!
                                        report["type"] = answer.text!
                                        report.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully saved report: \(report)")
                                                
                                                // Dismiss
                                                let alert = UIAlertController(title: "Successfully Reported",
                                                                              message: "\(videoObject.last!.value(forKey: "username") as! String)'s Text Post",
                                                    preferredStyle: .alert)
                                                
                                                let ok = UIAlertAction(title: "ok",
                                                                       style: .default,
                                                                       handler: nil)
                                                
                                                alert.addAction(ok)
                                                alert.view.tintColor = UIColor.black
                                                self.delegate?.present(alert, animated: true, completion: nil)
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                    }
                                    
                                    
                                    let cancel = UIAlertAction(title: "Cancel",
                                                               style: .cancel,
                                                               handler: nil)
                                    
                                    
                                    alert.addTextField(configurationHandler: nil)
                                    alert.addAction(report)
                                    alert.addAction(cancel)
                                    alert.view.tintColor = UIColor.black
                                    self.delegate?.present(alert, animated: true, completion: nil)
        })
        
        // (5) Cancel
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        

        
        if (videoObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
//            options.addAction(views)
            options.addAction(edit)
            options.addAction(delete)
            options.addAction(cancel)
//            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
//            views.button.setTitleColor(UIColor.black, for: .normal)
            edit.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            edit.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else {
            options.addAction(cancel)
            options.addAction(report)
            report.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            report.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        }
        
        self.delegate?.present(options, animated: true, completion: nil)
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
        
        // More tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
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
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
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
            let url = URL(string: handle)
            UIApplication.shared.openURL(url!)
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
