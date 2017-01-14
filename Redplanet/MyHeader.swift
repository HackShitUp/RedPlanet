//
//  MyHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class MyHeader: UICollectionReusableView {
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    // Initiliaze AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    

    @IBOutlet weak var myProPic: PFImageView!
    @IBOutlet weak var numberOfFriends: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var relationState: UIButton!
    @IBOutlet weak var userBio: KILabel!
    
    
    
    // Function to show friends
    func showFriends() {
        // Append to forFriends
        forFriends.append(PFUser.current()!)
        forFriends.append(PFUser.current()!)
        
        // Push VC
        let friendsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFriendsVC") as! RFriends
        self.delegate?.navigationController?.pushViewController(friendsVC, animated: true)
    }
    
    
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
                    
                    // Append object
                    proPicObject.append(object!)
                    
                    // Push VC
                    let proPicVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                    self.delegate?.navigationController?.pushViewController(proPicVC, animated: true)
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
        } else {
            // Mark: - Agrume
            let agrume = Agrume(image: self.myProPic.image!)
            agrume.statusBarStyle = UIStatusBarStyle.lightContent
            agrume.showFrom(self.delegate!.self)
        }
        
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Center text
        numberOfFriends.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        // (1) Add tap methods to show friends, followers, and following
        // (a) Friends
        let friendsTap = UITapGestureRecognizer(target: self, action: #selector(showFriends))
        friendsTap.numberOfTapsRequired = 1
        self.numberOfFriends.isUserInteractionEnabled = true
        self.numberOfFriends.addGestureRecognizer(friendsTap)
        
        // (b) Followers
        let followersTap = UITapGestureRecognizer(target: self, action: #selector(showFollowers))
        followersTap.numberOfTapsRequired = 1
        self.numberOfFollowers.isUserInteractionEnabled = true
        self.numberOfFollowers.addGestureRecognizer(followersTap)
        
        // (c) Following
        let followingTap = UITapGestureRecognizer(target: self, action: #selector(showFollowing))
        followingTap.numberOfTapsRequired = 1
        self.numberOfFollowing.isUserInteractionEnabled = true
        self.numberOfFollowing.addGestureRecognizer(followingTap)
        
        
        // (2) Show profile photo tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProPic))
        proPicTap.numberOfTapsRequired = 1
        self.myProPic.isUserInteractionEnabled = true
        self.myProPic.addGestureRecognizer(proPicTap)
        
        
        
        // (2) Count relationships
        
        // Query Relationships
        appDelegate.queryRelationships()
        
        // COUNT FRIENDS
        if myFriends.count == 0 {
            self.numberOfFriends.setTitle("friends", for: .normal)
        } else if myFriends.count == 1 {
            self.numberOfFriends.setTitle("1\nfriend", for: .normal)
        } else {
            self.numberOfFriends.setTitle("\(myFriends.count)\nfriends", for: .normal)
        }
        
        // COUNT FOLLOWERS
        if myFollowers.count == 0 {
            self.numberOfFollowers.setTitle("followers", for: .normal)
        } else if myFollowers.count == 1 {
            self.numberOfFollowers.setTitle("1\nfollower", for: .normal)
        } else {
            self.numberOfFollowers.setTitle("\(myFollowers.count)\nfollowers", for: .normal)
        }
        
        // COUNT FOLLOWING
        if myFollowing.count == 0 {
            self.numberOfFollowing.setTitle("following", for: .normal)
        } else if myFollowing.count == 1 {
            self.numberOfFollowing.setTitle("1\nfollowing", for: .normal)
        } else {
            self.numberOfFollowing.setTitle("\(myFollowing.count)\nfollowing", for: .normal)
        }
        
        
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
                        
                        
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Show alert
                    let alert = UIAlertController(title: "Unknown Account",
                                                  message: "Looks like this account doesn't exist yet.",
                                                  preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: nil)
                    
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.delegate?.present(alert, animated: true)
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
            // Open url
//            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
//            self.delegate?.present(modalWeb, animated: true, completion: nil)
        }
        
    }// end awakeFromNib
}
