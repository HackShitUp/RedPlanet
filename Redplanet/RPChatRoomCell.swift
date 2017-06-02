//
//  RPChatRoomCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import KILabel

/*
 UITableViewCell class that presents the <Message> attribute of a single object in "Chats"
 */

class RPChatRoomCell: UITableViewCell {
    
    // Initialize PFObject
    var postObject: PFObject?
    // Initialize Parent UIViewController
    var delegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var message: KILabel!
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject) {
        // MARK: - RPHelpers extension
        self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Set usernames depending on who sent what
        if (withObject.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Set Current user's username
            self.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
        } else {
            // Set username
            self.rpUsername.text! = chatUserObject.last!.value(forKey: "realNameOfUser") as! String
        }
        
        // Fetch Objects
        // (2) Get and set user's profile photos
        // If RECEIVER == <CurrentUser>     &&      SSENDER == <OtherUser>
        if (withObject.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (withObject.object(forKey: "sender") as! PFUser).objectId! == chatUserObject.last!.objectId! {
            
            // Get and set profile photo
            if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        }
        // If SENDER == <CurrentUser>       &&      RECEIVER == <OtherUser>
        if (withObject.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (withObject.object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
            
            // Get and set Profile Photo
            if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        }
        
        // (3) Set message
        self.message.text! = withObject.value(forKey: "Message") as! String
        
        // (4) Set time
        let from = withObject.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        self.time.text = "\(difference.getFullTime(difference: difference, date: from))"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // MARK: - KILabel; @, #, and https://
        // @@@
        message.userHandleLinkTapHandler = { label, handle, range in
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
        message.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.delegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
        // https://
        message.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.delegate?.present(webVC, animated: true, completion: nil)
        }
    }

}
