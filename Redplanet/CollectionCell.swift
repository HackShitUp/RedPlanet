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


/*
 UICollectionViewCell class that's universally used in "Library.swift" and "Stickers.swift"
 Has a single IBOutlet or UIView object, "assetPreview" that shows the preview for its respective parent class.
 Data is binded in its parent class.
 */

class CollectionCell: UICollectionViewCell {

    @IBOutlet weak var assetPreview: PFImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
