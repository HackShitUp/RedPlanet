//
//  MainUITab.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import SwipeNavigationController

class MainUITab: UITabBarController, UITabBarControllerDelegate {
    
    // Function to show camera
    func showShareUI() {
        DispatchQueue.main.async {
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set delegate
        self.delegate = self

        // MARK: - MainUITab Extension
        /*
         Overlay UIButton to push to the
         */
        self.view.setButton(container: self.view)
        rpButton.addTarget(self, action: #selector(showShareUI), for: .touchUpInside)
        
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

        // Set font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 10.0)!], for: .normal)
    }
}
