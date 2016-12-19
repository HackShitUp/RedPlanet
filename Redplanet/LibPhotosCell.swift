//
//  LibPhotosCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/19/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class LibPhotosCell: UICollectionViewCell {
    
    @IBOutlet weak var photo: PFImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
