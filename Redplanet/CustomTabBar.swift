//
//  CustomTabBar.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/30/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBar {
    
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        
        var sizeThatFits = super.sizeThatFits(size)
//        sizeThatFits.height = 40.0
        sizeThatFits.height = 50.00
        // Height is originally 50
        
        return sizeThatFits
    }

    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
