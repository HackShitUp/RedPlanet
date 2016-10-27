//
//  TextPostCell.swift
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

class TextPostCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Variabel to hold user's object
    var userObject: PFObject?
    
    // Variable to hold content object
    var contentObject: PFObject?
    

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBAction func moreButton(_ sender: AnyObject) {
    }
    
    
    // Function to go to OtherUser
    func goOther() {
        print("\(userObject)")
        
        // Append user's object
        otherObject.append(self.userObject!)
        // Append username
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    // Function to view comments
    @IBAction func comments(_ sender: AnyObject) {
        // Append object
        commentsObject.append(self.contentObject!)
        
        // Push VC
        let commentsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "commentsVC") as! Comments
        self.delegate?.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // (1) Add tap to go to user's profile
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goOther))
        userTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(userTap)
        
        // (2) Add comment tap
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(comments))
        commentTap.numberOfTapsRequired = 1
        self.numberOfComments.isUserInteractionEnabled = true
        self.numberOfComments.addGestureRecognizer(commentTap)
        
        
        
        // Handle @username tap
        textPost.userHandleLinkTapHandler = { label, handle, range in
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
        textPost.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
//            var mention = handle
//            mention = String(mention.characters.dropFirst())
//            hashtags.append(mention.lowercaseString)
//            let hashTags = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("hashTags") as! Hashtags
//            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        // Handle http: tap
        textPost.urlLinkTapHandler = { label, handle, range in
            // Open url
            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
            self.delegate?.present(modalWeb, animated: true, completion: nil)
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
