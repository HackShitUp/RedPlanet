//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/21/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class VideoCell: UICollectionViewCell {
    
    // Set Parent VC
    var delegate: UIViewController?
    
    // Set post
    var postObject: PFObject?
    
    
    // Function to bind data
    func bindData(sender: PFObject?) {
        
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
