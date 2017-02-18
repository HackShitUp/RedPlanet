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
import SimpleAlert

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
        
        // MARK: - SimpleAlert
        let options = AlertController(title: "Share With",
                                        message: "Shared Post",
                                        style: .alert)
        // Design content view
        options.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15.00)
            }
        }
        // Design corner radius
        options.configContainerCornerRadius = {
            return 14.00
        }

        
        let publicShare = AlertAction(title: "Everyone",
                                        style: .default,
                                        handler: { (AlertAction) in
                                            
                                            // Share to public ***FRIENDS ONLY***
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
                                            newsfeeds["textPost"] = "shared @\(self.fromRpUsername.text!)'s Share:"
                                            newsfeeds["pointObject"] = self.cellSharedObject!
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
                                                    notifications["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
                                                    notifications["to"] = self.rpUsername.text!
                                                    notifications["type"] = "share sh"
                                                    notifications["forObjectId"] = sharedObject.last!.objectId!
                                                    notifications.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            
                                                            // Handle optional chaining
                                                            if self.byUserObject!.value(forKey: "apnsId") != nil {
                                                                // MARK: - OneSignal
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!.uppercased()) re-shared your Shared Post"],
                                                                     "include_player_ids": ["\(self.byUserObject!.value(forKey: "apnsId") as! String)"],
                                                                     "ios_badgeType": "Increase",
                                                                     "ios_badgeCount": 1
                                                                    ]
                                                                )
                                                            }
                                                            

                                                            // Reload data
                                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                                            NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                            
                                                            // Show alert
                                                            let alert = UIAlertController(title: "Shared With Friends",
                                                                                          message: "Successfully shared \(self.rpUsername.text!)'s Share.",
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
        
        let privateShare = AlertAction(title: "One Person",
                                         style: .default,
                                         handler: { (AlertAction) in
                                            
                                            // Append to contentObject
                                            shareObject.append(self.cellSharedObject!)
                                            
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
        publicShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        publicShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        privateShare.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
        privateShare.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    
    
    // Function to do more
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
        let views = AlertAction(title: "🙈 Views",
                                style: .default,
                                handler: { (AlertAction) in
                                    // Append object
                                    viewsObject.append(itmObject.last!)
                                    // Push VC
                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
        })
        

        // (2) Delete Shared Post
        let delete = AlertAction(title: "Delete",
                                style: .destructive,
                                handler: { (AlertAction) in
                                            
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
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
        
        
        // (3) Save Post
        let save = AlertAction(title: "Save Post",
                               style: .default,
                               handler: { (AlertAction) in
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
        
        
        // (4) Delete Shared Post
        let report = AlertAction(title: "Report",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    
                                    let alert = UIAlertController(title: "Report",
                                                                  message: "Please provide your reason for reporting \(sharedObject.last!.value(forKey: "username") as! String)'s Share",
                                        preferredStyle: .alert)
                                    
                                    let report = UIAlertAction(title: "Report", style: .destructive) {
                                        [unowned self, alert] (action: UIAlertAction!) in
                                        
                                        let answer = alert.textFields![0]
                                        
                                        // Save to <Block_Reported>
                                        let report = PFObject(className: "Block_Reported")
                                        report["from"] = PFUser.current()!.username!
                                        report["fromUser"] = PFUser.current()!
                                        report["to"] = sharedObject.last!.value(forKey: "username") as! String
                                        report["toUser"] = sharedObject.last!.value(forKey: "byUser") as! PFUser
                                        report["forObjectId"] = sharedObject.last!.objectId!
                                        report["type"] = answer.text!
                                        report.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully saved report: \(report)")
                                                
                                                // Dismiss
                                                let alert = UIAlertController(title: "Successfully Reported",
                                                                              message: "\(sharedObject.last!.value(forKey: "username") as! String)'s Share",
                                                    preferredStyle: .alert)
                                                
                                                let ok = UIAlertAction(title: "ok",
                                                                       style: .default,
                                                                       handler: nil)
                                                
                                                alert.addAction(ok)
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
        
        

        
        if (sharedObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            options.addAction(views)
            options.addAction(save)
            options.addAction(delete)
            options.addAction(cancel)
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            save.button.setTitleColor(UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else {
            options.addAction(cancel)
            options.addAction(report)
            report.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            report.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        }
        
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Add byUserProPic tap
        let byUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(goByUser))
        byUserProPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(byUserProPicTap)
        
        // (2) add byUsername tap
        let byUsernameTap = UITapGestureRecognizer(target: self, action: #selector(goByUser))
        byUsernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(byUsernameTap)
        
        // (3) Add fromUserProPicTap
        let fromProPicTap = UITapGestureRecognizer(target: self, action: #selector(goFromUser))
        fromProPicTap.numberOfTapsRequired = 1
        self.fromRpUserProPic.isUserInteractionEnabled = true
        self.fromRpUserProPic.addGestureRecognizer(fromProPicTap)
        
        // (4) Add fromRpUsernameTap
        let fromUsernameTap = UITapGestureRecognizer(target: self, action: #selector(goFromUser))
        fromUsernameTap.numberOfTapsRequired = 1
        self.fromRpUsername.isUserInteractionEnabled = true
        self.fromRpUsername.addGestureRecognizer(fromUsernameTap)

        // (5) Add ContainerView tap
        let contentTap = UITapGestureRecognizer(target: self, action: #selector(pushContent))
        contentTap.numberOfTapsRequired = 1
        self.container.isUserInteractionEnabled = true
        self.container.addGestureRecognizer(contentTap)
        
        // (6) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (7) Add like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (8) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (9) Add comment tap
        let cCommentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        cCommentTap.numberOfTapsRequired = 1
        self.commentButton.isUserInteractionEnabled = true
        self.commentButton.addGestureRecognizer(cCommentTap)
        
        // (10) Add numberOfShares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (11) Add Share tap
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (12) More tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
