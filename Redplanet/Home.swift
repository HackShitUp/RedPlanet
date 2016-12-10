//
//  Home.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData



// Global Initialization
var pageMenu : CAPSPageMenu?


class Home: UIViewController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .default


        // Array to keep track of controllers in page menu
        var controllerArray : [UIViewController] = []
        
        // Create variables for all view controllers you want to put in the
        // page menu, initialize them, and add each to the controller array.
        // (Can be any UIViewController subclass)
        // Make sure the title property of all view controllers is set

        let friends = self.storyboard!.instantiateViewController(withIdentifier: "friendsVC") as! Friends
        friends.parentNavigator = self.navigationController
        friends.title = "Friends"
        controllerArray.append(friends)
        
        let following = self.storyboard?.instantiateViewController(withIdentifier: "followingVC") as! Following
        following.parentNavigator = self.navigationController
        following.title = "Following"
        controllerArray.append(following)
        
        // Customize page menu to your liking (optional) or use default settings by sending nil for 'options' in the init
        // Example:
        let parameters: [CAPSPageMenuOption] = [
            .menuItemSeparatorWidth(0.0),
            .useMenuLikeSegmentedControl(true),
            .menuHeight(self.navigationController!.navigationBar.frame.size.height),
            .selectionIndicatorColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)),
            .scrollMenuBackgroundColor(UIColor.white),
            .selectedMenuItemLabelColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)),
            .menuItemFont(UIFont(name: "AvenirNext-Medium", size: 17.00)!),
            .unselectedMenuItemLabelColor(UIColor.black)
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
        // Hide navigation Bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Show tabBar
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
