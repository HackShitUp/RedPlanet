//
//  StoryCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import KILabel

class StoryCell: UITableViewCell {
    
    // Parent VC
    var delegate: UIViewController?
    // PFObject
    var postObject: PFObject?

    @IBOutlet weak var textPreview: KILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // Function to show stories
    func showStories() {
        // Append object
        storyObjects.append(self.postObject!)
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let storiesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storiesVC") as! Stories
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storiesVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true)
    }
    
    
    // Func options
    func doMore() {
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add tap method to viewStory
        let storyTap = UITapGestureRecognizer(target: self, action: #selector(showStories))
        storyTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(storyTap)
        
        // Let holdOptions
        let holdOptions = UILongPressGestureRecognizer(target: self, action: #selector(doMore))
        holdOptions.minimumPressDuration = 0.40
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(holdOptions)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
