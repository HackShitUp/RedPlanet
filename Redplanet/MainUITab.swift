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

/*
 ========= Navigation button that launches to the Library, Camera, and New Text Post (aka: ShareUI) ===========
 Hide this button in viewWillAppear and show this button when viewWillDisappear is called
 in the respective UIViewController's lifecycle hierarchy
 */
let rpButton = UIButton(frame: CGRect(x: 0, y: 0, width: 75, height: 75))

// EXTENSION
// Method to configure button
extension UIView {
    func setButton(container: UIView?) {
        // Add button to bottom/center of UITabBar
        var buttonFrame = rpButton.frame
        buttonFrame.origin.y = container!.bounds.height - buttonFrame.height
        buttonFrame.origin.x = container!.bounds.width/2 - buttonFrame.size.width/2
        rpButton.frame = buttonFrame
        rpButton.setImage(UIImage(named: "Cam"), for: .normal)
        rpButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        /*
        rpButton.layer.shadowColor = UIColor.white.cgColor
        rpButton.layer.shadowOffset = CGSize(width: 0, height: -7)
        rpButton.layer.shadowRadius = 1
        rpButton.layer.shadowOpacity = 0.75
        */
        container!.addSubview(rpButton)
    }
}

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
