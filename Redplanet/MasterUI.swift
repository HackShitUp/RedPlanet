//
//  MasterUI.swift
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

import SDWebImage
import SwipeNavigationController

class MasterUI: UITabBarController, UITabBarControllerDelegate {
    
    // Initialize AppDelegate
    let appDelegate = AppDelegate()
    
    // Array to hold chats
    var unreadChats = [PFObject]()
    
    // Function to show camera
    func showShareUI() {
        DispatchQueue.main.async {
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }
    
    // Function to fetch chats
    open func fetchChatsQueue() {
        let frontChat = PFQuery(className: "ChatsQueue")
        frontChat.whereKey("frontUser", equalTo: PFUser.current()!)
        let endChat = PFQuery(className: "ChatsQueue")
        endChat.whereKey("endUser", equalTo: PFUser.current()!)
        let chatsQueue = PFQuery.orQuery(withSubqueries: [frontChat, endChat])
        chatsQueue.whereKeyExists("lastChat")
        chatsQueue.includeKeys(["lastChat", "frontUser", "endUser"])
        chatsQueue.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.unreadChats.removeAll(keepingCapacity: false)
                for object in objects! {
                    if let lastChat = object.object(forKey: "lastChat") as? PFObject {
                        if (lastChat.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && lastChat.value(forKey: "read") as! Bool == false {
                            self.unreadChats.append(lastChat)
                        }
                    }
                }
                
                /*
                 Set UITabBar Badge Value immediately after objects were appeneded
                 This is because the request runs in the background thread and returns an empty array if handled
                 Without a completion handler
                */
                if self.unreadChats.count != 0 {
                    if #available(iOS 10.0, *) {
                        self.tabBar.items?[3].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                    }
                    self.tabBar.items?[3].badgeValue = "\(self.unreadChats.count)"
                }

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    // Function to get new follow requests
    open func getNewRequests() {
        // MARK: - AppDelegate Query Relationships
        appDelegate.queryRelationships()
        // Set UITabBar badge icon
        if myRequestedFollowers.count != 0 {
            if #available(iOS 10.0, *) {
                self.tabBar.items?[4].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            }
            self.tabBar.items?[4].badgeValue = "\(myRequestedFollowers.count)"
        }
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // MARK: - RPHelpers; add rpButton to center bottom of UIView
//        self.view.setButton(container: self.view)
//        rpButton.addTarget(self, action: #selector(showShareUI), for: .touchUpInside)
        
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
        
        // Remove UITabBar border/configure UITabBar
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        self.tabBar.isTranslucent = false
        self.tabBar.tintColor = UIColor.black
        self.tabBar.barTintColor = UIColor.white

        // Set UITabBar font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 11)!], for: .normal)
        
        // Set username to 4th UITabBar item
        if let username = PFUser.current()!.value(forKey: "username") as? String {
            self.tabBar.items?[4].title = username.lowercased()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch Unread Chats and new Follow Requests
        fetchChatsQueue()
        getNewRequests()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - UITabBarController Delegate Method
    
    
}
