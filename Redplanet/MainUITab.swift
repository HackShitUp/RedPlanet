//
//  MainUITab.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SwipeNavigationController

class MainUITab: UITabBarController, UITabBarControllerDelegate {
    
    
    
    
    let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
    
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let def = UserDefaults.standard
        def.set(Int(self.selectedIndex), forKey: "lastTab")
        def.synchronize()
        
        if item.tag == 2 {
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set delegate
        self.delegate = self
        self.selectedIndex = 0
        
        
        let def = UserDefaults.standard
        let lastTab = def.value(forKey: "lastTab") as! Int
        //        self.selectedIndex = lastTab
        
        /*
         self.tabBar.layer.borderWidth = 0.3
         self.tabBar.layer.borderColor = UIColor.white.cgColor
         self.tabBar.clipsToBounds = true
         */
        
        /*
         var menuButtonFrame = shareButton.frame
         menuButtonFrame.origin.y = view.bounds.height - menuButtonFrame.height
         menuButtonFrame.origin.x = view.bounds.width/2 - menuButtonFrame.size.width/2
         shareButton.frame = menuButtonFrame
         shareButton.layer.cornerRadius = menuButtonFrame.height/2
         shareButton.setImage(UIImage(named: "Cam"), for: .normal)
         view.addSubview(shareButton)
         */
        
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
            //            self.tabBar.items?[4].title = PFUser.current()!.username!.lowercased()
        }
        
        // Set font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 10.0)!], for: .normal)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
}
