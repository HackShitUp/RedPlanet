//
//  MyContentCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class MyContentCell: UICollectionViewCell {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var textPreview: KILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
