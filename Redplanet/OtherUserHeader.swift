//
//  OtherUserHeader.swift
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


class OtherUserHeader: UICollectionReusableView {
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Load other user's data
        if let proPic = otherObject.last!.value(forKey: "userProfilePicture") as? PFFile {
            proPic.getDataInBackground(block: {
                (data: Data?, error: Error?) in
                if error == nil {
                    // TODO::
                    // Set other user's profile photo here
                } else {
                    print(error?.localizedDescription)
                }
            })
        }
    }
        
}
