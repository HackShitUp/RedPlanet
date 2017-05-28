 //
//  AppDelegate.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//
/*
  
  "Have I not commanded you? Be strong and courageous. 
  Do not be afraid; do not be discouraged, for the Lord
  your God will be with you wherever you go.”
  - Joshua 1:9
  
  How does it feel?
  How does it feel?
  To be without a home?
  Like a complete unknown?
  Like a rolling stone ?
  - Bob Dylan

  
  
RED:
• UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
• #FF0050

PURPLE
• UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
• #BD0FE1

BLUE:
• UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
• #00A1FF

GOOD GRAY
• UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1)
• #CCCCCC

SUPER LIGHT GREY
• UIColor(red: 0.96, green: 0.95, blue: 0.95, alpha: 1)

YELLOW:
• UIColor(red: 1, green: 0.86, blue: 0, alpha: 1)
*/

import UIKit
import CoreData
import Foundation

import Parse
import ParseUI
import Bolts

import NotificationBannerSwift
import OneSignal
import SwipeNavigationController
import SDWebImage

// User's relationships
// Followers, Following, Received Follow Requests, and Sent Follow Requests
var currentFollowers = [PFObject]()
var currentFollowing = [PFObject]()
var currentRequestedFollowers = [PFObject]()
var currentRequestedFollowing = [PFObject]()
var blockedUsers = [PFObject]()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver, OSPermissionObserver {

    // UIWindow
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Enable LocalDataStore()
        Parse.enableLocalDatastore()
        
        /*
         MARK: - Parse; Client Configuration
         • AWS EC2 Instance Server
         • Database hosted on MLAB
        */
        let configuration = ParseClientConfiguration {
            $0.applicationId = "mvFumzoAGYENJ0vOKjKB4icwSCiRiXqbYeFs29zk"
            $0.clientKey = "f3YjXEEzQYU8jJq7ZQIASlqxSgDr0ZmpfYUMFPuS"
            $0.server = "http://parseserver-48bde-env.us-east-1.elasticbeanstalk.com/parse/"
        }
        Parse.initialize(with: configuration)
        
        /*
        MARK: - OneSignal
        • Used for custom push notifications
        • APP_ID: 571bbb3a-3612-4496-b3b4-12623256782a
        */
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "571bbb3a-3612-4496-b3b4-12623256782a",
                                        handleNotificationReceived: { (notification) in
                                            
                                            // This block gets called when the user reacts to a notification received
                                            let payload = notification?.payload
                                            let fullMessage = payload?.body

                                            // Banner for notification
                                            if fullMessage!.hasPrefix("\(PFUser.current()!.username!.lowercased())") {
                                                // If PFUser.currentUser()! sent notification to self, do nothing
                                                print("Received notification for the current user...")
                                                
                                            } else if fullMessage!.hasSuffix("requested to follow you") {
                                                // Reload data
                                                let masterUI = MasterUI()
                                                masterUI.getNewRequests()
                                            
                                            } else if chatUsername.count != 0 && chatUserObject.count != 0 {
                                                if fullMessage!.hasPrefix("from") && fullMessage!.hasSuffix("\(chatUsername.last!.uppercased())") {
                                                    // if notificaiton titles: "from <Username>"
                                                    // and PFUser.currentUser! is CURRENTLY talking to OtherUser...
                                                    // Reload data for Chats
                                                    NotificationCenter.default.post(name: rpChat, object: nil)
                                                    
                                                } else if fullMessage!.hasSuffix("is typing...") {
                                                    // SHOW that the user is typing
                                                    // Set visible banner
                                                    // MARK: - NotitficationBanner
                                                    let banner = NotificationBanner(title: "", subtitle: "\(fullMessage!)", leftView: UIImageView(image: UIImage(named: "ChatsPurple")))
                                                    banner.subtitleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                                    banner.subtitleLabel?.textColor = UIColor.white
                                                    banner.roundAllCorners(sender: banner)
                                                    banner.backgroundColor = UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0)
                                                    banner.show()
                                                }
                                                
                                            } else {
                                                // MARK: - NotitficationBanner
                                                let banner = NotificationBanner(title: "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String):", subtitle: "\(fullMessage!)", leftView: UIImageView(image: UIImage(named: "RPLogo")))
                                                banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                                banner.titleLabel?.textColor = UIColor.black
                                                banner.subtitleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 15)
                                                banner.subtitleLabel?.textColor = UIColor.darkGray
                                                banner.roundAllCorners(sender: banner)
                                                banner.backgroundColor = UIColor.white
                                                banner.show()
                                            }
                                            
                                            
            }, handleNotificationAction: { (result) in
               // Action
            }, settings: [kOSSettingsKeyAutoPrompt : false, kOSSettingsKeyInFocusDisplayOption : false])
        
        
        /*
         MARK: - OneSignal
         Call when you want to prompt the user to accept push notifications.
         Only call once and only if you set kOSSettingsKeyAutoPrompt in AppDelegate to false.
         */
        // (1) Add observers
        OneSignal.add(self as OSPermissionObserver)
        OneSignal.add(self as OSSubscriptionObserver)
        // (2) Check for authorization status
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        if status.permissionStatus.status == .authorized {
        // AUTHORIZED
            let userID = status.subscriptionStatus.userId
            print("\nThe userID is: \(String(describing: userID))\n")
            
            // MARK: - Parse --> Save user's apnsId to server
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userID
                PFUser.current()!.saveInBackground()
            }
            
        } else if status.permissionStatus.status == .denied {
        // DENIED
            print("Denied")
            print("isSubscribed: \(status.subscriptionStatus.subscribed)")
        } else {
        // UNKNOWN
            // Prompt for OneSignal's Push Notifications
            OneSignal.promptForPushNotifications { (enabled: Bool) in
                if enabled == true {
                    // Subscribe to OS push notifications
                    OneSignal.setSubscription(true)
                } else {
                    // DON'T subscribe OS push notifications
                    OneSignal.setSubscription(false)
                }
            }
        }
        
        // Call Login Function
        // Which also calls queryRelationships()
        login()
        
        return true
    }

    
    
    /*
    // MARK: - OneSignal; REQUIRED
    Called when the user changes Notifications Access from "off" --> "on"
    */
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            print("Subscribed for OneSignal push notifications!")
            
            let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
            let userID = status.subscriptionStatus.userId
            print("THE userID = \(String(describing: userID))\n\n")
            
            // MARK: - Parse
            // Save user's apnsId to server
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userID
                PFUser.current()!.saveInBackground()
            }
        }
    }
    
    func onOSPermissionChanged(_ stateChanges: OSPermissionStateChanges!) {
        if stateChanges.from.status == .notDetermined || stateChanges.from.status == .denied {
            if stateChanges.to.status == .authorized {
                print("-AUTHORIZED-")
            }
        }
    }
    // end OneSignal
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting
        print("userSubscriptionSetting = \(userSubscriptionSetting)")
        let userID = status.subscriptionStatus.userId
        print("HERE\n===userID = \(String(describing: userID))")
        let pushToken = status.subscriptionStatus.pushToken
        print("pushToken = \(String(describing: pushToken))")
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
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    
    
    // FUNCTION - Login; Uses iPhone disk CoreData and UserDefaults to check whether is currently logged in or not.
    func login() {
        // Remember user's login
        // By setting their username
        if PFUser.current() != nil {
            
            // MARK: - HEAP
//            // Set App ID
//            Heap.setAppId("3455525110");
//            // Track Who Opens the App
//            Heap.track("AppOpen", withProperties:
//                ["byUserId": "\(PFUser.current()!.objectId!)",
//                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
//                ])
//            // Attach a unique identifier to user
//            Heap.identify("\(PFUser.current()!.objectId!)")
//            Heap.addUserProperties([
//                "UserId": "\(PFUser.current()!.objectId!)",
//                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)",
//                "Email": "\(PFUser.current()!.email!)"
//                ])
            
            #if DEBUG
                Heap.enableVisualizer();
            #endif
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            // MARK: - SwipeNavigationController
            let cameraVC = storyboard.instantiateViewController(withIdentifier: "center") as! UINavigationController
            let swipeNavigationController = SwipeNavigationController(centerViewController: cameraVC)
            swipeNavigationController.rightViewController = storyboard.instantiateViewController(withIdentifier: "right") as! UINavigationController
            swipeNavigationController.leftViewController = storyboard.instantiateViewController(withIdentifier: "left") as! UINavigationController
            swipeNavigationController.bottomViewController = storyboard.instantiateViewController(withIdentifier: "masterUI") as! MasterUI
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
    
    
    // FUNCTION - Query Relationships; Checks all of the current user's friends, followers, and followings, and blocked users
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
                currentFollowing.removeAll(keepingCapacity: false)
                currentRequestedFollowing.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    // Append currently following accounts
                    if object.value(forKey: "isFollowing") as! Bool == true {
                        currentFollowing.append(object.object(forKey: "following") as! PFUser)
                    } else {
                        // Append requested following accounts
                        currentRequestedFollowing.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
                if (error?.localizedDescription.contains("invalid session token"))! {
                    self.logout()
                }
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
                currentFollowers.removeAll(keepingCapacity: false)
                currentRequestedFollowers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append current followers
                    if object.value(forKey: "isFollowing") as! Bool == true {
                        currentFollowers.append(object.object(forKey: "follower") as! PFUser)
                    } else {
                    // Append accounts requested to follow you
                        currentRequestedFollowers.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
                if (error?.localizedDescription.contains("invalid session token"))! {
                    self.logout()
                }
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
                if (error?.localizedDescription.contains("invalid session token"))! {
                    self.logout()
                }
            }
        }
    }
    
    
    // FUNCTION - Logout
    func logout() {
        // Remove logged in user from app memory
        PFUser.logOutInBackground(block: { (error: Error?) in
            if error == nil {
                DispatchQueue.main.async(execute: {
                    // Login or Sign Up
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let login = storyboard.instantiateViewController(withIdentifier:"initialVC") as! UINavigationController
                    self.window?.makeKeyAndVisible()
                    self.window?.rootViewController = login
                })
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
}
