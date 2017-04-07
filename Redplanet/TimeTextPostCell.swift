//
//  TimeTextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SVProgressHUD

class TimeTextPostCell: UITableViewCell {
    
    // Initialize delegate
    var delegate: UINavigationController?
    
    // Initialize user object delegate
    var userObject: PFObject?
    
    // Initialize posts' object: PFObject
    var postObject: PFObject?

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
        NotificationCenter.default.post(name: textPostNotification, object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "followingNewsfeed"), object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
        NotificationCenter.default.post(name: otherNotification, object: nil)
    }
    
    
    // More button
    func showMore(sender: UIButton) {

        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: "Text Post")
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
        
        // (1) EDIT
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            editObjects.append(self.postObject!)
            // Push VC
            let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            self.delegate?.pushViewController(editVC, animated: true)
        })
        
        // (2) SAVE
        let save = AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
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
        
        // (3) DELETE
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
            SVProgressHUD.show()
            
            // Delete content
            let content = PFQuery(className: "Newsfeeds")
            content.whereKey("byUser", equalTo: PFUser.current()!)
            content.whereKey("objectId", equalTo: self.postObject!.objectId!)
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("pointObject", equalTo: self.postObject!)
            
            let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
            newsfeeds.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Delete object
                        object.deleteInBackground(block: {
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
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - SVProgressHUD
                    SVProgressHUD.showError(withStatus: "Error")
                }
            })
        })
        
        // (4) REPORT
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            let alert = UIAlertController(title: "Report",
                                          message: "Please provide your reason for reporting \(self.rpUsername.text!)'s Text Post",
                preferredStyle: .alert)
            
            let report = UIAlertAction(title: "Report", style: .destructive) {
                [unowned self, alert] (action: UIAlertAction!) in
                
                let answer = alert.textFields![0]
                
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["to"] = self.postObject!.value(forKey: "username") as! String
                report["toUser"] = self.postObject!.value(forKey: "byUser") as! PFUser
                report["forObjectId"] = self.postObject!.objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved report: \(report)")
                        
                        // MARK: - SVProgressHUD
                        SVProgressHUD.showSuccess(withStatus: "Reported")
                        
                        // Dismiss
                        dialog.dismiss()
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Dismiss
                        dialog.dismiss()
                    }
                })
            }
            
            
            let cancel = UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: { (alertAction: UIAlertAction!) in
                                        // Dismiss
                                        dialog.dismiss()
            })
            
            alert.addTextField(configurationHandler: nil)
            alert.addAction(report)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            dialog.present(alert, animated: true, completion: nil)
        })
        
        
        // Show options dependent on user's objectId
        if (self.postObject!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(edit)
            dialogController.addAction(save)
            dialogController.addAction(delete)
            dialogController.show(in: self.delegate!)
        } else {
            dialogController.addAction(report)
            dialogController.show(in: self.delegate!)
        }
    }// end AZDialogViewController
    
    // Function to share
    func shareOptions() {
        // Append post's object: PFObject
        shareObject.append(self.postObject!)
        
        // Share to chats
        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
        self.delegate?.pushViewController(shareToVC, animated: true)
    }
    
    
    
    // Function to like content
    func like(sender: UIButton) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        // If Heart is Filled --> UIImage ==> Like Filled-100
        if self.likeButton.image(for: .normal) == UIImage(named: "Like Filled-100") {
        
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
            
        } else {
            // LIKE
            let likes = PFObject(className: "Likes")
            likes["fromUser"] = PFUser.current()!
            likes["from"] = PFUser.current()!.username!
            likes["toUser"] = self.userObject!
            likes["to"] = self.rpUsername.text!
            likes["forObjectId"] = self.postObject!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like \(likes)")
                    
                    
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    // Change button title and image
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
                    notifications["type"] = "like tp"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.userObject!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Text Post"],
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
    
    
    // Function to show number of likes
    func showLikes() {
        // Append object
        likeObject.append(self.postObject!)
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.pushViewController(likesVC, animated: true)
    }
    
    // Function to view comments
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
        
        // (2) LIKE
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (3) # OF LIKES
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
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
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(showMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
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
                        
                        // Append user's username
                        otherName.append(mention)
                        // Append user object
                        otherObject.append(object)
                        
                        // Push VC
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
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: true)
            webVC.view.layer.cornerRadius = 8.00
            webVC.view.clipsToBounds = true
            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
