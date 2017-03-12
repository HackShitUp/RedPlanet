//
//  DiscoverHeaderCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/11/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class DiscoverHeaderCell: UICollectionViewCell {
    // Set URL
    var storyURL: String?
    // Cover Photo
    @IBOutlet weak var coverPhoto: PFImageView!
}
