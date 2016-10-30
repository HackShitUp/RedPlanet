//
//  OtherUserHeader.swift
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



// Array to hold other user's relationships
var oFriends = [PFObject]()

var oFollowers = [PFObject]()

var oFollowing = [PFObject]()

class OtherUserHeader: UICollectionReusableView {
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var numberOfFriends: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var relationType: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var userBio: KILabel!
    
    // Function to show friends
    func showFriends() {
        // Append to forFriends
        forFriends.append(otherObject.last!)
        
        // Push VC
        let friendsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFriendsVC") as! RFriends
        self.delegate?.navigationController?.pushViewController(friendsVC, animated: true)
    }
    
    
    // Function to show followers
    func showFollowers() {
        // Append to forFriends
        forFollowers.append(otherObject.last!)
        
        // Push VC
        let followersVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowersVC") as! RFollowers
        self.delegate?.navigationController?.pushViewController(followersVC, animated: true)
    }
    
    // Function to show followers
    func showFollowing() {
        // Append to forFriends
        forFollowing.append(otherObject.last!)
        
        // Push VC
        let followingVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rFollowingVC") as! RFollowing
        self.delegate?.navigationController?.pushViewController(followingVC, animated: true)
    }
    
    
    // Function to show profile photo
    func showProPic() {
        
        
        // Get user's profile photo
        let proPic = PFQuery(className: "ProfilePhoto")
        proPic.whereKey("fromUser", equalTo: otherObject.last!)
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
    
    
    
    // Function to friend
    func friendUser() {
        let friendMe = PFObject(className: "FriendMe")
        friendMe["frontFriend"] = PFUser.current()!
        friendMe["frontFriendName"] = PFUser.current()!.username!
        friendMe["endFriend"] = otherObject.last!
        friendMe["endFriendName"] = otherObject.last!.value(forKey: "username") as! String
        friendMe["isFriends"] = false
        friendMe.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                print("Successfully sent Friend request: \(friendMe)")
                
                // TODO::
                // Save to notifications
                // Send push notification
                
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    
    
    // Function to follow
    func followUser() {
        
    }
    
    
    
    // Function to undo relation
    func undoRelation() {
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // (1) Center text
        numberOfFriends.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        
        // (2) Count relationships
        // COUNT FRIENDS
        let endFriend = PFQuery(className: "FriendMe")
        endFriend.whereKey("endFriend", equalTo: otherObject.last!)
        endFriend.whereKey("frontFriend", notEqualTo: otherObject.last!)
        
        let frontFriend = PFQuery(className: "FriendMe")
        frontFriend.whereKey("frontFriend", equalTo: otherObject.last!)
        frontFriend.whereKey("endFriend", notEqualTo: otherObject.last!)
        
        let countFriends = PFQuery.orQuery(withSubqueries: [endFriend, frontFriend])
        countFriends.whereKey("isFriends", equalTo: true)
        countFriends.countObjectsInBackground(block: {
            (count: Int32, error: Error?) -> Void in
            if error == nil {
                self.numberOfFriends.setTitle("\(count)\nfriends", for: .normal)
            } else {
                self.numberOfFriends.setTitle("0\nfriends", for: .normal)
            }
        })
        
        // COUNT FOLLOWERS
        let countFollowers = PFQuery(className: "FollowMe")
        countFollowers.whereKey("isFollowing", equalTo: true)
        countFollowers.whereKey("following", equalTo: otherObject.last!)
        countFollowers.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                self.numberOfFollowers.setTitle("\(count)\nfollowers", for: .normal)
            } else {
                self.numberOfFollowers.setTitle("0\nfollowers", for: .normal)
            }
        })
        
        // COUNT FOLLOWING
        let countFollowing = PFQuery(className: "FollowMe")
        countFollowing.whereKey("isFollowing", equalTo: true)
        countFollowing.whereKey("follower", equalTo: otherObject.last!)
        countFollowing.countObjectsInBackground(block: {
            (count: Int32, error: Error?) in
            if error == nil {
                self.numberOfFollowing.setTitle("\(count)\nfollowing", for: .normal)
            } else {
                self.numberOfFollowing.setTitle("\(count)\nfollowing", for: .normal)
            }
        })
        
        // (3) Design buttons
        self.relationType.layer.cornerRadius = 22.00
        self.relationType.clipsToBounds = true
        
        
        self.friendButton.backgroundColor = UIColor.white
        self.friendButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.friendButton.layer.borderWidth = 3.00
        self.friendButton.layer.cornerRadius = 22.00
        self.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.friendButton.clipsToBounds = true
        
        self.followButton.backgroundColor = UIColor.white
        self.followButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
        self.followButton.layer.borderWidth = 4.00
        self.followButton.layer.cornerRadius = 22.00
        self.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.followButton.clipsToBounds = true
        
        
        
        // (4) Handle KILabel taps
        // Handle @username tap
        userBio.userHandleLinkTapHandler = { label, handle, range in
            // When mention is tapped, drop the "@" and send to user home page
            var mention = handle
            mention = String(mention.characters.dropFirst())
            
            //            // Query data
            //            let user = PFUser.query()!
            //            user.whereKey("username", equalTo: mention.lowercaseString)
            //            user.findObjectsInBackgroundWithBlock({
            //                (objects: [PFObject]?, error: NSError?) in
            //                if error == nil {
            //                    for object in objects! {
            //                        // Append user's username
            //                        otherName.append(mention)
            //                        // Append user object
            //                        otherObject.append(object)
            //
            //
            //                        let otherUser = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("otherUser") as! OtherUserProfile
            //                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
            //                    }
            //                } else {
            //                    print(error?.localizedDescription)
            //                }
            //            })
        }
        
        
        // Handle #object tap
        userBio.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            //            var mention = handle
            //            mention = String(mention.characters.dropFirst())
            //            hashtags.append(mention.lowercaseString)
            //            let hashTags = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("hashTags") as! Hashtags
            //            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        // Handle http: tap
        userBio.urlLinkTapHandler = { label, handle, range in
            // Open url
            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
            self.delegate?.present(modalWeb, animated: true, completion: nil)
        }
        
        
        // (5) Add tap methods to show friends, followers, and following        
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
        
        
        
        // (6) Add tap method to show profile photo
        // Show Profile photo if friends
        if myFriends.contains(otherObject.last!) && otherObject.last!.value(forKey: "proPicExists") as! Bool == true {
            let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProPic))
            proPicTap.numberOfTapsRequired = 1
            self.rpUserProPic.isUserInteractionEnabled = true
            self.rpUserProPic.addGestureRecognizer(proPicTap)
        } else {
            // Add tap gesture to zoom in
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.rpUserProPic.isUserInteractionEnabled = true
            self.rpUserProPic.addGestureRecognizer(zoomTap)
        }
        
        

    }
        
}
