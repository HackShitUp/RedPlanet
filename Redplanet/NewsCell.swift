//
//  NewsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts


// From Explore; NEWS - UICollectionViewCell class that shows the News Preview

class NewsCell: UICollectionViewCell {
    @IBOutlet weak var storyCover: PFImageView!
    @IBOutlet weak var publisherName: UILabel!
    @IBOutlet weak var storyTitle: UILabel!
}
