//
//  LikesAndSharesCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/3/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


class LikesAndSharesCell: UITableViewCell {
    
    @IBOutlet weak var iconicPreview: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var time: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
