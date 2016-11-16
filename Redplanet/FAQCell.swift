//
//  FAQCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import KILabel

class FAQCell: UITableViewCell {

    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var answer: KILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
