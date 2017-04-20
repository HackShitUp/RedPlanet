//
//  SharedPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/11/16.
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

class SharedPostCell: UITableViewCell {
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    // Initialize shared content's object
    var cellSharedObject: PFObject?
    
    // Initialize fromUser's object; PFObject
    var fromUserObject: PFObject?
    
    // Initialize byUser's object; PFObject
    var byUserObject: PFObject?
    

    // IBOutlets - User who shared content
    @IBOutlet weak var fromRpUserProPic: PFImageView!
    @IBOutlet weak var sharedTime: UILabel!
    @IBOutlet weak var fromRpUsername: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    // IBOutlets - Shared content
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    // IBOutlets - Buttons
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    // Function to go to fromUser's profile
    func goFromUser(sender: UIButton) {
        // Append user's object
        otherObject.append(self.fromUserObject!)
        // Apend otherName
        otherName.append(self.fromRpUsername.text!)
        
        // Push VC
        let fromUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(fromUserVC, animated: true)
    }
    
    
    // Function to go to byUser's profile
    func goByUser(sender: UIButton) {
        // Append user's object
        otherObject.append(self.byUserObject!)
        // Append otherName
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let fromUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(fromUserVC, animated: true)
    }
    
    
    // Function to push to conetnt
    func pushContent(sender: UIButton) {
        // Find Original Content
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: self.cellSharedObject!.objectId!)
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                for object in objects! {
                    if object["contentType"] as! String == "tp" {
                        // Text Post
                        // Append object
                        textPostObject.append(object)
                        
                        // Push VC
                        let textPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                        self.delegate?.navigationController?.pushViewController(textPostVC, animated: true)
                    }
                    
                    if object["contentType"] as! String == "ph" {
                        // Photo
                        // Append object
                        photoAssetObject.append(object)
                        
                        // Push VC
                        let photoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                        self.delegate?.navigationController?.pushViewController(photoVC, animated: true)
                    }
                    
                    if object["contentType"] as! String == "pp" {
                        // Profile Photo
                        // Append object
                        proPicObject.append(object)
                        otherObject.append(object.value(forKey: "byUser") as! PFUser)
                        otherName.append(object.value(forKey: "username") as! String)
                        
                        // Push VC
                        let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                        self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                    }
                    
                    if object["contentType"] as! String == "sp" {
                        // Space Post
                        // Append object
                        spaceObject.append(object)
                        otherObject.append(object["toUser"] as! PFUser)
                        otherName.append(object["username"] as! String)
                        
                        // Push VC
                        let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                        self.delegate?.navigationController?.pushViewController(spacePostVC, animated: true)
                    }
                    
                    if object["contentType"] as! String == "itm" {
                        // Moment
                        // Append object
                        itmObject.append(object)
                        // Push VC
                        let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                        self.delegate?.navigationController?.pushViewController(itmVC, animated: true)
                    }
                    
                    if object["contentType"] as! String == "vi" {
                        // Video
                        // Append object
                        videoObject.append(object)
                        
                        // Push VC
                        let videoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                        self.delegate?.navigationController?.pushViewController(videoVC, animated: true)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    
    
    // Function to show number of likes
    func showLikes() {
        // Append object
        likeObject.append(sharedObject.last!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }

    
    
    // Function to like content
    func like(sender: UIButton) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Successfully deleted like: \(object)")

                                
                                // Delete "Notifications"
                                let notifications = PFQuery(className: "Notifications")
                                notifications.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
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
                                
                                
                                // Re-enable buttons
                                self.likeButton.isUserInteractionEnabled = true
                                self.likeButton.isEnabled = true
                                
                                
                                // Change button title and image
                                self.likeButton.setTitle("notLiked", for: .normal)
                                self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                                
                                // Send Notification
                                NotificationCenter.default.post(name: sharedPostNotification, object: nil)
                                
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
            likes["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
            likes["to"] = self.rpUsername.text!
            likes["forObjectId"] = sharedObject.last!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like \(likes)")
                    
                    // Save to notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = self.rpUsername.text!
                    notifications["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["forObjectId"] = sharedObject.last!.objectId!
                    notifications["type"] = "like sh"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.fromUserObject!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Shared Post"],
                                     "include_player_ids": ["\(self.byUserObject!.value(forKey: "apnsId") as! String)"],
                                     "ios_badgeType": "Increase",
                                     "ios_badgeCount": 1
                                    ]
                                )
                            }
                            
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    
                    // Re-enable buttons
                    self.likeButton.isUserInteractionEnabled = true
                    self.likeButton.isEnabled = true
                    
                    
                    // Change button title and image
                    self.likeButton.setTitle("liked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    
                    // Send Notification
                    NotificationCenter.default.post(name: sharedPostNotification, object: nil)
                    
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
                    
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
    }
    
    
    
    
    // Function to go to comments
    @IBAction func comment(_ sender: Any) {
        // Append object
        commentsObject.append(sharedObject.last!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    
    // Function to show number of shares
    func showShares() {
        // Append object
        shareObject.append(sharedObject.last!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(sharesVC, animated: true)
    }
    
    
    
    // Function to share
    func shareOptions() {
        // Append post's object: PFObject
        shareObject.append(sharedObject.last!)
        
        // Share to chats
        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
        self.delegate?.navigationController?.pushViewController(shareToVC, animated: true)
    }
    
    
    
    // Function to do more
    func doMore(sender: UIButton) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Shared Post", message: "Options")
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
        
        // (1) VIEWS
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            viewsObject.append(sharedObject.last!)
            // Push VC
            let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) DELETE
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
            SVProgressHUD.show(withStatus: "Deleting")
            
            // Delete content
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
            newsfeeds.whereKey("objectId", equalTo: sharedObject.last!.objectId!)
            newsfeeds.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Delete object
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                                SVProgressHUD.showSuccess(withStatus: "Deleted")
                                
                                // Reload data
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                
                                // Pop view controller
                                _ = self.delegate?.navigationController?.popViewController(animated: true)
                                
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
        
        // (3) SAVE
        let save = AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor.black)
            SVProgressHUD.show(withStatus: "Saving")
            
            // Save Post
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.getObjectInBackground(withId: sharedObject.last!.objectId!, block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    object!["saved"] = true
                    object!.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if error == nil {
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
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
        
        // (4) Report
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            let alert = UIAlertController(title: "Report",
                                          message: "Please provide your reason for reporting \(sharedObject.last!.value(forKey: "username") as! String)'s Share",
                preferredStyle: .alert)
            
            let report = UIAlertAction(title: "Report", style: .destructive) { (action: UIAlertAction!) in
                
                let answer = alert.textFields![0]
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["toUsername"] = sharedObject.last!.value(forKey: "username") as! String
                report["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
                report["forObjectId"] = sharedObject.last!.objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved report: \(report)")
                        
                        // MARK: - SVProgressHUD
                        SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
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
            dialog.present(alert, animated: true, completion: nil)
        })
        
        
        // Show options dependent on user's objectId
        if (sharedObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(save)
            dialogController.addAction(delete)
            dialogController.show(in: self.delegate!)
        } else {
            dialogController.addAction(report)
            dialogController.show(in: self.delegate!)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) NAVIGATE TO USER
        let byUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(goByUser))
        byUserProPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(byUserProPicTap)
        let byUsernameTap = UITapGestureRecognizer(target: self, action: #selector(goByUser))
        byUsernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(byUsernameTap)
        
        // (2) NAVIGATE TO USER
        let fromProPicTap = UITapGestureRecognizer(target: self, action: #selector(goFromUser))
        fromProPicTap.numberOfTapsRequired = 1
        self.fromRpUserProPic.isUserInteractionEnabled = true
        self.fromRpUserProPic.addGestureRecognizer(fromProPicTap)
        let fromUsernameTap = UITapGestureRecognizer(target: self, action: #selector(goFromUser))
        fromUsernameTap.numberOfTapsRequired = 1
        self.fromRpUsername.isUserInteractionEnabled = true
        self.fromRpUsername.addGestureRecognizer(fromUsernameTap)

        // (3) GO TO CONTENT
        let contentTap = UITapGestureRecognizer(target: self, action: #selector(pushContent))
        contentTap.numberOfTapsRequired = 1
        self.container.isUserInteractionEnabled = true
        self.container.addGestureRecognizer(contentTap)
        
        // (4) # OF LIKES
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (5) LIKE
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (6) COMMENT
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (7) # OF COMMENTS
        let cCommentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        cCommentTap.numberOfTapsRequired = 1
        self.commentButton.isUserInteractionEnabled = true
        self.commentButton.addGestureRecognizer(cCommentTap)
        
        // (8) # OF SHARES
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (9) SHARE
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (10) MORE
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
