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
import SimpleAlert

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
        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
        NotificationCenter.default.post(name: followingNewsfeed, object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
        NotificationCenter.default.post(name: otherNotification, object: nil)
    }
    
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
                    notifications["toUser"] = otherObject.last!
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
        
        
        
        let publicShare = AlertAction(title: "All Friends",
                                      style: .default,
                                      handler: { (AlertAction) in
                                        
                                        // Share to public ***FRIENDS ONLY***
                                        
                                        
                                        // Convert UIImage to NSData
                                        let imageData = UIImageJPEGRepresentation(self.rpUserProPic.image!, 0.5)
                                        // Change UIImage to PFFile
                                        let parseFile = PFFile(data: imageData!)
                                        
                                        let newsfeeds = PFObject(className: "Newsfeeds")
                                        newsfeeds["byUser"] = PFUser.current()!
                                        newsfeeds["username"] = PFUser.current()!.username!
                                        newsfeeds["textPost"] = "shared @\(self.userObject!.value(forKey: "username") as! String)'s Profile Photo: \(self.textPost.text!)"
                                        newsfeeds["photoAsset"] = parseFile
                                        newsfeeds["pointObject"] = self.postObject!
                                        newsfeeds["contentType"] = "sh"
                                        newsfeeds.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if error == nil {
                                                print("Successfully shared photo: \(newsfeeds)")
                                                
                                                
                                                // Send Notification
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["fromUser"] = PFUser.current()!
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["toUser"] = self.userObject!
                                                notifications["to"] = self.rpUsername.text!
                                                notifications["type"] = "share pp"
                                                notifications["forObjectId"] = self.postObject!.objectId!
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        
                                                        // Handle optional chaining
                                                        if otherObject.last!.value(forKey: "apnsId") != nil {
                                                            // MARK: - OneSignal
                                                            // Send push notification
                                                            OneSignal.postNotification(
                                                                ["contents":
                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) shared your Text Post"],
                                                                 "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"],
                                                                 "ios_badgeType": "Increase",
                                                                 "ios_badgeCount": 1
                                                                ]
                                                            )
                                                        }
                                                        
                                                        // Reload data
                                                        self.reloadData()
                                                        
                                                        // Show alert
                                                        let alert = UIAlertController(title: "Shared With Friends",
                                                                                      message: "Successfully shared \(self.rpUsername.text!)'s Photo.",
                                                            preferredStyle: .alert)
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .default,
                                                                               handler: {(alertAction: UIAlertAction!) in
                                                                                // Pop view controller
                                                                                _ = self.delegate?.popViewController(animated: true)
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
        
        
        
        let privateShare = AlertAction(title: "One Friend",
                                       style: .default,
                                       handler: { (AlertAction) in
                                        
                                        // Share privately only
                                        // Append to contentObject
                                        shareObject.append(self.postObject!)
                                        
                                        // Share to chats
                                        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
                                        self.delegate?.pushViewController(shareToVC, animated: true)
                                        
        })
        
        
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .destructive,
                                 handler: nil)
        
        options.addAction(publicShare)
        options.addAction(privateShare)
        options.addAction(cancel)
        publicShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        publicShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        privateShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        privateShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.delegate?.present(options, animated: true, completion: nil)
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
        
        
        //        // (1) Views
        //        let views = AlertAction(title: "🙈 Views",
        //                                style: .default,
        //                                handler: { (AlertAction) in
        //                                    // Append object
        //                                    viewsObject.append(proPicObject.last!)
        //
        //                                    // Push VC
        //                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
        //                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
        //        })
        
        
        // (2)
        let edit = AlertAction(title: "🔩 Edit",
                               style: .default,
                               handler: { (AlertAction) in
                                
                                // Append object
                                editObjects.append(self.postObject!)
                                
                                // Push VC
                                let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                self.delegate?.pushViewController(editVC, animated: true)
        })
        
        
        // (3) Delete
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    /*
                                     (1) If currentUser is trying to delete his/her's most RECENT Profile Photo...
                                     • Change 'proPicExists' == false
                                     • Save new profile photo
                                     • Delete object from <Newsfeeds>
                                     
                                     (2) OTHERWISE
                                     • Keep 'proPicExists' == true
                                     • Delete object from <Newsfeeds>
                                     
                                     */
                                    
                                    // Show Progress
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.show(withStatus: "Deleting")
                                    
                                    // (1) Check if object is most recent by querying getFirstObject
                                    let recentProPic = PFQuery(className: "Newsfeeds")
                                    recentProPic.whereKey("byUser", equalTo: PFUser.current()!)
                                    recentProPic.whereKey("contentType", equalTo: "pp")
                                    recentProPic.order(byDescending: "createdAt")
                                    recentProPic.getFirstObjectInBackground(block: {
                                        (object: PFObject?, error: Error?) in
                                        if error == nil {
                                            
                                            if object! == self.postObject! {
                                                
                                                // Most recent Profile Photo
                                                // Delete object
                                                object?.deleteInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Most Recent Profile Photo has been deleted: \(object)")
                                                        
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
                                                                
                                                                // Dismiss Progress
                                                                SVProgressHUD.dismiss()
                                                                
                                                                // Reload data
                                                                self.reloadData()
                                                                
                                                                // Pop view controller
                                                                _ = self.delegate?.popViewController(animated: true)
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                        
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
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
                                                                    
                                                                    // Dismiss
                                                                    SVProgressHUD.dismiss()
                                                                    
                                                                    // Current User's Profile Photo DOES EXIST
                                                                    PFUser.current()!["proPicExists"] = true
                                                                    PFUser.current()!.saveEventually()
                                                                    
                                                                    // Reload data
                                                                    self.reloadData()
                                                                    
                                                                    // Pop view controller
                                                                    _ = self.delegate?.popViewController(animated: true)
                                                                    
                                                                    
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
                                            
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            
                                        }
                                    })
                                    
        })
        
        
        // (4) Report Content
        let reportBlock = AlertAction(title: "Report",
                                      style: .destructive,
                                      handler: { (AlertAction) in
                                        
                                        let alert = UIAlertController(title: "Report",
                                                                      message: "Please provide your reason for reporting \(self.rpUsername.text!)'s Profile Photo",
                                            preferredStyle: .alert)
                                        
                                        let report = UIAlertAction(title: "Report", style: .destructive) {
                                            [unowned self, alert] (action: UIAlertAction!) in
                                            
                                            let answer = alert.textFields![0]
                                            
                                            let report = PFObject(className: "Block_Reported")
                                            report["from"] = PFUser.current()!.username!
                                            report["fromUser"] = PFUser.current()!
                                            report["to"] = self.rpUsername.text!
                                            report["toUser"] = self.userObject!
                                            report["forObjectId"] = self.postObject!.objectId!
                                            report["type"] = answer.text!
                                            report.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved report: \(report)")
                                                    
                                                    // Dismiss
                                                    let alert = UIAlertController(title: "Successfully Reported",
                                                                                  message: "\(self.rpUsername.text!)'s Profile Photo",
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
        
        
        if self.postObject!.objectId! == PFUser.current()!.objectId! {
            //            options.addAction(views)
            options.addAction(edit)
            options.addAction(delete)
            options.addAction(cancel)
            edit.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            edit.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else {
            options.addAction(cancel)
            options.addAction(reportBlock)
            reportBlock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            reportBlock.button.setTitleColor(UIColor(red: 1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        }
        
        self.delegate?.present(options, animated: true, completion: nil)
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

    override func awakeFromNib() {
        super.awakeFromNib()
        // (1) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)
        
        // (2) ACTION to Like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(likePP))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (3) Comment button tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(showComments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (4) Number of likes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (5) Private Share
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareContent))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (6) Number of shares
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(sharers))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (7) Go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        
        // (8) Go to user's profile
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.smallProPic.isUserInteractionEnabled = true
        self.smallProPic.addGestureRecognizer(proPicTap)
        
        // (10) More tap
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
