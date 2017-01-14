//
//  AboutUsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/26/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import KILabel

import Parse
import ParseUI
import Bolts

class AboutUsCell: UITableViewCell {
    
    // Initialize delegate
    var delegate: UIViewController?
    
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var aboutText: KILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Handle @username tap
        aboutText.userHandleLinkTapHandler = { label, handle, range in
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
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        
        // Handle #object tap
        aboutText.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
            var mention = handle
            mention = String(mention.characters.dropFirst())
            hashtags.append(mention.lowercased())
            let hashTags = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! HashTags
            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)
        }
        
        // Handle http: tap
        aboutText.urlLinkTapHandler = { label, handle, range in
            // Open url
//            let modalWeb = SwiftModalWebVC(urlString: handle, theme: .lightBlack)
//            self.delegate?.present(modalWeb, animated: true, completion: nil)
//            UIApplication.shared.open(handle)
        }

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
