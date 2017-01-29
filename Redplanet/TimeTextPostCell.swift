//
//  TimeTextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SimpleAlert
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
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.delegate?.pushViewController(otherVC, animated: true)
    }
    
    
    
    // More button
    func showMore(sender: UIButton) {
        
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
                                    viewsObject.append(self.postObject!)
                                    
                                    // Push VC
                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
                                    
        })
        
        // (2) Edit
        let edit = AlertAction(title: "🔩 Edit",
                               style: .default,
                               handler: { (AlertAction) in
                                
                                // Append object
                                editObjects.append(self.postObject!)
                                
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
                                                        
                                                        // Dismiss
                                                        SVProgressHUD.dismiss()
                                                        
                                                        // Reload data
                                                        NotificationCenter.default.post(name: timelineNotification, object: nil)
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
        
        
        
        // (4) Report Content
        let reportBlock = AlertAction(title: "Report",
                                      style: .destructive,
                                      handler: { (AlertAction) in
                                        
                                        let alert = UIAlertController(title: "Report",
                                                                      message: "Please provide your reason for reporting \(self.postObject!.value(forKey: "username") as! String)'s Text Post",
                                            preferredStyle: .alert)
                                        
                                        let report = UIAlertAction(title: "Report", style: .destructive) {
                                            [unowned self, alert] (action: UIAlertAction!) in
                                            
                                            let answer = alert.textFields![0]
                                            
                                            // Save to <Block_Reported>
                                            let report = PFObject(className: "Block_Reported")
                                            report["from"] = PFUser.current()!.username!
                                            report["fromUser"] = PFUser.current()!
                                            report["to"] = self.postObject!.value(forKey: "username") as! String
                                            report["toUser"] = self.postObject!.value(forKey: "byUser") as! PFUser
                                            report["forObjectId"] = self.postObject!.objectId!
                                            report["type"] = answer.text!
                                            report.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved report: \(report)")
                                                    
                                                    // Dismiss
                                                    let alert = UIAlertController(title: "Successfully Reported",
                                                                                  message: "\(self.postObject!.value(forKey: "username") as! String)'s Text Post",
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
        
        
        
        
        if (self.postObject!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            options.addAction(views)
            options.addAction(edit)
            options.addAction(delete)
            options.addAction(cancel)
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            edit.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            edit.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else {
            options.addAction(cancel)
            options.addAction(reportBlock)
            reportBlock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            reportBlock.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        }
        
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    // Function to share
    func shareOptions() {
        
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
                                        let newsfeeds = PFObject(className: "Newsfeeds")
                                        newsfeeds["byUser"] = PFUser.current()!
                                        newsfeeds["username"] = PFUser.current()!.username!
                                        newsfeeds["textPost"] = "shared @\(self.rpUsername.text!)'s Text Post: \(self.textPost.text!)"
                                        newsfeeds["pointObject"] = textPostObject.last!
                                        newsfeeds["contentType"] = "sh"
                                        newsfeeds.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if error == nil {
                                                print("Successfully shared text post: \(newsfeeds)")
                                                
                                                
                                                // Send Notification
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["fromUser"] = PFUser.current()!
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["toUser"] = textPostObject.last!.value(forKey: "byUser") as! PFUser
                                                notifications["to"] = self.rpUsername.text!
                                                notifications["type"] = "share tp"
                                                notifications["forObjectId"] = textPostObject.last!.objectId!
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
                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) shared your Text Post"],
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
                                                                                      message: "Successfully shared \(self.rpUsername.text!)'s Text Post.",
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
        
        let privateShare = AlertAction(title: "One Friend",
                                       style: .default,
                                       handler: { (AlertAction) in
                                        
                                        // Append to contentObject
                                        shareObject.append(self.postObject!)
                                        
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
    
    
    
    // Function to like content
    func like(sender: UIButton) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            
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
                                
                                // Send Notification
                                NotificationCenter.default.post(name: timelineNotification, object: nil)
                                
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
                    
                    // Send Notification
                    NotificationCenter.default.post(name: timelineNotification, object: nil)
                    
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
        // (1) Tap for rpUserProPic and rpUsername
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        // (2) Tap for rpUsername
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // (3) Like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (4) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (5) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (6) Add Share tap
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (7) Add numberOfShares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (8) More Button
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(showMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
