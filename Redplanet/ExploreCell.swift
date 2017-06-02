//
//  ExploreCell.swift
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

// From Explore; SUGGESTED ACCOUNTS and NEAR ME - UICollectionViewCell class that shows the News Preview

class ExploreCell: UICollectionViewCell {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var rpUserBio: KILabel!
    
    
}
