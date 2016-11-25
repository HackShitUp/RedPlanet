//
//  BestFriendsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/10/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel



class BestFriendsCell: UITableViewCell {
    
    // Initialize paretn VC
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpName: UILabel!
    @IBOutlet weak var rpBio: KILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
