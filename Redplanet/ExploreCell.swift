//
//  ExploreCell.swift
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

class ExploreCell: UICollectionViewCell {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        // Layout views
//        self.rpUserProPic.layoutIfNeeded()
//        self.rpUserProPic.layoutSubviews()
//        self.rpUserProPic.setNeedsLayout()
//        
//        // Make Profile Photo Circular
//        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
//        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
//        self.rpUserProPic.layer.borderWidth = 0.5
//        self.rpUserProPic.clipsToBounds = true
    }
    
}
