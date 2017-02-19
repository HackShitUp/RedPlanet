//
//  SpacePostCell.swift
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
import OneSignal
import SVProgressHUD
import SimpleAlert

class SpacePostCell: UITableViewCell {
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    // Set byUser's object
    var byUserObject: PFObject?
    
    // Set toUser's Object
    var toUserObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var textPost: KILabel!
    
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var mediaAsset: PFImageView!

    
    
    @IBAction func comment(_ sender: Any) {
        // Append object
        commentsObject.append(spaceObject.last!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    
    // Function to go to OtherUser
    func goOther() {
        // Append user's object
        otherObject.append(self.byUserObject!)
        // Append username
        otherName.append(self.rpUsername.text!.lowercased())
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    

    
    // Function to show number of likes
    func showLikes(seder: UIButton) {
        // Append object
        likeObject.append(spaceObject.last!)
        
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
            likes.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
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
                                notifications.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
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
                                NotificationCenter.default.post(name: spaceNotification, object: nil)
                                
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
            likes["toUser"] = self.toUserObject!
            likes["to"] = spaceObject.last!.value(forKey: "username") as! String
            likes["forObjectId"] = spaceObject.last!.objectId!
            likes.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved like \(likes)")
                    
                    
                    // Save to notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["to"] = spaceObject.last!.value(forKey: "username") as! String
                    notifications["toUser"] = self.toUserObject!
                    notifications["forObjectId"] = spaceObject.last!.objectId!
                    notifications["type"] = "like sp"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            // MARK: - OneSignal
                            // Send push notification
                            if self.toUserObject!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) liked your Space Post"],
                                     "include_player_ids": ["\(self.toUserObject!.value(forKey: "apnsId") as! String)"],
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
                    NotificationCenter.default.post(name: spaceNotification, object: nil)
                    
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
    
    
    
    
    
    // Function to show number of shares
    func showShares() {
        // Append object
        shareObject.append(spaceObject.last!)
        
        // Push VC
        let sharesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharesVC") as! Shares
        self.delegate?.navigationController?.pushViewController(sharesVC, animated: true)
    }
    
    
    
    
    // Function to share
    func shareOptions() {
        // Append to contentObject
        shareObject.append(spaceObject.last!)
        
        // Share to chats
        let shareToVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "shareToVC") as! ShareTo
        self.delegate?.navigationController?.pushViewController(shareToVC, animated: true)
    }

    
    
    // Save or share the photo
    func saveShare(sender: UILongPressGestureRecognizer) {
        if spaceObject.last!.value(forKey: "photoAsset") != nil {
            // Photo to Share
            let image = self.mediaAsset.image!
            let imageToShare = [image]
            let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            self.delegate?.present(activityVC, animated: true, completion: nil)

        } else {
            // Text to Share
            let textToShare = "@\(self.rpUsername.text!) Space Post on Redplanet: \(self.textPost.text!)\nhttps://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8"
            let objectsToShare = [textToShare]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.delegate?.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    // Function to play video
    func playVideo() {
        
        // Fetch video data
        if let video = spaceObject.last!.value(forKey: "videoAsset") as? PFFile {
            // Traverse video url
            let videoUrl = NSURL(string: video.url!)
            // MARK: - Periscope Video View Controller
            let videoViewController = VideoViewController(videoURL: videoUrl as! URL)
            self.delegate?.present(videoViewController, animated: true, completion: nil)
        }
    }
    
    
    // Function to layout taps
    func layoutTaps() {
        if spaceObject.last!.value(forKey: "photoAsset") != nil {
            
            // Hold to save
            let mediaHold = UILongPressGestureRecognizer(target: self, action: #selector(saveShare))
            mediaHold.minimumPressDuration = 0.50
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(mediaHold)
            
            // Tap to zoom
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(zoomTap)
            
        } else if spaceObject.last!.value(forKey: "videoAsset") != nil {
            
            // Play video tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(playTap)
            
            
        }
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
        let views = AlertAction(title: "🙈 Views 🙈",
                                style: .default,
                                handler: { (AlertAction) in
                                    // Append object
                                    viewsObject.append(spaceObject.last!)
                                    
                                    // Push VC
                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        
        // (2) Edit
        let edit = AlertAction(title: "🔩 Edit 🔩",
                               style: .default,
                               handler: { (AlertAction) in
                                // Append object
                                editObjects.append(spaceObject.last!)
                                
                                // Push VC
                                let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                self.delegate?.navigationController?.pushViewController(editVC, animated: true)
        })
        
        
        // (3) Save post
        let save = AlertAction(title: "Save Post",
                               style: .default,
                               handler: { (AlertAction) in
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.show(withStatus: "Saving")
                                
                                // Save Post
                                let newsfeeds = PFQuery(className: "Newsfeeds")
                                newsfeeds.getObjectInBackground(withId: spaceObject.last!.objectId!, block: {
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
        
        
        // (4) Delete for byUser
        let delete1 = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                            
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                    SVProgressHUD.show(withStatus: "Deleting")
                                    
                                        // Set content
                                        let content = PFQuery(className: "Newsfeeds")
                                        content.whereKey("byUser", equalTo: PFUser.current()!)
                                        content.whereKey("objectId", equalTo: spaceObject.last!.objectId!)
                                            
                                        let shares = PFQuery(className: "Newsfeeds")
                                        shares.whereKey("pointObject", equalTo: spaceObject.last!)
                                            
                                        let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                        newsfeeds.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                // Delete all objects
                                                PFObject.deleteAll(inBackground: objects, block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {

                                                        // MARK: - SVProgressHUD
                                                        SVProgressHUD.showSuccess(withStatus: "Deleted")
                                                        
                                                        // Reload data
                                                        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"),object: nil)
                                                        NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                        NotificationCenter.default.post(name: otherNotification, object: nil)
                                                        
                                                        // Pop view controller
                                                        _ = self.delegate?.navigationController?.popViewController(animated: true)
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

        // (5) Delete for toUser
        let delete2 = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            
                                            // Set content
                                            let content = PFQuery(className: "Newsfeeds")
                                            content.whereKey("toUser", equalTo: PFUser.current()!)
                                            content.whereKey("objectId", equalTo: spaceObject.last!.objectId!)
                                            
                                            let shares = PFQuery(className: "Newsfeeds")
                                            shares.whereKey("pointObject", equalTo: spaceObject.last!)
                                            
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
                                                                NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                                NotificationCenter.default.post(name: otherNotification, object: nil)
                                                                
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

        // (6) Report Content
        let report = AlertAction(title: "Report",
                                      style: .destructive,
                                      handler: { (AlertAction) in
                                        let alert = UIAlertController(title: "Report",
                                                                      message: "Please provide your reason for reporting \(spaceObject.last!.value(forKey: "username") as! String)'s Space Post",
                                            preferredStyle: .alert)
                                        
                                        let report = UIAlertAction(title: "Report", style: .destructive) {
                                            [unowned self, alert] (action: UIAlertAction!) in
                                            
                                            let answer = alert.textFields![0]
                                            
                                            // Save to <Block_Reported>
                                            let report = PFObject(className: "Block_Reported")
                                            report["from"] = PFUser.current()!.username!
                                            report["fromUser"] = PFUser.current()!
                                            report["to"] = spaceObject.last!.value(forKey: "username") as! String
                                            report["toUser"] = spaceObject.last!.value(forKey: "byUser") as! PFUser
                                            report["forObjectId"] = spaceObject.last!.objectId!
                                            report["type"] = answer.text!
                                            report.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved report: \(report)")
                                                    
                                                    // Dismiss
                                                    let alert = UIAlertController(title: "Successfully Reported",
                                                                                  message: "\(spaceObject.last!.value(forKey: "username") as! String)'s Space Post",
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
        
        
        // (7) Cancel
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        // Return options
        if (spaceObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            options.addAction(views)
            options.addAction(edit)
            options.addAction(save)
            options.addAction(delete1)
            options.addAction(cancel)
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            edit.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            edit.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            save.button.setTitleColor(UIColor.black, for: .normal)
            delete1.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete1.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else if (spaceObject.last!.value(forKey: "toUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            options.addAction(views)
            options.addAction(save)
            options.addAction(delete2)
            options.addAction(cancel)
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            save.button.setTitleColor(UIColor.black, for: .normal)
            delete2.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete2.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        } else {
            options.addAction(report)
            options.addAction(cancel)
            report.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            report.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
        }
        
        self.delegate?.present(options, animated: true, completion: nil)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Design corner radius
        if mediaAsset != nil {
            self.mediaAsset.layer.cornerRadius = 5.00
            self.mediaAsset.clipsToBounds = true
        }
        
        // (1) Add user's profile photo tap to go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        userTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(userTap)
        
        // (2) Add username tap to go to user's profile
        let usernameTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        usernameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(usernameTap)
        
        // (3) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comment))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        // (7) Add numberOfLikes tap
        let numLikesTap = UITapGestureRecognizer(target: self, action: #selector(showLikes))
        numLikesTap.numberOfTapsRequired = 1
        self.numberOfLikes.isUserInteractionEnabled = true
        self.numberOfLikes.addGestureRecognizer(numLikesTap)
        
        // (4) Add like button tap
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
        
        // (5) Add numberOfShares tap
        let numSharesTap = UITapGestureRecognizer(target: self, action: #selector(showShares))
        numSharesTap.numberOfTapsRequired = 1
        self.numberOfShares.isUserInteractionEnabled = true
        self.numberOfShares.addGestureRecognizer(numSharesTap)
        
        // (6) Share options tap
        let dmTap = UITapGestureRecognizer(target: self, action: #selector(shareOptions))
        dmTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(dmTap)
        
        // (7) Add method to textPost
        let tpHold = UILongPressGestureRecognizer(target: self, action: #selector(saveShare))
        tpHold.minimumPressDuration = 0.50
        self.textPost.isUserInteractionEnabled = true
        self.textPost.addGestureRecognizer(tpHold)
        
        // (8) More tap
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
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
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
            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
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
