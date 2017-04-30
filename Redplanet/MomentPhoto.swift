//
//  MomentPhoto.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage

class MomentPhoto: UICollectionViewCell {
    
    @IBOutlet weak var photoMoment: PFImageView!
    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Apply shadows
        self.rpUsername.layer.applyShadow(layer: self.rpUsername.layer)
        self.time.layer.applyShadow(layer: self.time.layer)
        self.moreButton.layer.applyShadow(layer: self.moreButton.layer)
    }

}
