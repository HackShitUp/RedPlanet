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
    
    
    // Initialized PFObject
    var postObject: PFObject?
    // Initialized parent UIViewController
    var delegate: UIViewController?
    
    @IBOutlet weak var photoMoment: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    
    
    // FUNCTION - Navigates to user's profile
    func visitProfile(sender: AnyObject) {
        if let user = self.postObject!.object(forKey: "byUser") as? PFUser {
            otherObject.append(user)
            otherName.append(user.value(forKey: "username") as! String)
        }
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }

    // Function to update UI
    func updateView(withObject: PFObject?) {
        // (1) Get and set user's object
        if let user = withObject!.object(forKey: "byUser") as? PFUser {
            // Set name
            self.rpUsername.setTitle("\(user.value(forKey: "realNameOfUser") as! String)", for: .normal)
        }
        
        // (2) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        time.text = difference.getFullTime(difference: difference, date: from)
        
        // (3) Set Photo
        if let photo = withObject!.value(forKey: "photoAsset") as? PFFile {
            // MARK: - SDWebImage
            photoMoment.sd_addActivityIndicator()
            photoMoment.sd_setIndicatorStyle(.gray)
            photoMoment.sd_setImage(with: URL(string: photo.url!)!)
        }
        
        // (4) Bring name/time to front and add subview
        self.contentView.bringSubview(toFront: self.rpUsername)
        self.contentView.bringSubview(toFront: self.time)
        self.rpUsername.layer.applyShadow(layer: self.rpUsername.layer)
        self.time.layer.applyShadow(layer: self.time.layer)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
    }

}
