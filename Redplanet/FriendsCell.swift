//
//  FriendsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/20/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


class FriendsCell: UITableViewCell {
    
    
    // Initialize parent VC
    var delegate: UIViewController?
    
    
    @IBOutlet weak var contentColor: UIView!
    @IBOutlet weak var rpUserProPic: PFImageView!

    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var contentType: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
