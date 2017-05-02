//
//  NewsFeedCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import Parse
import ParseUI
import Bolts

class NewsFeedCell: UITableViewCell {
    
    // Parent VC
    var delegate: UIViewController?
    
    // PFObject
    var postObject: PFObject?

    @IBOutlet weak var textPreview: UILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // Function to show stories
    func showStories() {
        // Save to Views
//        let views = PFObject(className: "Views")
//        views["byUser"] = PFUser.current()!
//        views["username"] = PFUser.current()!.username!
//        views["forObjectId"] = self.postObject!.objectId!
//        views.saveInBackground()
        
        // Append object
        storyObjects.append(self.postObject!)
        
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let storiesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storiesVC") as! Stories
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storiesVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true)
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
        
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
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
            viewsVC.view.backgroundColor = UIColor.white
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
                                    // MARK: - RPHelpers
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.showSuccess(withTitle: "Deleted")
                                    
                                    // Send FriendsNewsfeeds Notification
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                    // Send MyProfile Notification
                                    NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                    
                                    // Pop view controller
                                    _ = self.delegate?.navigationController?.popViewController(animated: true)
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - RPHelpers
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.showError(withTitle: "Network Error")
                                }
                            })
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showError(withTitle: "Network Error")
                        }
                    })
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        })
        
        // Show options if post belongs to current user
        if (self.postObject!.value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            dialogController.addAction(views)
            dialogController.addAction(delete)
            dialogController.show(in: self.delegate!)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add tap method to viewStory
        let storyTap = UITapGestureRecognizer(target: self, action: #selector(showStories))
        storyTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(storyTap)
        
        // Let holdOptions
        let holdOptions = UILongPressGestureRecognizer(target: self, action: #selector(doMore))
        holdOptions.minimumPressDuration = 0.40
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(holdOptions)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
