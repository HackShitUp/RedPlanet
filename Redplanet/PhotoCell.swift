//
//  PhotoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/21/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import KILabel

import Parse
import ParseUI
import Bolts

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var photo: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
