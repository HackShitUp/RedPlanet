//
//  CustomTabBar.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/30/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit

/*
 Custom UITabBar class that minimizes default height of the tab bar.
 */

class CustomTabBar: UITabBar {
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 45.00
        return sizeThatFits
    }
}
