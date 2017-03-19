//
//  PermissionsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class PermissionsCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var reason: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
