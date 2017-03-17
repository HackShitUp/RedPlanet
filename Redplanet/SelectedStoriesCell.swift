//
//  SelectedStoriesCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/16/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class SelectedStoriesCell: UICollectionViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var coverPhoto: PFImageView!
}
