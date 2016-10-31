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
        // Add top border to distinguish content
        let upperBorder = CALayer()
        upperBorder.backgroundColor = UIColor.black.cgColor
        upperBorder.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 0.50)
        self.layer.addSublayer(upperBorder)
    }
    
}
