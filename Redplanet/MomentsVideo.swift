//
//  MomentsVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SimpleAlert
import SVProgressHUD
import SwipeNavigationController
import OneSignal


class MomentsVideo: UICollectionViewCell {
    
    // Initialize parentVC
    var delegate: UIViewController?
    var postObject: PFObject?
    
    // Initialize player
    var player: Player!
    
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    
    // Query content
    func fetchContent() {
        // (1) Load moment
        if let videoFile = self.postObject!.value(forKey: "videoAsset") as? PFFile {
            
            // VIDEO MOMENT
            let player = AVPlayer(url: URL(string: videoFile.url!)!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.contentView.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.contentView.contentMode = .scaleAspectFit
            self.contentView.layer.addSublayer(playerLayer)
            player.isMuted = false
            player.play()
            
            // Store buttons in an array
            let buttons = [self.likeButton,
                           self.numberOfLikes,
                           self.commentButton,
                           self.numberOfComments,
                           self.shareButton,
                           self.numberOfShares,
                           self.rpUsername,
                           self.time,
                           self.moreButton] as [Any]
            // Add shadows and bring view to front
            for b in buttons {
                (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
                (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
                (b as AnyObject).layer.shadowRadius = 3
                (b as AnyObject).layer.shadowOpacity = 0.6
                self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
            }
        }
        
        // (2) Set username
        if let user = self.postObject!.object(forKey: "byUser") as? PFUser {
            self.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
        }
        
        // (3) Set time
        let from = self.postObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        if difference.second! <= 0 {
            self.time.text = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                self.time.text = "1 second ago"
            } else {
                self.time.text = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                self.time.text = "1 minute ago"
            } else {
                self.time.text = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                self.time.text = "1 hour ago"
            } else {
                self.time.text = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                self.time.text = "1 day ago"
            } else {
                self.time.text = "\(difference.day!) days ago"
            }
            if self.postObject!.value(forKey: "saved") as! Bool == true {
                self.likeButton.isUserInteractionEnabled = false
                self.numberOfLikes.isUserInteractionEnabled = false
                self.commentButton.isUserInteractionEnabled = false
                self.numberOfComments.isUserInteractionEnabled = false
                self.shareButton.isUserInteractionEnabled = false
                self.numberOfShares.isUserInteractionEnabled = false
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            self.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
            if self.postObject!.value(forKey: "saved") as! Bool == true {
                self.likeButton.isUserInteractionEnabled = false
                self.numberOfLikes.isUserInteractionEnabled = false
                self.commentButton.isUserInteractionEnabled = false
                self.numberOfComments.isUserInteractionEnabled = false
                self.shareButton.isUserInteractionEnabled = false
                self.numberOfShares.isUserInteractionEnabled = false
            }
        }
        
        // (4) Fetch likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                // (A) Append objects
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                
                
                // (B) Manipulate likes
                if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
                    // liked
                    self.likeButton.setTitle("liked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "WhiteLikeFilled"), for: .normal)
                } else {
                    // notLiked
                    self.likeButton.setTitle("notLiked", for: .normal)
                    self.likeButton.setImage(UIImage(named: "WhiteLike"), for: .normal)
                }
                
                // (C) Set number of likes
                if self.likes.count == 0 {
                    self.numberOfLikes.setTitle("likes", for: .normal)
                } else if self.likes.count == 1 {
                    self.numberOfLikes.setTitle("1 like", for: .normal)
                } else {
                    self.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        // (5) Fetch comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.comments.removeAll(keepingCapacity: false)
                
                // (A) Append objects
                for object in objects! {
                    self.comments.append(object)
                }
                
                // (B) Set number of comments
                if self.comments.count == 0 {
                    self.numberOfComments.setTitle("comments", for: .normal)
                } else if self.comments.count == 1 {
                    self.numberOfComments.setTitle("1 comment", for: .normal)
                } else {
                    self.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        // (6) Fetch shares
        let shares = PFQuery(className: "Newsfeeds")
        shares.whereKey("contentType", equalTo: "sh")
        shares.whereKey("pointObject", equalTo: self.postObject!)
        shares.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.shares.removeAll(keepingCapacity: false)
                
                // (A) Append objects
                for object in objects! {
                    self.shares.append(object)
                }
                
                // (B) Set number of shares
                if self.shares.count == 0 {
                    self.numberOfShares.setTitle("shares", for: .normal)
                } else if self.shares.count == 1 {
                    self.numberOfShares.setTitle("1 share", for: .normal)
                } else {
                    self.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }// end fetchContent
    
    
    // Functiont to go back
    func goBack(sender: UIGestureRecognizer) {
        // Remove last objects
//        itmObject.removeLast()
        // POP VC
        self.delegate?.navigationController?.radialPopViewController(withDuration: 0.2, withStartFrame: CGRect(x: CGFloat((self.delegate?.view.frame.size.width)!/2), y: CGFloat((self.delegate?.view.frame.size.height)!), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {() -> Void in
        })
    }
    
    
    // Function to go to user's profile
    func goUser(sender: UIButton) {
        // Append otherObject
        otherObject.append(self.postObject!.value(forKey: "byUser") as! PFUser)
        // Append otherName
        otherName.append(self.rpUsername.titleLabel!.text!)
        
        // Push VC
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    
    // Function to shareVia
    func shareVia() {
        // INSTANCEVIDEODATA
        let textToShare = "@\(PFUser.current()!.username!)'s Video on Redplanet.\nhttps://redplanetapp.com/download/"
        let url = URL(string: (self.postObject!.value(forKey: "videoAsset") as! PFFile).url!)
        let videoData = NSData(contentsOf: url!)
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docDirectory = paths[0]
        let filePath = "\(docDirectory)/tmpVideo.mov"
        videoData?.write(toFile: filePath, atomically: true)
        let videoLink = NSURL(fileURLWithPath: filePath)
        let objectsToShare = [textToShare, videoLink] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.setValue("Video", forKey: "subject")
        self.delegate?.present(activityVC, animated: true, completion: nil)
    }
    
    
    // Function to show options
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
        
        let views = AlertAction(title: "Views",
                                style: .default,
                                handler: { (AlertAction) in
                                    // Append object
                                    viewsObject.append(self.postObject!)
                                    // Push VC
                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.delegate?.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        let save = AlertAction(title: "Save",
                               style: .default,
                               handler: { (AlertAction) in
                                // MARK: - SVProgressHUD
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                SVProgressHUD.setForegroundColor(UIColor.black)
                                SVProgressHUD.show(withStatus: "Saving")
                                
                                // Shared and og content
                                let newsfeeds = PFQuery(className: "Newsfeeds")
                                newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
                                newsfeeds.whereKey("objectId", equalTo: self.postObject!.objectId!)
                                newsfeeds.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            object["saved"] = true
                                            object.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.showSuccess(withStatus: "Saved")
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
        
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                    SVProgressHUD.show(withStatus: "Deleting")
                                    
                                    // Shared and og content
                                    let content = PFQuery(className: "Newsfeeds")
                                    content.whereKey("byUser", equalTo: PFUser.current()!)
                                    content.whereKey("objectId", equalTo: self.postObject!.objectId!)
                                    
                                    let shares = PFQuery(className: "Newsfeeds")
                                    shares.whereKey("pointObject", equalTo: self.postObject!)
                                    
                                    let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                    newsfeeds.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            // Delete all objects
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
                                                            
                                                            // Send FriendsNewsfeeds Notification
                                                            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                                            
                                                            // Send MyProfile Notification
                                                            NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                            
                                                            // Pop VC
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
                                            
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.showError(withStatus: "Error")
                                        }
                                    })
        })
        
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        
        
        options.addAction(views)
        options.addAction(save)
        options.addAction(delete)
        options.addAction(cancel)
        views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17)
        views.button.setTitleColor(UIColor.black, for: .normal)
        save.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17)
        save.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0), for: .normal)
        delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17)
        delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.delegate?.present(options, animated: true, completion: nil)
    }

    
    
    func configureMoment() {
        // MARK: - SwipeNavigationController
//        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
        
        // MARK: - RadialTransitionSwipe
        self.delegate?.navigationController?.enableRadialSwipe()
        
        // Tap to Pop VC
        let tapOut = UITapGestureRecognizer(target: self, action: #selector(goBack))
        tapOut.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(tapOut)
        
        // Username tap
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        
        // More button tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(showMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
        // Long press to share
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(shareVia))
        longTap.minimumPressDuration = 0.15
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(longTap)
    }
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
