//
//  CommentsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/7/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices
import Parse
import ParseUI
import Bolts
import KILabel

class CommentsCell: UITableViewCell {
    
    // Initialize parent UIViewController
    var delegate: UIViewController?
    // Initialize PFObject
    var postObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var comment: KILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfLikes: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Handle @username tap
        comment.userHandleLinkTapHandler = { label, handle, range in
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
                        // Push VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        
        // Handle #object tap
        comment.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
//            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
//            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        
        // Handle http: tap
        comment.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            // MARK: - RPHelpers
            webVC.view.roundTopCorners(sender: webVC.view)
            self.delegate?.present(webVC, animated: true, completion: nil)
        }

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
