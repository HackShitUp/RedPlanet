//
//  OtherContentCell.swift
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

import KILabel

class OtherContentCell: UICollectionViewCell {
    
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var textPreview: KILabel!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var time: KILabel!
    @IBOutlet weak var rpUsername: KILabel!
    
    
    override func awakeFromNib() {
        // Set color around the border
//        self.contentView.layer.cornerRadius = 10.00
//        self.contentView.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
//        self.contentView.layer.borderColor = UIColor.black.cgColor
//        self.contentView.layer.borderWidth = 0.50
//        self.contentView.clipsToBounds = true
    }
}
