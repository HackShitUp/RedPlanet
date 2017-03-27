//
//  MasterTab.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SwipeNavigationController

class MasterTab: UITabBarController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create corner radius for topLeft/topRight of UIView
        let shape = CAShapeLayer()
        shape.bounds = self.view.frame
        shape.position = self.view.center
        shape.path = UIBezierPath(roundedRect: self.view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8)).cgPath
        self.view.layer.backgroundColor = UIColor.black.cgColor
        self.view.layer.mask = shape
        self.view.clipsToBounds = true

        // Change status bar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tabBar's tintColor and tabBar's barTintColor
        self.tabBar.tintColor = UIColor.black
        self.tabBar.barTintColor = UIColor.white

        // If current user is not nil
        if PFUser.current() != nil {
            // Set title to user's username
            self.tabBar.items?[4].title = PFUser.current()!.username!.lowercased()
        }
        
        // Set font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 10.0)!], for: .normal)
    }
    
    
}
