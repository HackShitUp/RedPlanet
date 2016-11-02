//
//  RelationshipRequestsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/1/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class RelationshipRequestsCell: UICollectionViewCell {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var userBio: KILabel!
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var ignoreButton: UIButton!
    @IBOutlet weak var relationState: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
