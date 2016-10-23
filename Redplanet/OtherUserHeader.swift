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
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var numberOfFriends: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var relationType: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var userBio: UILabel!
    
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

    }
        
}
