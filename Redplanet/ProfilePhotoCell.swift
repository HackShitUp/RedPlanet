//
//  ProfilePhotoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/1/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage

class ProfilePhotoCell: UITableViewCell {
    
    // Initialie PFObject to bind data
    var postObject: PFObject?
    // StoryScrollCell's "parentDelegate"
    var superDelegate: UIViewController?
    // Array to hold likes
    var likes = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var largeProPic: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    
    // Function to go to user's profile
    func visitProfile(sender: UIButton) {
        otherObject.append(self.postObject?.value(forKey: "byUser") as! PFUser)
        otherName.append(self.postObject?.value(forKey: "username") as! String)
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }

    
    // Function to update view
    func updateView(postObject: PFObject?) {
        // (1) Get user's object
        if let user = postObject?.value(forKey: "byUser") as? PFUser {
            // Set username
            self.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
            // Set profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPHelpers
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                // MARK: - SDWebImage
                self.largeProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPHelpers
                self.largeProPic.makeCircular(forView: self.largeProPic, borderWidth: 3.50, borderColor: UIColor.darkGray)
            }
        }
        
        // (2) Set textPost
        if let textPost = postObject?.value(forKey: "textPost") as? String {
            self.textPost.text = textPost
        }
        
        // (3) Set time
        let from = postObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        self.time.text = "Updated their profile photo \(difference.getFullTime(difference: difference, date: from))"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add Profile Tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
    }

}
