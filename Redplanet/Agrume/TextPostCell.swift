
//
//  TextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage
import SafariServices
import ReadabilityKit

/*
 MARK: - THIS CLASS RELATES TO POSTS SHARED ON REDPLANET
 UITableViewCell that presents a Text Post shared by a user.
 
 • Refers to "tp" in the database class, "Posts", with a definitive value in <textPost> handled as a String.
 
 PARENT CLASS IS ALWAYS "StoryScrollCell.swift"
 */

class TextPostCell: UITableViewCell {
    
    // Initialized PFObject
    var postObject: PFObject?
    // Initialized parent UIViewController
    var superDelegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var webImage: UIImageView!
    @IBOutlet weak var webTitlePreview: UILabel!
    
    // FUNCTION - Navigates to user's profile
    func visitProfile(sender: AnyObject) {
        if let user = self.postObject!.object(forKey: "byUser") as? PFUser {
            otherObject.append(user)
            otherName.append(user.value(forKey: "username") as! String)
        }
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Binds data to update UI
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
                self.textPost.font = UIFont(name: "AvenirNext-Bold", size: 25)
                // MARK: - RPExtensions
                self.textPost.textColor = UIColor.randomColor()
            } else {
                self.textPost.font = UIFont(name: "AvenirNext-Medium", size: 17)
                self.textPost.textColor = UIColor.black
            }
            self.textPost.text = text
            
            for var word in text.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                // @'s
                if word.hasPrefix("http") {
                    
                    // MARK: - Readability
                    Readability.parse(url: URL(string: word)!, completion: { (data) in
                        
                        // Traverse image URL and hide views if no image exists
                        if let imageURL = data?.topImage {
                            // MARK: - SDWebImage
                            self.webImage.sd_setImage(with: URL(string: imageURL)!)
                            // Set title
                            if let title = data?.title {
                                if let description = data?.description {
                                    self.webTitlePreview.text = "\(title)\n\(description)"
                                }
                            }
                            
                            // MARK: - RPHelpers
                            self.webImage.roundAllCorners(sender: self.webImage)
                            self.webImage.layer.borderColor = UIColor.groupTableViewBackground.cgColor
                            self.webImage.layer.borderWidth = 0.5
                            self.webImage.clipsToBounds = true
                            
                            // Replace word
                            self.textPost.text = text.replacingOccurrences(of: "\(word)", with: "")
                            
                        } else {
                            self.webImage.isHidden = true
                            self.webTitlePreview.isHighlighted = true
                        }
                        
                    })
                }
            }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set frames
        self.contentView.frame = self.frame
        
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
        // https://
        self.textPost.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.superDelegate?.navigationController?.present(webVC, animated: true, completion: nil)
        }
    }
    
}
