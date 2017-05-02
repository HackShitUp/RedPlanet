//
//  CurrentUserHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AudioToolbox
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import KILabel

class CurrentUserHeader: UITableViewHeaderFooterView {

    // Initialize parent VC
    var delegate: UIViewController?
    
    // Initiliaze AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var myProPic: PFImageView!
    @IBOutlet weak var numberOfPosts: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var userBio: KILabel!

    // Function to show followers
    func showFollowers() {
        // Append to forFriends
        forFollowers.append(PFUser.current()!)
        forFollowers.append(PFUser.current()!)
        
        // Push VC
        let followersVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowersVC") as! RFollowers
        self.delegate?.navigationController?.pushViewController(followersVC, animated: true)
    }
    
    // Function to show followers
    func showFollowing() {
        // Append to forFriends
        forFollowing.append(PFUser.current()!)
        forFollowers.append(PFUser.current()!)
        
        // Push VC
        let followingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowingVC") as! RFollowing
        self.delegate?.navigationController?.pushViewController(followingVC, animated: true)
    }
    
    
    // Function to show profile photo
    func showProPic() {
        
        if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
            // Append to otherObject
            otherObject.append(PFUser.current()!)
            // Append to otherName
            otherName.append(PFUser.current()!.username!)
            
            // Get user's profile photo
            let proPic = PFQuery(className: "Newsfeeds")
            proPic.whereKey("byUser", equalTo: PFUser.current()!)
            proPic.whereKey("contentType", equalTo: "pp")
            proPic.order(byDescending: "createdAt")
            proPic.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
//                    // Append object
//                    proPicObject.append(object!)
//                    
//                    // Push VC
//                    let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
//                    self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
        } else {
            // Mark: - Agrume
            let agrume = Agrume(image: self.myProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
            agrume.hideStatusBar = true
            agrume.showFrom(self.delegate!.self)
        }
        
    }
    
    // Function to edit profile
    func editProfile() {
        // Track when user taps the EditProfile button
        Heap.track("TappedEditProfile", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        let editVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "editProfileVC") as! ProfileEdit
        self.delegate?.navigationController?.pushViewController(editVC, animated: true)
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Center text
        numberOfPosts.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        // Configure view
        self.contentView.backgroundColor = UIColor.white
        
        // (1) Add tap methods to show followers, and following
        // (A) Followers
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(showFollowers))
        followersTap.numberOfTapsRequired = 1
        self.numberOfFollowers.isUserInteractionEnabled = true
        self.numberOfFollowers.addGestureRecognizer(followersTap)
        // (B) Following
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(showFollowing))
        followingTap.numberOfTapsRequired = 1
        self.numberOfFollowing.isUserInteractionEnabled = true
        self.numberOfFollowing.addGestureRecognizer(followingTap)
        
        // (2) Show profile photo tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProPic))
        proPicTap.numberOfTapsRequired = 1
        self.myProPic.isUserInteractionEnabled = true
        self.myProPic.addGestureRecognizer(proPicTap)
        
        // (3) Edit Profile via fullName
        let editTap = UITapGestureRecognizer(target: self, action: #selector(editProfile))
        editTap.numberOfTapsRequired = 1
        self.fullName.isUserInteractionEnabled = true
        self.fullName.addGestureRecognizer(editTap)
        
        // (4) Handle KILabel taps
        // Handle @username tap
        userBio.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: mention.lowercased())
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append user's username
                        otherName.append(mention)
                        // Append user object
                        otherObject.append(object)
                        
                        
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - AudioToolBox; Vibrate Device
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    // MARK: - AZDialogViewController
                    let dialogController = AZDialogViewController(title: "💩\nUnknown Account",
                                                                  message: "Looks like this account doesn't exist.")
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
                    // Add Skip and verify button
                    dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                        // Dismiss
                        dialog.dismiss()
                    }))
                    dialogController.show(in: self.delegate!)
                }
            })
        }
        
        // Handle #object tap
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        
        // Handle http: tap
        userBio.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: true)
            webVC.view.layer.cornerRadius = 8.00
            webVC.view.clipsToBounds = true
            self.delegate?.navigationController?.present(webVC, animated: true, completion: nil)
        }
        
    }// end awakeFromNib

}
