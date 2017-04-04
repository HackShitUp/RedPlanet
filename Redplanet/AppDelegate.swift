//
//  AppDelegate.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//



/*
                                                            How does it feel?
 
                                                            How does it feel?
 
                                                            To be without a home?
 
                                                            Like a complete unknown?
 
                                                            Like a rolling stone ?

RED:
• UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
• #FF0050

PURPLE
• UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
• #BD0FE1

BLUE:
• UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
• #00A1FF
 
LIGHT GREY
• UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)

YELLOW:
• UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0)
 */

import UIKit
import CoreData
import Foundation

import Parse
import ParseUI
import Bolts

import OneSignal
import SwipeNavigationController
import SDWebImage

// Current Username
var username = [String]()

// User's relationships
// Followers, Following, Received Follow Requests, and Sent Follow Requests
var myFollowers = [PFObject]()
var myFollowing = [PFObject]()
var myRequestedFollowers = [PFObject]()
var myRequestedFollowing = [PFObject]()
var blockedUsers = [PFObject]()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // UIWindow
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Power your app with local datastore
        Parse.enableLocalDatastore()
        
        // Configure Parse Hosted Server MLAB on AWS
        let configuration = ParseClientConfiguration {
            $0.applicationId = "mvFumzoAGYENJ0vOKjKB4icwSCiRiXqbYeFs29zk"
            $0.clientKey = "f3YjXEEzQYU8jJq7ZQIASlqxSgDr0ZmpfYUMFPuS"
            $0.server = "http://parseserver-48bde-env.us-east-1.elasticbeanstalk.com/parse/"
        }
        Parse.initialize(with: configuration)
        
        // OneSignal for custom push notifications
        // 571bbb3a-3612-4496-b3b4-12623256782a
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "571bbb3a-3612-4496-b3b4-12623256782a",
                                        handleNotificationReceived: { (notification) in
                                            
                                            // This block gets called when the user reacts to a notification received
                                            let payload = notification?.payload
                                            let fullMessage = payload?.body

                                            // Banner for notification
                                            if fullMessage!.hasPrefix("\(PFUser.current()!.username!.uppercased())") {
                                                // If PFUser.currentUser()! caused
                                                // Sent notification
                                                // Set "invisible banner"
                                                let banner = Banner(title: "",
                                                                    subtitle: "",
                                                                    image: nil,
                                                                    backgroundColor: UIColor.clear
                                                )
                                                
                                                banner.dismissesOnTap = true
                                                banner.show(duration: 0.0)
                                                
                                                
                                            } else if chatUsername.count != 0 && chatUserObject.count != 0 {
                                                if fullMessage!.hasPrefix("from") && fullMessage!.hasSuffix("\(chatUsername.last!.uppercased())") {
                                                    // if notificaiton titles: "from <Username>"
                                                    // and PFUser.currentUser! is CURRENTLY talking to OtherUser...
                                                    // Reload data for Chats
                                                    NotificationCenter.default.post(name: rpChat, object: nil)
                                                    
                                                } else if fullMessage!.hasSuffix("is typing...") {
                                                    // SHOW that the user is typing
                                                    // Set visible banner
                                                    let banner = Banner(title: nil,
                                                        subtitle: "\(fullMessage!)",
                                                        image: UIImage(named: "RedplanetLogo"),
                                                        backgroundColor: UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0))
                                                    banner.adjustsStatusBarStyle = false
                                                    banner.detailLabel.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                                    banner.detailLabel.textColor = UIColor.white
                                                    banner.dismissesOnTap = true
                                                    banner.springiness = .heavy
                                                    banner.hasShadows = false
                                                    banner.alpha = 1
                                                    banner.show(duration: 3.0)
                                                }
                                                
                                            } else {
                                                // Set visible banner
                                                let banner = Banner(title: "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String):",
                                                    subtitle: "\(fullMessage!)",
                                                    image: UIImage(named: "RedplanetLogo"),
                                                    backgroundColor: UIColor.white
                                                )
                                                banner.adjustsStatusBarStyle = false
                                                banner.titleLabel.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                                banner.titleLabel.textColor = UIColor.black
                                                banner.detailLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                                                banner.detailLabel.textColor = UIColor.black
                                                banner.dismissesOnTap = true
                                                banner.springiness = .heavy
                                                banner.alpha = 1
                                                banner.show(duration: 3.0)
                                            }
                                            
                                            
            }, handleNotificationAction: { (result) in
               // Action
                
            }, settings: [kOSSettingsKeyAutoPrompt : false, kOSSettingsKeyInFocusDisplayOption : false])
        
        
        // Ask to register for push notifications
        OneSignal.registerForPushNotifications()

        // MARK: - HEAP Analytics
        if PFUser.current() != nil {
            // Set App ID
            Heap.setAppId("3455525110");
            // Track Who Opens the App
            Heap.track("AppOpen", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            // Attach a unique identifier to user
            Heap.identify("\(PFUser.current()!.objectId!)")
            Heap.addUserProperties([
                "UserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)",
                "Email": "\(PFUser.current()!.email!)"
                ])
            
            #if DEBUG
                Heap.enableVisualizer();
            #endif
        }
        
        
        // Call Login Function
        // Which also calls queryRelationships()
        login()
        
        return true
    }
    
    // MARK: - Push Notifications
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        // Get user's playerId
        // this is also the user's "apnsId" in the Parse-Server
        OneSignal.idsAvailable({ (userId, pushToken) in
            print("• UserId:%@", userId as Any)
            
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userId
                PFUser.current()!.saveInBackground()
            }
            
            if (pushToken != nil) {
                print("• PushToken:%@", pushToken ?? "")
            }
        })
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // Set again in Application's data
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        // Print error
        print(error.localizedDescription)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        
        /*
         This is when the app exits.
         */
        
        print("IDL")
        
        
//        // Track Who Opens the App
//        Heap.track("AppOpen", withProperties:
//            ["byUserId": "\(PFUser.current()!.objectId!)",
//                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
//            ])

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        /*
         This is IMMEDIATELY AFTER the app exits.
         */
        
        print("EXITED")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        /*
         This is when the app re-opens without ending it
         */
        
        print("Opened?")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.

        //        self.saveContext()
        
        /*
         This is when the app TERMINATES for good
         */
        
        print("ENDED")
    }
    
    
    
    // MARK: - Redplanet VIP Functions
    // (1) Login ---- Uses iPhone disk CoreData and UserDefaults to check whether is currently logged in or not.
    func login() {
        // Remember user's login
        // By setting their username
        if PFUser.current() != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            // MARK: - SwipeNavigationController
            let cameraVC = storyboard.instantiateViewController(withIdentifier: "center") as! UINavigationController
            let swipeNavigationController = SwipeNavigationController(centerViewController: cameraVC)
            swipeNavigationController.topViewController = storyboard.instantiateViewController(withIdentifier: "top") as! UINavigationController
            swipeNavigationController.rightViewController = storyboard.instantiateViewController(withIdentifier: "right") as! UINavigationController
            swipeNavigationController.leftViewController = storyboard.instantiateViewController(withIdentifier: "left") as! UINavigationController
            swipeNavigationController.bottomViewController = storyboard.instantiateViewController(withIdentifier: "mainUITab") as! MainUITab
            swipeNavigationController.setNeedsStatusBarAppearanceUpdate()
            // Set status bar
            UIApplication.shared.isStatusBarHidden = false
            UIApplication.shared.statusBarStyle = .lightContent
            // Make rootVC
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = swipeNavigationController
            self.window?.makeKeyAndVisible()
            
            // Call relationships function
            _ = queryRelationships()
        } else {
            // Login or Sign Up
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let login = storyboard.instantiateViewController(withIdentifier:"initialVC") as! UINavigationController
            self.window?.makeKeyAndVisible()
            window?.rootViewController = login
        }
    }
    
    
    // (2) Query Relationships
    // --- Checks all of the current user's friends, followers, and followings, and blocked users
    func queryRelationships() {
        // (1) Query Following
        // && Users you've requested to Follow
        let following = PFQuery(className: "FollowMe")
        following.includeKey("following")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.order(byDescending: "createdAt")
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                myFollowing.removeAll(keepingCapacity: false)
                myRequestedFollowing.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    // Append currently following accounts
                    if object.value(forKey: "isFollowing") as! Bool == true {
                        myFollowing.append(object.object(forKey: "following") as! PFUser)
                    } else {
                        // Append requested following accounts
                        myRequestedFollowing.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })

        // (2) Query Followers 
        // && Users who've requested to be FRIENDS with YOU
        let followers = PFQuery(className: "FollowMe")
        followers.includeKey("follower")
        followers.whereKey("following", equalTo: PFUser.current()!)
        followers.order(byDescending: "createdAt")
        followers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                myFollowers.removeAll(keepingCapacity: false)
                myRequestedFollowers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append current followers
                    if object.value(forKey: "isFollowing") as! Bool == true {
                        myFollowers.append(object.object(forKey: "follower") as! PFUser)
                    } else {
                    // Append accounts requested to follow you
                        myRequestedFollowers.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        // (3) Query BLOCKED
        let blockedBy = PFQuery(className: "Blocked")
        blockedBy.whereKey("byUser", equalTo: PFUser.current()!)
        blockedBy.whereKey("toUser", notEqualTo: PFUser.current()!)
        let blockedTo = PFQuery(className: "Blocked")
        blockedTo.whereKey("toUser", equalTo: PFUser.current()!)
        blockedTo.whereKey("byUser", notEqualTo: PFUser.current()!)
        let block = PFQuery.orQuery(withSubqueries: [blockedBy, blockedTo])
        block.includeKeys(["byUser", "toUser"])
        block.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                blockedUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Append people you've blocked
                    if (object.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        blockedUsers.append(object.object(forKey: "toUser") as! PFUser)
                    } else if (object.object(forKey: "toUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    // Append people who've blocked you
                        blockedUsers.append(object.object(forKey: "byUser") as! PFUser)
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }// end QueryRelationships()
}
