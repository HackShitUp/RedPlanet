//
//  AboutUsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/26/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import KILabel

class AboutUsCell: UITableViewCell {
    
    @IBOutlet weak var aboutText: KILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
