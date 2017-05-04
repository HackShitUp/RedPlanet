//
//  MomentPhoto.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage

class MomentPhoto: UICollectionViewCell {
    
    @IBOutlet weak var photoMoment: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    
    
    // Function to do more
    func doMore(sender: UIButton) {
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
        
        
        // (1) Views
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            
        })
        
//        // (2) Delete
//        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
//            // Dismiss
//            dialog.dismiss()
//            // MARK: - RPHelpers
//            let rpHelpers = RPHelpers()
//            rpHelpers.showProgress(withTitle: "Deleting Text Post...")
//            // Delete from Newsfeeds
//            let newsfeeds = PFQuery(className: "Newsfeeds")
//            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
//            newsfeeds.whereKey("objectId", equalTo: self.postObject!)
//            newsfeeds.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
//                if error == nil {
//                    for object in objects! {
//                        object.deleteInBackground()
//                        // MARK: - RPHelpers
//                        let rpHelpers = RPHelpers()
//                        rpHelpers.showSuccess(withTitle: "Deleted Text Post")
//                    }
//                } else {
//                    print(error?.localizedDescription as Any)
//                    // MARK: - RPHelpers
//                    let rpHelpers = RPHelpers()
//                    rpHelpers.showError(withTitle: "Failed to Deleted Text Post")
//                }
//            })
//        })
//        
//        // (3) Report
//        let report = AZDialogAction(title: "Report", handler: { (dialog) -> Void in
//            // Dismiss
//            dialog.dismiss()
//        })
//        
//        // Show options depending on user
//        if (self.postObject!.value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
//            dialogController.addAction(views)
//            dialogController.addAction(delete)
//            dialogController.show(in: self.superDelegate!)
//        } else {
//            dialogController.addAction(report)
//            dialogController.show(in: self.superDelegate!)
//        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Apply shadows
        self.rpUsername.layer.applyShadow(layer: self.rpUsername.layer)
        self.time.layer.applyShadow(layer: self.time.layer)
        self.moreButton.layer.applyShadow(layer: self.moreButton.layer)
    }

}
