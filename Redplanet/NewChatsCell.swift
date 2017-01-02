//
//  NewChatsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Share content
var privateText = [String]()
var privatePhoto = [UIImage]()

class NewChatsCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var rpFullName: UILabel!
    
    
    // Share With
    func createChat() {
        
        // Append chat objects
        chatUsername.append(self.userObject!.value(forKey: "username") as! String)
        // Show chat
        chatUserObject.append(self.userObject!)
        
        // Push to RPChat Room
        let chatRoom = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
        self.delegate?.navigationController?.pushViewController(chatRoom, animated: true)
        
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Add alert function
        let alertTap = UITapGestureRecognizer(target: self, action: #selector(createChat))
        alertTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(alertTap)
        
        // Set layouts
        rpUserProPic.layoutIfNeeded()
        rpUserProPic.layoutSubviews()
        rpUserProPic.setNeedsLayout()
        
        // Make pro pic ciruclar
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        self.rpUserProPic.layer.borderWidth = 0.5
        self.rpUserProPic.clipsToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
