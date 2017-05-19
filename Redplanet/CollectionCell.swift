//
//  CollectionCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class CollectionCell: UICollectionViewCell {

    @IBOutlet weak var assetPreview: PFImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
