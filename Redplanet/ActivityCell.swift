//
//  ActivityCell.swift
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

class ActivityCell: UITableViewCell {
    
    
    // Instantiate parent view controller
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?

    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var activity: UIButton!
    @IBOutlet weak var time: UILabel!
    
    
    // Function to go to user's profile
    func goUser() {
        // Append user's object
        otherObject.append(self.userObject!)
        // Append user's name
        otherName.append(self.rpUsername.titleLabel!.text!)
        
        // Push VC
        let otherVC = delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Add userProfile tap
        let userTap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        userTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(userTap)
        self.rpUserProPic.addGestureRecognizer(userTap)


    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
