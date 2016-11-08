//
//  RPIconsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/8/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

class RPIconsCell: UITableViewCell {


    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var iconName: UILabel!
    @IBOutlet weak var iconDescription: UILabel!
    @IBOutlet weak var background: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
