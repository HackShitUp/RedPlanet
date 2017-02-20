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

import SimpleAlert
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
        views.saveEventually()
        
        if self.postObject!.value(forKey: "contentType") as! String == "itm" {
        // MOMENT
            // Append content object
            itmObject.append(self.postObject!)
            
            // PHOTO
            if self.postObject!.value(forKey: "photoAsset") != nil {
                // Push VC
                let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                self.delegate?.pushViewController(itmVC, animated: true)
            } else {
            // VIDEO
                // Push VC
                let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                self.delegate?.pushViewController(momentVideoVC, animated: true)
            }
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sh" {
        // SHARED POST
            
            // Append object
            sharedObject.append(self.postObject!)
            // Push VC
            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
            self.delegate?.pushViewController(sharedPostVC, animated: true)
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sp" {
        // SPACE POST
            
            // Append object
            spaceObject.append(self.postObject!)
            
            // Append otherObject
            otherObject.append(self.postObject!.value(forKey: "toUser") as! PFUser)
            
            // Append otherName
            otherName.append(self.postObject!.value(forKey: "toUsername") as! String)
            
            // Push VC
            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
            self.delegate?.pushViewController(spacePostVC, animated: true)
        }
    }
    
    // Func options
    func doMore() {
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
        
        let views = AlertAction(title: "🙈 Views 🙈",
                                style: .default,
                                handler: { (AlertAction) in
                                    
                                    // Append object
                                    viewsObject.append(self.postObject!)
                                    
                                    // Push VC
                                    let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                    self.delegate?.pushViewController(viewsVC, animated: true)
        })
        
        let share = AlertAction(title: "Share Via",
                               style: .default,
                               handler: { (AlertAction) in
                                
        })
        
        let delete = AlertAction(title: "Delete",
                                 style: .destructive,
                                 handler: { (AlertAction) in
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.setBackgroundColor(UIColor.white)
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
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
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        if self.userObject!.objectId! == PFUser.current()!.objectId! {
            options.addAction(views)
            options.addAction(share)
            options.addAction(delete)
            options.addAction(cancel)
            
            for b in options.actions {
                b.button.frame.size.height = 50
            }
            views.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            views.button.setTitleColor(UIColor.black, for: .normal)
            share.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            share.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha: 1.0), for: .normal)
            delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha: 1.0), for: .normal)
            cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
            cancel.button.setTitleColor(UIColor.black, for: .normal)
            self.delegate?.present(options, animated: true, completion: nil)
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
