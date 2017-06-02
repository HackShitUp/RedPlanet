//
//  PhotoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import KILabel
import SDWebImage


/*
 MARK: - THIS CLASS RELATES TO POSTS SHARED ON REDPLANET
 UITableViewCell that presents a photo shared by a user.
 
 • Refers to "ph" in the database class, "Posts", with a definitive value in <photoAsset> handled as a File value (PFFile).
 
 PARENT CLASS IS ALWAYS "StoryScrollCell.swift"
 */

class PhotoCell: UITableViewCell {

    // PFObject; used to determine post type
    var postObject: PFObject?
    // Parent UIViewController
    var superDelegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var photo: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    // FUNCTION - Zoom into photo
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.photo.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.superDelegate!.self)
    }
    
    // FUNCTION - Navigates to user's profile
    func visitProfile(sender: AnyObject) {
        if let user = self.postObject!.object(forKey: "byUser") as? PFUser {
            otherObject.append(user)
            otherName.append(user.value(forKey: "username") as! String)
        }
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Bind data to update UI
    func updateView(withObject: PFObject?) {
        // (1) Get user's object
        if let user = withObject!.object(forKey: "byUser") as? PFUser {
            // Get realNameOfUser
            self.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
            // Set profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPExtensions
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            }
        }
        
        // (2) Set text post
        if let text = withObject!.value(forKey: "textPost") as? String {
            // MARK: - RPExtensions
            let formattedString = NSMutableAttributedString()
            _ = formattedString.bold("\((withObject!.object(forKey: "byUser") as! PFUser).username!) ", withFont: UIFont(name: "AvenirNext-Demibold", size: 15)).normal("\(text)", withFont: UIFont(name: "AvenirNext-Medium", size: 15))
            if withObject!.value(forKey: "textPost") as! String != "" {
                self.textPost.attributedText = formattedString
            } else {
                self.textPost.isHidden = true
            }
        }
        
        // (3) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set photo
        if let image = withObject!.value(forKey: "photoAsset") as? PFFile {
            self.photo.autoresizingMask = .flexibleBottomMargin
            self.photo.autoresizingMask = .flexibleHeight
            self.photo.contentMode = .scaleAspectFit
            
            // MARK: - SDWebImage
            self.photo.sd_addActivityIndicator()
            self.photo.sd_setIndicatorStyle(.gray)
            self.photo.sd_setImage(with: URL(string: image.url!)!)
        }
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
        
        // Zoom tap
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.photo.isUserInteractionEnabled = true
        self.photo.addGestureRecognizer(zoomTap)
    }
}
