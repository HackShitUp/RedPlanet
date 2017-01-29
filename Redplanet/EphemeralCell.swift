//
//  EphemeralCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts



class EphemeralCell: UITableViewCell {
    
    // Instantiate delegate
    var delegate: UINavigationController?
    
    // Instantiate user's object
    var userObject: PFObject?
    
    // Instantiate post object
    var contentObject: PFObject?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var iconicPreview: PFImageView!
    
    
    // Function to view post
    func viewPost() {
        if self.contentObject!.value(forKey: "contentType") as! String == "sh" {
            // Append object
            sharedObject.append(self.contentObject!)
            // Push VC
            let sharedPostVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
            self.delegate?.pushViewController(sharedPostVC, animated: true)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPost))
        tap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(tap)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
