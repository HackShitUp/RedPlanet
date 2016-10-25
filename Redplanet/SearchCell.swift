//
//  SearchCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts



class SearchCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Initilize user's object
    var userObject: PFObject?

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpFullName: UILabel!
    @IBOutlet weak var rpUsername: UILabel!
    
    // Go to user
    func goUser() {
        
        // Append other user
        otherObject.append(self.userObject!)
        // Append otherName
        otherName.append(self.rpUsername.text!)
        
        // Push VC
        let otherVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.delegate?.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add tap to go to user's profile
        let tap = UITapGestureRecognizer(target: self, action: #selector(goUser))
        tap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpFullName.isUserInteractionEnabled = true
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(tap)
        self.rpFullName.addGestureRecognizer(tap)
        self.rpUsername.addGestureRecognizer(tap)
        self.contentView.addGestureRecognizer(tap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
