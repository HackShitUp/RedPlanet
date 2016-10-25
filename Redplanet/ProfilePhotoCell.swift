//
//  ProfilePhotoCell.swift
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

class ProfilePhotoCell: UITableViewCell {
    
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    // Fetch profile photo
    func fetchProPic() {
        // Get user's profile photo
        let proPic = PFQuery(className: "ProfilePhoto")
        proPic.whereKey("fromUser", equalTo: otherObject.last!)
        proPic.order(byDescending: "createdAt")
        proPic.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (A) Get profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            self.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription)
                            // Set default
                            self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                } else {
                    // Set default
                    self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                }
                
                // (B) Set caption
                self.caption.text! = object!["proPicCaption"] as! String
                
                // (C) Set username
                self.rpUsername.text! = otherObject.last!.value(forKey: "realNameOfUser") as! String
                
                
                // (D) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    self.time.text = "now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    self.time.text = "\(difference.second!) seconds ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    self.time.text = "\(difference.minute!) minutes ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    self.time.text = "\(difference.hour!) hours ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    self.time.text = "\(difference.day!) days ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    self.time.text = "\(difference.weekOfMonth!) weeks ago"
                }
                
                
                
                // Post notification
                NotificationCenter.default.post(name: profileNotification, object: nil)
                
                
            } else {
                print(error?.localizedDescription)
            }
            
        }
    }
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Fetch Profile Photo
        fetchProPic()

        // Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
