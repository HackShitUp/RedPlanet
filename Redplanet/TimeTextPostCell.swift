//
//  TimeTextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SimpleAlert
import SVProgressHUD

class TimeTextPostCell: UITableViewCell {
    
    // Initialize delegate
    var delegate: UIViewController?
    
    // Initialize user object delegate
    var userObject: PFObject?
    
    // Initialize posts' object: PFObject
    var postObject: PFObject?
    
    // Likes, Comments, and Shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // Function to fetch likes, comments and shares
    func fetchInteractions() {
        // (III) Fetch likes, comments, and shares
        let likes = PFQuery(className: "Likes")
        likes.includeKey("fromUser")
        likes.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                }
                
                // Comments
                let comments = PFQuery(className: "Comments")
                comments.whereKey("forObjectId", equalTo: self.postObject!.objectId!)
                comments.findObjectsInBackground {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            self.comments.append(object)
                        }
                        
                        // Shares
                        let shares = PFQuery(className: "Newsfeeds")
                        shares.includeKeys(["pointObject", "byUser"])
                        shares.whereKey("contentType", equalTo: "sh")
                        shares.whereKey("pointObject", equalTo: self.postObject!)
                        shares.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // Clear array
                                self.shares.removeAll(keepingCapacity: false)
                                for object in objects! {
                                    self.shares.append(object.object(forKey: "byUser") as! PFUser)
                                }
                                
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                        
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Set likes, comments, and shares
        // Number of likes
        if self.likes.count == 0 {
            self.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            self.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            self.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
            self.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
        } else {
            self.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
        }
        // Number of comments
        if self.comments.count == 0 {
            self.numberOfComments.setTitle("comments", for: .normal)
        } else if self.comments.count == 1 {
            self.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            self.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
        }
        // Number of shares
        if self.shares.count == 0 {
            self.numberOfShares.setTitle("shares", for: .normal)
        } else if self.shares.count == 1 {
            self.numberOfShares.setTitle("1 share", for: .normal)
        } else {
            self.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
