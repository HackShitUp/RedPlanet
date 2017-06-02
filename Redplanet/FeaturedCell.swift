//
//  FeaturedCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/16/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import KILabel

// From Explore; FEATURED POSTS - UICollectionViewCell class that shows the News Preview

class FeaturedCell: UICollectionViewCell {
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var textPreview: KILabel!
}
