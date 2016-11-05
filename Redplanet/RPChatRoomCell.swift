//
//  RPChatRoomCell.swift
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


class RPChatRoomCell: UITableViewCell {
    
    
    // Initialize Parent View Controller
    var delegate: UIViewController?
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var message: KILabel!
    
    
    // Show chat options
    func chatOptions(sender: UIGestureRecognizer) {
        
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        let copy = UIAlertAction(title: "Copy",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    // Copy text
                                    
                                    let message: UILabel = sender.view as! UILabel
                                    print("The text selected is: \(message.text!)")
                                    
                                    let pasteboard: UIPasteboard = UIPasteboard.general
                                    pasteboard.string = message.text!
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        options.addAction(copy)
        options.addAction(cancel)
        options.view.tintColor = UIColor.black
        self.delegate?.present(options, animated: true, completion: nil)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
        // add text tap
        let chatHold = UILongPressGestureRecognizer(target: self, action: #selector(chatOptions))
        chatHold.minimumPressDuration = 0.50
        self.message.isUserInteractionEnabled = true
        self.message.addGestureRecognizer(chatHold)
        
        
        
        
        // Handle @username tap
        message.userHandleLinkTapHandler = { label, handle, range in
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
        message.hashtagLinkTapHandler = { label, handle, range in
            // When # is tapped, drop the "#" and send to hashtags
//            var mention = handle
//            mention = String(mention.characters.dropFirst())
//            hashtags.append(mention.lowercaseString)
//            let hashTags = self.delegate?.storyboard?.instantiateViewControllerWithIdentifier("hashTags") as! Hashtags
//            self.delegate?.navigationController?.pushViewController(hashTags, animated: true)

        }
        
        // Handle http: tap
        message.urlLinkTapHandler = { label, handle, range in
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
