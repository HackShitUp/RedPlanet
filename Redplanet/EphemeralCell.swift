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
        
        
        
        // MARK: - RPPopUpViewController
        let rpPopUpVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rpPopUpVC") as! RPPopUpVC
        let navigator = UINavigationController(rootViewController: rpPopUpVC)
        
        navigator.view.backgroundColor = UIColor.clear
        
        // Determine post type
        if self.postObject!.value(forKey: "contentType") as! String == "itm" {
        // MOMENT
            // Append postObject (PFObject)
            itmObject.append(self.postObject!)
            
            // PHOTO
            if self.postObject!.value(forKey: "photoAsset") != nil {
                // Present VC
                let itmVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: itmVC)
                self.delegate?.present(navigator, animated: false, completion: nil)
                
            } else {
            // VIDEO
                // Present VC
                let momentVideoVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "momentVideoVC") as! MomentVideo
                rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: momentVideoVC)
                self.delegate?.present(navigator, animated: false, completion: nil)
            }
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sh" {
        // SHARED POST
            // Append object
            sharedObject.append(self.postObject!)
            // Present VC
            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
//            sharedPostVC.delegate = rpPopUpVC
//            rpPopUpVC.configureView(vc: rpPopUpVC, popOverVC: sharedPostVC)
//            self.delegate?.present(navigator, animated: false, completion: nil)
            _ = self.delegate?.pushViewController(sharedPostVC, animated: true)
            
        } else if self.postObject!.value(forKey: "contentType") as! String == "sp" {
        // SPACE POST
            // Append object
            spaceObject.append(self.postObject!)
            otherObject.append(self.postObject!.value(forKey: "toUser") as! PFUser)
            otherName.append(self.postObject!.value(forKey: "toUsername") as! String)
            // Push VC
            let spacePostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
            // TODO: POPVC
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
        
        // MARK: - RPPopUpViewController
        let rpPopUpVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rpPopUpVC") as! RPPopUpVC
        let navigator = UINavigationController(rootViewController: rpPopUpVC)
        
        // (1) VIEWS
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Append object
            viewsObject.append(self.postObject!)
            
            let viewsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
//            viewsVC.delegate = rpPopUpVC
//            rpPopUpVC.configureView(vc: rpPopUpVC, popOverVC: viewsVC)
//            self.delegate?.present(navigator, animated: true, completion: nil)
            
            
            
            // Create the MantleViewController from the Storyboard using the
//            let mantleViewController = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "vc") as! RCMantleViewController
            // Create your modal controller with your storyboard ID
            //            let popUpViewController = storyboard!.instantiateViewController(withIdentifier: "PopUpViewController") as! PopUpViewController
            // Set it's delegate to be able to call 'delegate.dismissView(animated: Bool)'
//            viewsVC.delegate = rpPopUpVC as! RPPopUpVCDelegate
            
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewsVC)
            // Present the modal through the MantleViewController
//            self.delegate?.present(navigator, animated: false, completion: nil)
            rpPopUpVC.draggableToSides = false
            self.delegate?.present(rpPopUpVC, animated: false, completion: nil)
        })
        
        // (2) DELETE
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
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
                                    SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
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
}
