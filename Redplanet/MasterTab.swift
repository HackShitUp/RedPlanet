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

class MasterTab: UITabBarController {
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layer.cornerRadius = 14.00
        self.view.clipsToBounds = true
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If current user is not nil
        if PFUser.current() != nil {
            // Set title to user's username
            self.tabBar.items?[4].title = PFUser.current()!.username!.uppercased()
        }
        
        // Set font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 10.0)!], for: .normal)
    }
    
    
}
