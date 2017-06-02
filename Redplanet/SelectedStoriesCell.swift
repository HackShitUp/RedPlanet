//
//  SelectedStoriesCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

/*
 UICollectionViewCell that holds the IBOutlets and UIView objects for each news story.
 */

class SelectedStoriesCell: UICollectionViewCell {
    @IBOutlet weak var publisherLogo: PFImageView!
    @IBOutlet weak var publisherName: UILabel!
    @IBOutlet weak var coverPhoto: PFImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var storyDescription: UILabel!
    @IBOutlet weak var storyStatus: UILabel!
}
