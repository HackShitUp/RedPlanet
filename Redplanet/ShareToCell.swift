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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
