//
//  TimeMediaCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SimpleAlert
import SVProgressHUD


class TimeMediaCell: UITableViewCell {
    
    // Initialize delegate
    var delegate: UINavigationController?
    
    // Initialize posts' object: PFObject
    var postObject: PFObject?
    
    // Initialize user's object: PFObject
    var userObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    // Function to go to user's profile
    func goUser(sender: Any) {
        otherObject.append(self.userObject!)
        otherName.append(self.userObject!.value(forKey: "username") as! String)
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.pushViewController(otherVC, animated: true)
    }
    
    // Function to reload data
    func reloadData() {
        // Send Notification
        NotificationCenter.default.post(name: photoNotification, object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "followingNewsfeed"), object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
        NotificationCenter.default.post(name: otherNotification, object: nil)
    }
    
    // Function to send push notification
    func sendPush() {
        // MARK: - OneSignal
        // Send push notification
        if self.userObject!.value(forKey: "apnsId") != nil {
            
            if self.postObject!.value(forKey: "contentType") as! String == "ph" {
                OneSignal.postNotification(
                    ["contents":
                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Photo"],
                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                     "ios_badgeType": "Increase",
                     "ios_badgeCount": 1
                    ]
                )
            } else if self.postObject!.value(forKey: "contentType") as! String == "pp" {
                OneSignal.postNotification(
                    ["contents":
                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Profile Photo"],
                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                     "ios_badgeType": "Increase",
                     "ios_badgeCount": 1
                    ]
                )
                
            } else if self.postObject!.value(forKey: "contentType") as! String == "vi" {
                OneSignal.postNotification(
                    ["contents":
                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Video"],
                     "include_player_ids": ["\(self.userObject!.value(forKey: "apnsId") as! String)"],
                     "ios_badgeType": "Increase",
                     "ios_badgeCount": 1
                    ]
                )
            }
        }
    }
    
    // Function to like Photo, Profile Photo, or Video
    func like(sender: Any) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.image(for: .normal) == UIImage(named: "Like-100") {
            
            // LIKE
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["forObjectId"] = self.postObject?.objectId!
            likes["toUser"] = self.userObject!
            likes["to"] = self.rpUsername.text!
            likes.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    // Change button image
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
                    // Reload data
                    self.reloadData()
                    
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
                    notifications["forObjectId"] = self.postObject!.objectId!
                    notifications["type"] = "like \(self.postObject!.value(forKey: "contentType") as! String)"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // Send push notification
                            self.sendPush()
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
        } else {
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
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
                                
                                // Change button image
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
                                // Reload data
                                self.reloadData()
                                
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
                                notifications.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
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

        }
    }
    
    
    // Function to show number of likes
    func showLikes() {
        // Append object
        likeObject.append(self.postObject!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.pushViewController(likesVC, animated: true)
    }
    
    @IBAction func comments(_ sender: Any) {
        // Append object
        commentsObject.append(self.postObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.pushViewController(commentsVC, animated: true)
    }
    
    // Function to show number of shares
    func showShares() {
        // Append object
        shareObject.append(self.postObject!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.pushViewController(sharesVC, animated: true)
    }
    
    
    // Function to share
    func shareOptions() {
        // Append post's object: PFObject
        shareObject.append(self.postObject!)
        
        // Share to chats
        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
        self.delegate?.pushViewController(shareToVC, animated: true)
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
        
        
        // (1) Edit
        let edit = AlertAction(title: "Edit",
                               style: .default,
                               handler: { (AlertAction) in
                                
                                // Append object
                                editObjects.append(self.postObject!)
                                
                                // Push VC
                                let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                self.delegate?.pushViewController(editVC, animated: true)
        })
        
        // (2) Save Post
        let save = AlertAction(title: "Save",
                               style: .default,
                               handler: { (AlertAction) in
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.show(withStatus: "Saving")
                                
                                // Save Post
                                let newsfeeds = PFQuery(className: "Newsfeeds")
                                newsfeeds.getObjectInBackground(withId: self.postObject!.objectId!, block: {
                                    (object: PFObject?, error: Error?) in
                                    if error == nil {
                                        object!["saved"] = true
                                        object!.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if error == nil {
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.showSuccess(withStatus: "Saved")
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.showError(withStatus: "Error")
                                            }
                                        })
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - SVProgressHUD
                                        SVProgressHUD.showError(withStatus: "Error")
                                    }
                                })
        })
        
        // (3) Delete Photo
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                    SVProgressHUD.show()
                                    
                                    // Delete all shared posts and the original post
                                    let content = PFQuery(className: "Newsfeeds")
                                    content.whereKey("byUser", equalTo: PFUser.current()!)
                                    content.whereKey("objectId", equalTo: self.postObject!.objectId!)
                                    
                                    let shares = PFQuery(className: "Newsfeeds")
                                    shares.whereKey("pointObject", equalTo: self.postObject!)
                                    
                                    let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                    newsfeeds.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            // Delete objects
                                            PFObject.deleteAll(inBackground: objects, block: {
                                                (success: Bool, error: Error?) in
                                                if success {    
                                                    // Delete all Notifications
                                                    let notifications = PFQuery(className: "Notifications")
                                                    notifications.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
                                                    notifications.findObjectsInBackground(block: {
                                                        (objects: [PFObject]?, error: Error?) in
                                                        if error == nil {
                                                            for object in objects! {
                                                                object.deleteEventually()
                                                            }
                                                            // MARK: - SVProgressHUD
                                                            SVProgressHUD.showSuccess(withStatus: "Deleted")
                                                            
                                                            // Reload data
                                                            self.reloadData()
                                                            
                                                            // Pop view controller
                                                            _ = self.delegate?.popViewController(animated: true)
                                                        } else {
                                                            print(error?.localizedDescription as Any)
                                                            // MARK: - SVProgressHUD
                                                            SVProgressHUD.showError(withStatus: "Error")
                                                        }
                                                    })
                                                    
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.showError(withStatus: "Error")
                                                }
                                            })
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.showError(withStatus: "Error")
                                        }
                                    })
                                    
        })
        
        
        // (4) Report Content
        let report = AlertAction(title: "Report",
                                      style: .destructive,
                                      handler: { (AlertAction) in
                                        let alert = UIAlertController(title: "Report",
                                                                      message: "Please provide your reason for reporting \(self.userObject!.value(forKey: "username") as! String)'s Photo",
                                            preferredStyle: .alert)
                                        
                                        let report = UIAlertAction(title: "Report", style: .destructive) {
                                            [unowned self, alert] (action: UIAlertAction!) in
                                            
                                            let answer = alert.textFields![0]
                                            
                                            
                                            // REPORTED
                                            let report = PFObject(className: "Reported")
                                            report["byUsername"] = PFUser.current()!.username!
                                            report["byUser"] = PFUser.current()!
                                            report["to"] = self.userObject!.value(forKey: "username") as! String
                                            report["toUser"] = self.userObject!
                                            report["forObjectId"] = self.postObject!.objectId!
                                            report["reason"] = answer.text!
                                            report.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved report: \(report)")
                                                    
                                                    // Dismiss
                                                    let alert = UIAlertController(title: "Successfully Reported",
                                                                                  message: "\(self.userObject!.value(forKey: "username") as! String)'s Photo",
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
        
        if self.userObject!.objectId! == PFUser.current()!.objectId! {
            options.addAction(edit)
            options.addAction(save)
            options.addAction(delete)
            options.addAction(cancel)
            edit.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            edit.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
            save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17)
            save.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
        } else {
            options.addAction(cancel)
            options.addAction(report)
            report.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            report.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        }
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.delegate?.present(options, animated: true, completion: nil)
    }

    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // (1) NAVIGATE TO USER
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // (2) # OF LIKES
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (3) LIKE
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (4) COMMENT
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (5) SHARE
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (6) # OF SHARES
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)

        // (7) MORE
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
        // (8) ZOOM
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
        
        // Handle @username tap
        textPost.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: mention.lowercased())
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // APPEND DATA
                        otherName.append(mention)
                        otherObject.append(object)
                        // PUSH VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        // Handle #object tap
        textPost.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
            self.delegate?.pushViewController(hashTags, animated: true)
        }
        
        // Handle http: tap
        textPost.urlLinkTapHandler = { label, handle, range in
            // MARK: - SwiftWebVC
//            let webVC = SwiftModalWebVC(urlString: handle)
//            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
