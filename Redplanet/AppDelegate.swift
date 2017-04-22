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

GOOD GRAY
• UIColor(red:0.80, green:0.80, blue:0.80, alpha:1.0)
• #CCCCCC
 
SUPER LIGHT GREY
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

// User's relationships
// Followers, Following, Received Follow Requests, and Sent Follow Requests
var myFollowers = [PFObject]()
var myFollowing = [PFObject]()
var myRequestedFollowers = [PFObject]()
var myRequestedFollowing = [PFObject]()
var blockedUsers = [PFObject]()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver, OSPermissionObserver {

    // UIWindow
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Enable LocalDataStore()
        Parse.enableLocalDatastore()
        
        /*
         MARK: - Parse
         • Client Configuration with 
         • AWS EC2 Instance Server hosted on 
         • MLAB
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
                                            if fullMessage!.hasPrefix("\(PFUser.current()!.username!.uppercased())") {
                                                // If PFUser.currentUser()! caused
                                                // Sent notification
                                                // Set "invisible banner"
                                                let banner = Banner(title: "", subtitle: "", image: nil,
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
                                                        subtitle: "💭 \(fullMessage!)",
                                                        image: nil,
                                                        backgroundColor: UIColor(red:0.00, green:0.63, blue:1.00, alpha:1.0))
                                                    banner.adjustsStatusBarStyle = false
                                                    banner.detailLabel.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                                    banner.detailLabel.textColor = UIColor.white
                                                    banner.dismissesOnTap = true
                                                    banner.springiness = .heavy
                                                    banner.hasShadows = false
                                                    banner.alpha = 1
                                                    banner.adjustsStatusBarStyle = true
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

    
    
    // MARK: - OneSignal
    /*
     Called when the user changes Notifications Access from "off" --> "on"
     REQUIRED
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
    /**/
    
    
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

        //        self.saveContext()
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
            // Make rootVC
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = swipeNavigationController
            self.window?.makeKeyAndVisible()
            // Call relationships function
            _ = queryRelationships()
            // Check birthday
//            checkBday()
            
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
    
    
    // Function to check birthday
    func checkBday() {
        if let usersBirthday = PFUser.current()!.value(forKey: "birthday") as? String {
            // (1) Get user's birthday // MONTH DATE // 6 Characters Total
            let bEndIndex = usersBirthday.startIndex
            let bStartIndex = usersBirthday.index(bEndIndex, offsetBy: 6)
            let r = Range(uncheckedBounds: (lower: bEndIndex, upper: bStartIndex))
            let finalBday = usersBirthday[r]
            
            // (2) Change String to Date // Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd"
            let birthDate = dateFormatter.date(from: finalBday)
            
            // (3) Set up today's date as string // String
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            let todayString = formatter.string(from: date)
            
            // (4) Convert todayString to Date()
            let todayFormat = DateFormatter()
            todayFormat.dateFormat = "MMM dd"
            let today = todayFormat.date(from: todayString)

            // Send chat if it DOES NOT YET exist!!!
            if today == birthDate {
                
                let chats = PFQuery(className: "Chats")
                chats.includeKey("receiver")
                chats.whereKey("senderUsername", equalTo: "teamrp")
                chats.whereKey("receiver", equalTo: PFUser.current()!)
                chats.whereKey("Message", equalTo: "Happy Birthday \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), hope you have a great birthday with the people you love!🎉🎂🎁\n\n❤, Team Redplanet")
                chats.countObjectsInBackground(block: {
                    (count: Int32, error: Error?) in
                    if error == nil {
                        if count == 0 {
                            // Send user chat from TeamRP
                            PFUser.query()!.getObjectInBackground(withId: "NgIJplW03t") {
                                (object: PFObject?, error: Error?) in
                                if error == nil {
                                    let chats = PFObject(className: "Chats")
                                    chats["sender"] = object!
                                    chats["senderUsername"] = "teamrp"
                                    chats["receiver"] = PFUser.current()!
                                    chats["receiverUsername"] = PFUser.current()!.username!
                                    chats["read"] = false
                                    chats["saved"] = false
                                    chats["Message"] = "Happy Birthday \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), hope you have a great birthday with the people you love!🎉🎂🎁\n\n❤, Team Redplanet"
                                    chats.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            // Set visible banner
                                            let banner = Banner(title: "HAPPY BIRTHDAY 🎉🎂🎁",
                                                                subtitle: "from REDPLANET",
                                                                image: UIImage(named: "RedplanetLogo"),
                                                                backgroundColor: UIColor.white)
                                            banner.adjustsStatusBarStyle = false
                                            banner.titleLabel.font = UIFont(name: "AvenirNext-Demibold", size: 15)
                                            banner.titleLabel.textColor = UIColor.black
                                            banner.detailLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                                            banner.detailLabel.textColor = UIColor.black
                                            banner.dismissesOnTap = true
                                            banner.springiness = .heavy
                                            banner.alpha = 1
                                            banner.show(duration: 3.0)
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // Set visible banner
                                    let banner = Banner(title: "HAPPY BIRTHDAY 🎉🎂🎁",
                                                        subtitle: "from REDPLANET",
                                                        image: UIImage(named: "RedplanetLogo"),
                                                        backgroundColor: UIColor.white)
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
                            }
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
        }
    }
}
