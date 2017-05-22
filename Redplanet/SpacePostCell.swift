//
//  SpacePostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/22/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage

class SpacePostCell: UITableViewCell {
    
    // Initialized PFObject
    var postObject: PFObject?
    // Initialized parent UIViewController
    var superDelegate: UIViewController?
    
    @IBOutlet weak var byUserProPic: PFImageView!
    @IBOutlet weak var byUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var toUserProPic: PFImageView!
    @IBOutlet weak var toUsername: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    
    // FUNCTION - Navigates to sender's profile
    func visitProfile(sender: AnyObject) {
        // Traverse user's object
        if let byUser = self.postObject?.value(forKey: "byUser") as? PFUser {
            otherObject.append(byUser)
            otherName.append(byUser.username!)
        } else if let toUser = self.postObject?.value(forKey: "toUser") as? PFUser {
            otherObject.append(toUser)
            otherName.append(toUser.username!)
        }
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject?) {
        
        // MARK: - RPExtensions
        self.byUserProPic.makeCircular(forView: self.byUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        self.toUserProPic.makeCircular(forView: self.toUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Get byUser's object
        if let byUser = withObject?.value(forKey: "byUser") as? PFUser {
            // Get and set proPic
            if let proPic = byUser.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.byUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // Set fullName
            self.byUsername.text = (byUser.value(forKey: "realNameOfUser") as! String)
        }
        
        // (2) Get toUser's object
        if let toUser = withObject?.value(forKey: "toUser") as? PFUser {
            // Get and set proPic
            if let proPic = toUser.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.toUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // Set fullName
            self.toUsername.text = (toUser.value(forKey: "realNameOfUser") as! String)
        }
        
        // (3) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPExtensions
        self.time.text = "Updated their profile photo \(difference.getFullTime(difference: difference, date: from))"
        
        // (4) Set text post
        if let text = withObject!.value(forKey: "textPost") as? String {
            // MARK: - RPExtensions
            let formattedString = NSMutableAttributedString()
            _ = formattedString.bold("\((withObject!.value(forKey: "byUser") as! PFUser).username!) ", withFont: UIFont(name: "AvenirNext-Demibold", size: 15)).normal("\(text)", withFont: UIFont(name: "AvenirNext-Medium", size: 15))
            if withObject!.value(forKey: "textPost") as! String != "" {
                self.textPost.attributedText = formattedString
            } else {
                self.textPost.isHidden = true
            }
        }
        
        // (5) Set photo or video
        // MARK: - SDWebImage
        self.mediaPreview.sd_setIndicatorStyle(.gray)
        self.mediaPreview.sd_showActivityIndicatorView()
        // Traverse asset to PFFile
        if let photo = withObject?.value(forKey: "photoAsset") as? PFFile {
            // MARK: - SDWebImage
            self.mediaPreview.sd_setImage(with: URL(string: photo.url!))
            // MARK: - RPExtensions
            self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
        } else if let video = withObject?.value(forKey: "videoAsset") as? PFFile {
            // TODO::
            // ADD VIDEO....
        }
    }
    
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Set byUser's Profile Tap
        let byUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile(sender:)))
        byUserProPicTap.numberOfTapsRequired = 1
        byUserProPic.isUserInteractionEnabled = true
        byUserProPic.addGestureRecognizer(byUserProPicTap)
        let byUsername = UITapGestureRecognizer(target: self, action: #selector(visitProfile(sender:)))
        byUsername.numberOfTapsRequired = 1
        byUserProPic.isUserInteractionEnabled = true
        byUserProPic.addGestureRecognizer(byUserProPicTap)
        // Set toUser's Profile Tap
        let toUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile(sender:)))
        toUserProPicTap.numberOfTapsRequired = 1
        toUserProPic.isUserInteractionEnabled = true
        toUserProPic.addGestureRecognizer(toUserProPicTap)
        let toUsernameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile(sender:)))
        toUsernameTap.numberOfTapsRequired = 1
        toUsername.isUserInteractionEnabled = true
        toUsername.addGestureRecognizer(toUsernameTap)
        
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
