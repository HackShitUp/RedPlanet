//
//  CustomTabBar.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/30/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBar {
    
    override func awakeFromNib() {
//        self.backgroundImage = UIImage()
//        self.shadowImage = nil
//        self.setValue(true, forKey: "_hidesShadows")
//        self.clipsToBounds = true
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 45.00
        return sizeThatFits
    }
    
}
