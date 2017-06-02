//
//  UserCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

/*
 UITableViewCell class that shows the following user's data:
 • User's Profile Photo (ie: "userProfilePicture" in database).
 • User's Username (ie: "username" in database).
 • User's Full Name (ie: "realNameOfUser" in database).
 */

class UserCell: UITableViewCell {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
