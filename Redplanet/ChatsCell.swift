//
//  ChatsCell.swift
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

class ChatsCell: UITableViewCell {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var status: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Circular profile photos
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
