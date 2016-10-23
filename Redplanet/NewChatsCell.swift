//
//  NewChatsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class NewChatsCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var rpFullName: UILabel!
    
    
    // Share With
    func showAlert() {
        
        let alert = UIAlertController(title: "Private Chat",
                                      message: "Share privately with \(self.userObject!.value(forKey: "realNameOfUser") as! String)",
            preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "yes",
                                style: .default,
                                handler: {(alertAction: UIAlertAction!) in
                                    // Share to friend
                                    // TODO::
        })
        
        let no = UIAlertAction(title: "no",
                               style: .destructive,
                               handler: nil)
        
        alert.addAction(no)
        alert.addAction(yes)
        self.delegate?.present(alert, animated: true, completion: nil)
        
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Add alert function
        let alertTap = UITapGestureRecognizer(target: self, action: #selector(showAlert))
        alertTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpFullName.isUserInteractionEnabled = true
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(alertTap)
        self.rpFullName.addGestureRecognizer(alertTap)
        self.rpUserProPic.addGestureRecognizer(alertTap)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
