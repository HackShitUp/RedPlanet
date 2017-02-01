//
//  Home.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

class Home: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - CAPSPageMenu
    // pageMenu Initialization
    var pageMenu : CAPSPageMenu?
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .default


        // Array to keep track of controllers in page menu
        var controllerArray : [UIViewController] = []
        
        // FRIENDS
        let friends = self.storyboard!.instantiateViewController(withIdentifier: "friendsVC") as! Friends
        friends.parentNavigator = self.navigationController
        friends.title = "Friends"
        controllerArray.append(friends)
        
        // FOLLOWING
        let following = self.storyboard?.instantiateViewController(withIdentifier: "tFollowing") as! TFollowing
        following.parentNavigator = self.navigationController
        following.title = "Following"
        controllerArray.append(following)
        
        // Customize page menu to your liking (optional) or use default settings by sending nil for 'options' in the init
        let parameters: [CAPSPageMenuOption] = [
            .menuItemSeparatorWidth(0.0),
            .useMenuLikeSegmentedControl(true),
            .menuHeight(35.00),
            .selectionIndicatorColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)),
            .scrollMenuBackgroundColor(UIColor.white),
            .selectedMenuItemLabelColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)),
            .menuItemFont(UIFont(name: "AvenirNext-Medium", size: 17.00)!),
            .unselectedMenuItemLabelColor(UIColor.black),
            .bottomMenuHairlineColor(UIColor.clear)
        ]
        
        // Initialize page menu with controller array, frame, and optional parameters
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRect(x: 0.0, y: 20.00, width: self.view.frame.width, height: self.view.frame.height-self.navigationController!.tabBarController!.tabBar.frame.height-20), pageMenuOptions: parameters)
        
        // Lastly add page menu as subview of base view controller view
        // or use pageMenu controller in you view hierachy as desired
        self.view.addSubview(pageMenu!.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Hide navigation Bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Show tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show statusBar, hide navigation bar, show tab bar
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Hide menu
        pageMenu?.hideTopMenuBar = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Hide menu
        pageMenu?.hideTopMenuBar = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
