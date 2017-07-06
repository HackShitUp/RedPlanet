//
//  SendToCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 7/5/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class SendToCell: UITableViewCell {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Configre UITableViewCell
        self.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
