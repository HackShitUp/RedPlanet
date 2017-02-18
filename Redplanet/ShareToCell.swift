//
//  ShareToCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/18/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class ShareToCell: UITableViewCell {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var checkMark: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
