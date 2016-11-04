//
//  MediaAssetCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel



class PhotoAssetCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Variabel to hold user's object
    var userObject: PFObject?
    
    // Variable to hold content object
    var contentObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var rpMedia: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBAction func moreButton(_ sender: AnyObject) {
        
        
        // Show Options
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        let delete = UIAlertAction(title: "Delete",
                                   style: .destructive,
                                   handler: {(alertAction: UIAlertAction!) in
        })
        
        let edit = UIAlertAction(title: "Edit",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
        })
        
        
        let views = UIAlertAction(title: "Views",
                                  style: .default,
                                  handler: {(alertAction: UIAlertAction!) in
        })
        
        
        let shareVia = UIAlertAction(title: "Share Via",
                                     style: .default,
                                     handler: {(alertAction: UIAlertAction!) in
                                        
                                        
                                        // set up activity view controller
                                        let image = self.rpMedia.image!
                                        let imageToShare = [image]
                                        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                                        activityViewController.popoverPresentationController?.sourceView = self.delegate?.view // so that iPads won't crash
                                        
                                        // exclude some activity types from the list (optional)
                                        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
                                        
                                        // present the view controller
                                        self.delegate?.present(activityViewController, animated: true, completion: nil)
        })
        
        
        // Report
        let report = UIAlertAction(title: "Report Content",
                                   style: .destructive,
                                   handler: {(alertAction: UIAlertAction!) in
                                    
                                    
                                    let alert = UIAlertController(title: "Report \(self.rpUsername.text!)'s content?",
                                        message: "Please enter your reason for reporting this content.",
                                        preferredStyle: .alert)
                                    
                                    
                                    let report = UIAlertAction(title: "report", style: .destructive) {
                                        [unowned self, alert] (action: UIAlertAction!) in
                                        
                                        let answer = alert.textFields![0]
                                        
                                        let report = PFObject(className: "Block_Reported")
                                        report["from"] = PFUser.current()!.username!
                                        report["fromUser"] = PFUser.current()!
                                        report["to"] = self.rpUsername.text!
                                        report["toUser"] = otherObject.last!
                                        report["forObjectId"] = textPostObject.last!.objectId!
                                        report["type"] = answer.text!
                                        report.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully saved report: \(report)")
                                                
                                                // Dismiss
                                                let alert = UIAlertController(title: "Successfully Reported",
                                                                              message: "\(self.rpUsername.text!)",
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
                                    
                                    let cancel = UIAlertAction(title: "cancel",
                                                               style: .cancel,
                                                               handler: nil)
                                    
                                    
                                    // Add textfield
                                    alert.addTextField(configurationHandler: nil)
                                    alert.addAction(report)
                                    alert.addAction(cancel)
                                    self.delegate?.present(alert, animated: true, completion: nil)
        })
        
        
        
        
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .destructive,
                                   handler: nil)
        
        
        
        
        if self.userObject! == PFUser.current()! {
            // Edit, delete, share to facebook/twitter, and cancel
            options.addAction(delete)
            options.addAction(edit)
            options.addAction(views)
            options.addAction(shareVia)
            options.addAction(cancel)
            options.view.tintColor = UIColor.black
            self.delegate?.present(options, animated: true, completion: nil)
        } else {
            // report, block, share to facebook/twitter, and cancel
            options.addAction(shareVia)
            options.addAction(report)
            options.addAction(cancel)
            options.view.tintColor = UIColor.black
            self.delegate?.present(options, animated: true, completion: nil)
        }
    }
    
    // Function to go to OtherUser
    func goOther() {
        print("\(userObject)")
        
        // Append user's object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpMedia.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    
    
    // Function to share
    func shareOptions() {
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        // TODO:
        // share to FOLLOWERS
        
        let publicShare = UIAlertAction(title: "All Friends",
                                        style: .default,
                                        handler: {(alertAction: UIAlertAction!) in
    
                                            // Share to public ***FRIENDS ONLY***

                                            
                                            // Convert UIImage to NSData
                                            let imageData = UIImageJPEGRepresentation(self.rpMedia.image!, 0.5)
                                            // Change UIImage to PFFile
                                            let parseFile = PFFile(data: imageData!)
                                            
                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                            newsfeeds["byUser"] = PFUser.current()!
                                            newsfeeds["username"] = PFUser.current()!.username!
                                            newsfeeds["textPost"] = "shared @\(self.rpUsername.text!)'s Photo: \(self.caption.text!)"
                                            newsfeeds["photoAsset"] = parseFile
                                            newsfeeds["pointObject"] = photoAssetObject.last!
                                            newsfeeds["contentType"] = "sh"
                                            newsfeeds.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if error == nil {
                                                    print("Successfully shared photo: \(newsfeeds)")
                                                    
                                                    // Send notification
                                                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                    
                                                    // Show alert
                                                    let alert = UIAlertController(title: "Shared With Friends",
                                                                                  message: "Successfully shared \(self.rpUsername.text!)'s Photo.",
                                                        preferredStyle: .alert)
                                                    
                                                    let ok = UIAlertAction(title: "ok",
                                                                           style: .default,
                                                                           handler: {(alertAction: UIAlertAction!) in
                                                                            // Pop view controller
                                                                            self.delegate!.navigationController?.popViewController(animated: true)
                                                    })
                                                    
                                                    alert.addAction(ok)
                                                    self.delegate?.present(alert, animated: true, completion: nil)
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
        })
        
        let privateShare = UIAlertAction(title: "One Friend",
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
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    
    
    
    // Function to view comments
    @IBAction func comments(_ sender: AnyObject) {
        // Append object
        commentsObject.append(self.contentObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    
    
    
    
    // Function to like content
    func like(sender: UIButton) {
        
        // Re-enable buttons
        self.likeButton.isUserInteractionEnabled = false
        self.likeButton.isEnabled = false
        
        if self.likeButton.title(for: .normal) == "liked" {
            
            // UNLIKE
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: photoAssetObject.last!.objectId!)
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
                                NotificationCenter.default.post(name: photoNotification, object: nil)
                                
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
                                notifications.whereKey("forObjectId", equalTo: photoAssetObject.last!.objectId!)
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
            likes["toUser"] = photoAssetObject.last!.value(forKey: "byUser") as! PFUser
            likes["to"] = self.rpUsername.text!
            likes["forObjectId"] = photoAssetObject.last!.objectId!
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
                    NotificationCenter.default.post(name: photoNotification, object: nil)
                    
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
                    notifications["toUser"] = photoAssetObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["forObjectId"] = photoAssetObject.last!.objectId!
                    notifications["type"] = "like pv"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
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
        likeObject.append(self.contentObject!)
        
        // Push VC
        let likesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "likersVC") as! Likers
        self.delegate?.navigationController?.pushViewController(likesVC, animated: true)
    }
    

    
    // Function to show number of sharers
    func showSharers() {
        // Append object
        shareObject.append(self.contentObject!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(sharesVC, animated: true)
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Add tap to go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        userTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(userTap)
        
        // (2) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpMedia.isUserInteractionEnabled = true
        self.rpMedia.addGestureRecognizer(zoomTap)
        
        
        // (3) Add direct share tap
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        
        // (4) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        
        // (5) Add like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        
        // (6) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        
        // (7) Add numberOfShares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showSharers))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
