//
//  MasterUI.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SDWebImage
import SwipeNavigationController


/*
 UITabBarController Class that manages the bottom tab-bar of the Application
 ie: Home, Explore, Camera button, Chats, and Profile. 
 This class also manages 3 important functions. Also, 2 of the last noted below are open functions accessible anywhere:
 
 
 (1) setButton() - Configures the camera button in the tab bar.
 (2) fetchChatsQueue() - Gets unread chats from the database class, "ChatsQueue" and configures the UITabBar badge icon.
 (3) getNewRequests() - Gets new follow requests from the database class, "FollowMe" and configures the UITabBar badge icon.
 
 */

class MasterUI: UITabBarController, UITabBarControllerDelegate, SwipeNavigationControllerDelegate {
    
    // Initialize lastIndex for UITabBarController's selectedIndex
    var lastIndex: Int? = 0
    
    // Initialize AppDelegate
    let appDelegate = AppDelegate()
    
    // Array to hold chats
    var unreadChats = [PFObject]()

    // FUNCTION - Show Camera
    func showShareUI() {
        DispatchQueue.main.async {
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }
    
    // FUCNTION - Fetch Chats
    open func fetchChatsQueue(completionHandler: @escaping (_ count: Int) -> ()) {
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
                
                // Pass unreadChats count in completionHandler
                completionHandler(self.unreadChats.count)

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    // FUNCTION - Get new follow requests
    open func getNewRequests(completionHandler: @escaping (_ count: Int) -> ()) {
        // MARK: - AppDelegate Query Relationships
        appDelegate.queryRelationships()
        
        // Pass new followRequests count in completionHandler
        completionHandler(currentRequestedFollowers.count)
    }
    
    
    // MARK: - SwipeNavigationController Delegate Method
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        self.selectedIndex = self.lastIndex!
    }
    
    
    // MARK: - UIView Life Cycle
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

        // Set UITabBar's tintColor
        self.tabBar.tintColor = UIColor.black
        self.tabBar.barTintColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure AVAudioSession
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                            with: [.duckOthers, .defaultToSpeaker])
        } catch {
            print("AVAudioSession; failed to set background audio preference")
        }
        
        // Remove UITabBar border/configure UITabBar
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.shadowImage = UIImage()
        self.tabBar.isTranslucent = false
        self.tabBar.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        self.tabBar.barTintColor = UIColor.white

        // Set UITabBar font
        UITabBarItem.appearance().setTitleTextAttributes(
            [NSFontAttributeName: UIFont(name: "AvenirNext-Demibold",
                                         size: 11)!], for: .normal)
        
        // Set username to 4th UITabBar item
        if let username = PFUser.current()!.value(forKey: "username") as? String {
            if username.characters.count > 6 {
                let firstSix = String(username.characters.prefix(6))
                self.tabBar.items?[4].title = "\(firstSix.uppercased())..."
            } else {
                self.tabBar.items?[4].title = "\(username.uppercased())"
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.delegate = self
        
        // Set delegate
        self.tabBarController?.delegate = self
        
        // Fetch Unread Chats
        self.fetchChatsQueue { (count) in
            if count != 0 {
                DispatchQueue.main.async(execute: {
                    if #available(iOS 10.0, *) {
                        self.tabBar.items?[3].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                    }
                    self.tabBar.items?[3].badgeValue = "\(count)"
                })
            } else {
                self.tabBar.items?[3].badgeValue = nil
            }
        }
        // Get New Follow Requests
        self.getNewRequests { (count) in
            // Set UITabBar badge icon
            if count != 0 {
                if #available(iOS 10.0, *) {
                    self.tabBar.items?[4].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                }
                self.tabBar.items?[4].badgeValue = "\(currentRequestedFollowers.count)"
            } else {
                self.tabBar.items?[4].badgeValue = nil
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - UITabBarController Delegate Methods
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Pass last selectedIndex and pass it to class' variable; lastIndex
        switch item {
            case self.tabBar.items![0]:
            self.lastIndex = 0
            case self.tabBar.items![1]:
            self.lastIndex = 1
            case self.tabBar.items![2]:
                // MARK: - SwipeNavigationController
                self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
            case self.tabBar.items![3]:
            self.lastIndex = 3
            case self.tabBar.items![4]:
            self.lastIndex = 4
        default:
            break;
        }
    }
}
