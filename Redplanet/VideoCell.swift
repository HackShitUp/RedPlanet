//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import KILabel
import SDWebImage

class VideoCell: UITableViewCell {
    
    // Initialie PFObject to bind data
    var postObject: PFObject?
    // StoryScrollCell's "parentDelegate"
    var superDelegate: UIViewController?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var videoPreview: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    // FUNCTION - Navigate to user's profile
    func visitProfile(sender: AnyObject) {
        otherObject.append(self.postObject?.value(forKey: "byUser") as! PFUser)
        otherName.append(self.postObject?.value(forKey: "username") as! String)
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Binds data to update UI
    func updateView(withObject: PFObject?) {
        // (1) Get user's object
        if let user = withObject!.value(forKey: "byUser") as? PFUser {
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
        
        // (2) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPExtensions
        time.text = difference.getFullTime(difference: difference, date: from)
        
        // (3) Set text post
        if let text = withObject!.value(forKey: "textPost") as? String {
            // Manipulate font size and color depending on character count
            if text.characters.count < 140 {
                self.textPost.font = UIFont(name: "AvenirNext-Bold", size: 23)
                // MARK: - RPExtensions
                self.textPost.textColor = UIColor.randomColor()
            } else {
                self.textPost.font = UIFont(name: "AvenirNext-Medium", size: 17)
                self.textPost.textColor = UIColor.black
            }
            self.textPost.text = text
            
            /*
             for var word in text.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
             // @'s
             if word.hasPrefix("http") {
             //                    let apiEndpoint: String = "http://tinyurl.com/api-create.php?url=\(word)"
             //                    let shortURL = try? String(contentsOf: URL(string: apiEndpoint)!, encoding: String.Encoding.ascii)
             // Replace text
             Readability.parse(url: URL(string: word)!, completion: { (data) in
             let title = data?.title
             let description = data?.description
             let keywords = data?.keywords
             let imageUrl = data?.topImage
             let videoUrl = data?.topVideo
             print(title)
             })
             }
             }
            */
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
        
        // MARK: - KILabel; @, #, and https://
        // @@@
        self.textPost.userHandleLinkTapHandler = { label, handle, range in
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: String(handle.characters.dropFirst()).lowercased())
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append data
                        otherName.append(String(handle.characters.dropFirst()).lowercased())
                        otherObject.append(object)
                        // Push VC
                        let otherUser = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.superDelegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        self.textPost.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.superDelegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
