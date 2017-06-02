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

/*
 UITableViewHeaderFooterView class that shows the user's profile.
 This class references to the XIB file, "CurrentUserHeader.xib" which presents the following:
 • Number of Posts
 • Number of Followers
 • Number of Following
 • Follow/Unfollow Button
 • User's full name (realNameOfUser in database) - when tapped, navigates to "ProfileEdit.swift"
 • User's bio.
 Works with "CurrentUser.swift", this class where the user's posts and notifications are shown.
 */

class CurrentUserHeader: UITableViewHeaderFooterView {

    // Initialize parent VC
    var delegate: UIViewController?

    @IBOutlet weak var myProPic: PFImageView!
    @IBOutlet weak var numberOfPosts: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var userBio: KILabel!
    @IBOutlet weak var segmentView: UIView!
    
    // FUNCITON - Show followers
    func showFollowers() {
        // Show FollowersFollowingVC
        let followersFollowingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followersFollowingVC") as! FollowersFollowing
        followersFollowingVC.relationForUser = PFUser.current()!
        followersFollowingVC.followersFollowing = "Followers"
        self.delegate?.navigationController?.pushViewController(followersFollowingVC, animated: true)
    }
    
    // FUNCTION - Show followers
    func showFollowing() {
        // Show FollowersFollowingVC
        let followersFollowingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "followersFollowingVC") as! FollowersFollowing
        followersFollowingVC.relationForUser = PFUser.current()!
        followersFollowingVC.followersFollowing = "Following"
        self.delegate?.navigationController?.pushViewController(followersFollowingVC, animated: true)
    }
    
    // FUNCTION - Show profile photo
    func showProPic() {
        // Check if ProfilePhoto exists
        if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
        // Show Profile Photo
            // Get user's profile photo
            let proPic = PFQuery(className: "Posts")
            proPic.whereKey("byUser", equalTo: PFUser.current()!)
            proPic.whereKey("contentType", equalTo: "pp")
            proPic.includeKeys(["byUser", "toUser"])
            proPic.order(byDescending: "createdAt")
            proPic.getFirstObjectInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // StoryVC
                    let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
                    storyVC.storyObject = object
                    // MARK: - RPPopUpVC
                    let rpPopUpVC = RPPopUpVC()
                    rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
                    self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
            
        } else if PFUser.current()!.value(forKey: "proPicExists") as! Bool == false {
        // ZOOM into photo
            // Mark: - Agrume
            let agrume = Agrume(image: self.myProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
            agrume.hideStatusBar = true
            agrume.showFrom(self.delegate!.self)
        }
    }
    
    // FUNCTION - Edit profile
    func editProfile() {
        // Track when user taps the EditProfile button
        Heap.track("TappedEditProfile", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        let profileEdit = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profileEditVC") as! ProfileEdit
        self.delegate?.navigationController?.pushViewController(profileEdit, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Center # of posts, followers, and following text
        numberOfPosts.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
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
        
        // (4)
        // MARK: - KILabel; @, #, and https://
        // @@@
        userBio.userHandleLinkTapHandler = { label, handle, range in
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
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.delegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
        // https://
        userBio.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }
}
