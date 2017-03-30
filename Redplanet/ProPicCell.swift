//
//  ProPicCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/31/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SVProgressHUD

class ProPicCell: UITableViewCell {
    
    // Initialzie parent vc
    var delegate: UINavigationController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Intiialize post's object: PFObject
    var postObject: PFObject?
    
    @IBOutlet weak var smallProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    
    // Function to reload data
    func reloadData() {
        // Send notification
        NotificationCenter.default.post(name: profileNotification, object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "followingNewsfeed"), object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
        NotificationCenter.default.post(name: otherNotification, object: nil)
    }
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    
    // Like function button
    func likePP(sender: UIButton) {
        
        // Disable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        // Like or unlike depending on state
        if self.likeButton.image(for: .normal) == UIImage(named: "Like Filled-100") {
            // Unlike Profile Photo
            let likes = PFQuery(className: "Likes")
            likes.whereKey("fromUser", equalTo: PFUser.current()!)
            likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if error == nil {
                                print("Successfully deleted like: \(object)")
                                
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
            likes["forObjectId"] = self.postObject!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like: \(likes)")
                    
                    // Save to notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = self.rpUsername.text!
                    notifications["toUser"] = self.userObject!
                    notifications["forObjectId"] = self.postObject!.objectId!
                    notifications["type"] = "like pp"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if otherObject.last!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Profile Photo"],
                                     "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
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
    
    
    @IBAction func showComments(_ sender: Any) {
        // Append object
        commentsObject.append(self.postObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.pushViewController(commentsVC, animated: true)
    }
    
    
    
    // Function to show sharers
    func sharers() {
        // Append object
        shareObject.append(self.postObject!)
        
        // Push VC
        let shareVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.pushViewController(shareVC, animated: true)
    }
    
    
    // Function to share
    func shareContent() {
        // Append post's object: PFObject
        shareObject.append(self.postObject!)
        
        // Share to chats
        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
        self.delegate?.pushViewController(shareToVC, animated: true)
    }

    
    // Function for moreButton
    func doMore(sender: UIButton) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: "Profile Photo")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        // UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0).cgColor
            button.backgroundColor = UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        // (1) EDIT POST
        let editAction = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            editObjects.append(self.postObject!)
            // Push VC
            let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            self.delegate?.pushViewController(editVC, animated: true)
        })
        
        // (2) DELETE POST
        let deleteAction = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            /*
             (1) If currentUser is trying to delete his/her's most RECENT Profile Photo...
             • Change 'proPicExists' == false
             • Save new profile photo
             • Delete object from <Newsfeeds>
             
             (2) OTHERWISE
             • Keep 'proPicExists' == true
             • Delete object from <Newsfeeds>
             */
            
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
            SVProgressHUD.show(withStatus: "Deleting")
            
            // (1) Check if object is most recent by querying getFirstObject
            let recentProPic = PFQuery(className: "Newsfeeds")
            recentProPic.whereKey("byUser", equalTo: PFUser.current()!)
            recentProPic.whereKey("contentType", equalTo: "pp")
            recentProPic.order(byDescending: "createdAt")
            recentProPic.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    if object!.objectId! == self.postObject!.objectId! {
                        // Most recent Profile Photo
                        // Delete object
                        object?.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                
                                // Set new profile photo
                                let proPicData = UIImageJPEGRepresentation(UIImage(named: "Gender Neutral User-100")!, 0.5)
                                let parseFile = PFFile(data: proPicData!)
                                
                                // User's Profile Photo DOES NOT exist
                                PFUser.current()!["proPicExists"] = false
                                PFUser.current()!["userProfilePicture"] = parseFile
                                PFUser.current()!.saveInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        print("Deleted current profile photo and saved a new one.")
                                        
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
                                            print("Successfully deleted profile photo: \(object)")
                                            
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.showSuccess(withStatus: "Deleted")
                                            
                                            // Current User's Profile Photo DOES EXIST
                                            PFUser.current()!["proPicExists"] = true
                                            PFUser.current()!.saveEventually()
                                            
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
                                }
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
        
        // (3) REPORT POST
        let reportAction = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            let alert = UIAlertController(title: "Report",
                                          message: "Please provide your reason for reporting \(self.rpUsername.text!)'s Profile Photo",
                preferredStyle: .alert)
            
            let report = UIAlertAction(title: "Report", style: .destructive) {
                [unowned self, alert] (action: UIAlertAction!) in
                
                let answer = alert.textFields![0]
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["toUsername"] = self.rpUsername.text!
                report["toUser"] = self.userObject!
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
        
        // SHOW OPTIONS DEPENDING ON USER'S OBJECTID
        if self.userObject!.objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(editAction)
            dialogController.addAction(deleteAction)
            dialogController.show(in: self.delegate!)
        } else {
            dialogController.addAction(reportAction)
            dialogController.show(in: self.delegate!)
        }
    }
    
    
    // Function to go to user's profile
    func goUser() {
        // *** otherObject and otherName's data already appended ***
        otherObject.append(self.userObject!)
        otherName.append(self.rpUsername.text!)
        // Push VC
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.pushViewController(otherVC, animated: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Layout views
        self.rpUserProPic.layoutIfNeeded()
        self.rpUserProPic.layoutSubviews()
        self.rpUserProPic.setNeedsLayout()
        
        // Make Vide Preview Circular
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.darkGray.cgColor
        self.rpUserProPic.layer.borderWidth = 1.50
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // (1) ZOOM
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)
        
        // (2) LIKE
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(likePP))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (3) # OF LIKES
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (4) COMMENT
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(showComments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (5) SHARE
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareContent))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (6) # OF SHARES
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(sharers))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (7) GO TO USER'S PROFILE
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.smallProPic.isUserInteractionEnabled = true
        self.smallProPic.addGestureRecognizer(proPicTap)
        
        // (8) MORE
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
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
//            // MARK: - SafariServices
//            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: true)
//            webVC.view.layer.cornerRadius = 8.00
//            webVC.view.clipsToBounds = true
//            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
