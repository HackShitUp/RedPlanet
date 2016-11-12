//
//  SharedPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/11/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal

class SharedPostCell: UITableViewCell {

    // IBOutlets - User who shared content
    @IBOutlet weak var fromRpUserProPic: PFImageView!
    @IBOutlet weak var sharedTime: UILabel!
    @IBOutlet weak var fromRpUsername: UILabel!
    
    // IBOutlets - Shared content
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    // IBOutlets - Buttons
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // create cor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
