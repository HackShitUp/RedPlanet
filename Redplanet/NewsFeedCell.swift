//
//  NewsFeedCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts

class NewsFeedCell: UITableViewCell {
    
    // Parent VC
    var delegate: UINavigationController?
    
    // PFObject
    var postObject: PFObject?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // Function to show stories
    func showStories() {
        // Save to Views
        let views = PFObject(className: "Views")
        views["byUser"] = PFUser.current()!
        views["username"] = PFUser.current()!.username!
        views["forObjectId"] = self.postObject!.objectId!
        views.saveInBackground()
        
        // Append object
        timelineObjects.append(self.postObject!)
        
        // MARK: - RPPopUpVC
        let rpPopUpVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "rpPopUpVC") as! RPPopUpVC
        let timelineVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "timelineVC") as! Timeline
        rpPopUpVC.configureView(vc: rpPopUpVC, popOverVC: timelineVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Add tap method to viewStory
        let storyTap = UITapGestureRecognizer(target: self, action: #selector(showStories))
        storyTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(storyTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
