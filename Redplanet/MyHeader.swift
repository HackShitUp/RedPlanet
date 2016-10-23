//
//  MyHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class MyHeader: UICollectionReusableView {
        

    @IBOutlet weak var myProPic: PFImageView!
    @IBOutlet weak var numberOfFriends: UIButton!
    @IBOutlet weak var numberOfFollowers: UIButton!
    @IBOutlet weak var numberOfFollowing: UIButton!
    @IBOutlet weak var friendButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var relationState: UIButton!
    @IBOutlet weak var userBio: KILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Center text
        numberOfFriends.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowers.titleLabel!.textAlignment = NSTextAlignment.center
        numberOfFollowing.titleLabel!.textAlignment = NSTextAlignment.center
        
        
    }// end awakeFromNib
}
