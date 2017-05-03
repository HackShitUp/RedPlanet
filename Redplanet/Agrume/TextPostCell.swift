
//
//  TextPostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class TextPostCell: UITableViewCell {
    
    
    var postObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!

    
    // Function to like object
    func like(sender: UIButton) {
        let rpHelpers = RPHelpers()
        if self.likeButton.image(for: .normal) == UIImage(named: "LikeFilled") {
            rpHelpers.unlikeObject(forObject: self.postObject!)
        } else if self.likeButton.image(for: .normal) == UIImage(named: "Like") {
            rpHelpers.likeObject(forObject: self.postObject, notificationType: "like tp", activeButton: self.likeButton)
        }
    }
    
    
    // Function to bind data
    func updateView(postObject: PFObject?) {
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let likeTap = UITapGestureRecognizer(target: self, action: #selector(like))
        likeTap.numberOfTapsRequired = 1
        self.likeButton.isUserInteractionEnabled = true
        self.likeButton.addGestureRecognizer(likeTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
