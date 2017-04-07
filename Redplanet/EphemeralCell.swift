//
//  EphemeralCell.swift
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

import SVProgressHUD

class EphemeralCell: UITableViewCell {
    
    // Instantiate delegate
    var delegate: UINavigationController?
    
    // Instantiate user's object
    var userObject: PFObject?
    
    // Instantiate post object
    var postObject: PFObject?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var iconicPreview: PFImageView!
    
    // Function to view post
    func viewPost() {
        // Save post
        let views = PFObject(className: "Views")
        views["byUser"] = PFUser.current()!
        views["username"] = PFUser.current()!.username!
        views["forObjectId"] = self.postObject!.objectId!
        views.saveInBackground()
        
        if self.postObject!.value(forKey: "contentType") as! String == "itm" {
        // MOMENT
            // Append content object
            itmObject.append(self.postObject!)
            
            // PHOTO
            if self.postObject!.value(forKey: "photoAsset") != nil {
                // Push VC
                let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                self.delegate?.radialPushViewController(itmVC, withStartFrame: CGRect(x: CGFloat(self.contentView.frame.size.width), y: CGFloat(0), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {
                })
            } else {
            // VIDEO
                // Push VC
                let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                self.delegate?.radialPushViewController(momentVideoVC, withStartFrame: CGRect(x: CGFloat(self.contentView.frame.size.width), y: CGFloat(0), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {
                })
            }
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sh" {
        // SHARED POST
            // Append object
            sharedObject.append(self.postObject!)
            // Push VC
            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
            self.delegate?.radialPushViewController(sharedPostVC, withStartFrame: CGRect(x: CGFloat(self.contentView.frame.size.width), y: CGFloat(0), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {
            })
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sp" {
        // SPACE POST
            // Append object
            spaceObject.append(self.postObject!)
            otherObject.append(self.postObject!.value(forKey: "toUser") as! PFUser)
            otherName.append(self.postObject!.value(forKey: "toUsername") as! String)
            // Push VC
            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
            self.delegate?.radialPushViewController(spacePostVC, withStartFrame: CGRect(x: CGFloat(self.contentView.frame.size.width), y: CGFloat(0), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {
            })
        }
    }
    
    // Func options
    func doMore() {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: nil)
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
            viewsObject.append(self.postObject!)
            // Push VC
            let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            self.delegate?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) DELETE
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
//            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 15))
            SVProgressHUD.show()
            
            // Delete shared and original post
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
                        if error == nil {
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
 
        // Show options if post belongs to current user
        if self.userObject!.objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(delete)
            dialogController.show(in: self.delegate!)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPost))
        tap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(tap)
        
        // Let holdOptions
        let holdOptions = UILongPressGestureRecognizer(target: self, action: #selector(doMore))
        holdOptions.minimumPressDuration = 0.40
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(holdOptions)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
