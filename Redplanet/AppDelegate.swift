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
 
 *//*

                                                             
 C O L O R S
 
 YELLOW:
 UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
 
 RED:
 UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
 
 BLUE:
 UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0)
 
 #ff004f

 
 
 */



import UIKit
import CoreData
import Foundation

import Parse
import ParseUI
import Bolts

import OneSignal
import Mixpanel


// Current Username
var username = [String]()



// User's relationships: friends, followers, and following
var myFriends = [PFObject]()
var myFollowers = [PFObject]()
var myFollowing = [PFObject]()

// Not yet confirmed: friends, followers, and following
var myRequestedFriends = [PFObject]()
var requestedToFriendMe = [PFObject]()

var myRequestedFollowers = [PFObject]()
var myRequestedFollowing = [PFObject]()




@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Power your app with local datastore
        Parse.enableLocalDatastore()
        
        
        // Initialize Pare
        // APP NAME: "R E D P L A N E T"
        Parse.setApplicationId("mvFumzoAGYENJ0vOKjKB4icwSCiRiXqbYeFs29zk",
                               clientKey: "f3YjXEEzQYU8jJq7ZQIASlqxSgDr0ZmpfYUMFPuS")
        
        
        // OneSignal for custom push notifications
        // 571bbb3a-3612-4496-b3b4-12623256782a
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "571bbb3a-3612-4496-b3b4-12623256782a",
                                        handleNotificationReceived: { (notification) in
                                            
                                            
                                            // This block gets called when the user reacts to a notification received
                                            let payload = notification?.payload
                                            let fullMessage = payload?.title
                                            
                                            print("\(fullMessage)")
                                            
                                            // Banner for notification
                                            if fullMessage!.hasPrefix("\(PFUser.current()!.username!)") {
                                                // If PFUser.currentUser()! caused
                                                // Sent notification
                                                // Set "invisible banner"
                                                let banner = Banner(title: "",
                                                                    subtitle: "",
                                                                    image: nil,
                                                                    backgroundColor: UIColor.clear
                                                )
                                                
                                                banner.dismissesOnTap = true
                                                banner.show(duration: 3.0)
                                                
                                            } else if fullMessage!.hasPrefix("from") && chatUsername.count != 0 && fullMessage!.hasSuffix(chatUsername.last!.uppercased()) {
                                                // if notificaiton titles: "from <Username>"
                                                // and PFUser.currentUser! is CURRENTLY talking to OtherUser...
                                                // Reload data for SlackChat
                                                
                                                NotificationCenter.default.post(name: rpChat, object: nil)
                                                
                                                
                                            } else {
                                                // Set visible banner
                                                let banner = Banner(title: "\(fullMessage!)",
                                                    subtitle: "",
                                                    image: nil,
                                                    backgroundColor: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                                                )
                                                banner.dismissesOnTap = true
                                                banner.show(duration: 3.0)
                                            }
                                            
                                            
                                            
                                            
            }, handleNotificationAction: { (result) in
                
                // Add action
               

                
            }, settings: [kOSSettingsKeyAutoPrompt : false, kOSSettingsKeyInFocusDisplayOption : false])
        
        
        // Ask to register for push notifications
        OneSignal.registerForPushNotifications()
        
    
        
        // MARK: - Mixpanel People Analytics
        if PFUser.current() != nil {
            
            
            // Initialize Mixpanel API
//            Mixpanel.init(token: "f3328bd382f9a28fe612f4b1e4d77923", andFlushInterval: 5)
            
//            let mixpanel = Mixpanel.initialize(token: "f3328bd382f9a28fe612f4b1e4d77923")
//            mixpanel.track(event: "Opened App",
//                           properties:["Username": "\(PFUser.currentUser()!.username!)"])

            // // Sets user 13793's "Plan" attribute to "Premium"
//            Mixpanel.mainInstance().people.set(property: "Plan",
//                                               to: "Premium")
        }
        
        
        // Call Login Function...
        // Which also calls <queryRelationships()>
        login()
        
        
        return true
    }

    
    
    
    // MARK: - Push Notifications
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        // Get user's playerId
        // this is also the user's "apnsId" in the Parse-Server
        OneSignal.idsAvailable({ (userId, pushToken) in
            print("UserId:%@", userId)
            
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userId
                PFUser.current()!.saveInBackground()
            }
            
            if (pushToken != nil) {
                print("pushToken:%@", pushToken)
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
        let username: String? = UserDefaults.standard.string(forKey: "username")
        if PFUser.current() != nil {

            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
            masterTab.tabBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
            self.window?.makeKeyAndVisible()
            window?.rootViewController = masterTab
            
            
            // Call relationships function
            queryRelationships()
            
            // Check anonymity
            anonymous()
            
            // Check birthday
            checkBirthday()
            
        } else {
            // Login or Sign Up
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let login = storyboard.instantiateViewController(withIdentifier:"loginVC") as! LoginOrSignUp
            let login = storyboard.instantiateViewController(withIdentifier:"initialVC") as! UINavigationController
            self.window?.makeKeyAndVisible()
            window?.rootViewController = login
        }
    }
    
    
    // (2) Query Relationships --- Checks all of the current user's friends, followers, and followings
    func queryRelationships() {
        // TODO::
        print("Fetching Relationships...")
        // Query Friends && Users you've requested to be friends WITH
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriends, fFriends])
        friends.includeKey("endFriend")
        friends.includeKey("frontFriend")
        friends.whereKey("isFriends", equalTo: true)
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                myFriends.removeAll(keepingCapacity: false)
                myRequestedFriends.removeAll(keepingCapacity: false)
                requestedToFriendMe.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // If FRIENDS
                    // "isFriends" == true
                    if object["endFriend"] as! PFUser == PFUser.current()! {
                        myFriends.append(object["frontFriend"] as! PFUser)
                    }
                    
                    if object["frontFriend"] as! PFUser == PFUser.current()! {
                        myFriends.append(object["endFriend"] as! PFUser)
                    }
                }
                
                
                
                
                let eFriends = PFQuery(className: "FriendMe")
                eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
                eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
                
                let fFriends = PFQuery(className: "FriendMe")
                fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
                fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
                
                let notFriends = PFQuery.orQuery(withSubqueries: [eFriends, fFriends])
                notFriends.includeKey("endFriend")
                notFriends.includeKey("frontFriend")
                notFriends.whereKey("isFriends", equalTo: false)
                notFriends.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            // PFUser.currentUser()! received a friend request
                            if object["endFriend"] as! PFUser == PFUser.current()! {
                                requestedToFriendMe.append(object["frontFriend"] as! PFUser)
                            }
                            
                            // PFUser.currentUser()! sent a friend request
                            if object["frontFriend"] as! PFUser == PFUser.current()! {
                                myRequestedFriends.append(object["endFriend"] as! PFUser)
                            }
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        
        // Query Following && Users you've requested to Follow
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
                    
                    // Is FOLLOWING
                    if object["isFollowing"] as! Bool == true {
                        myFollowing.append(object["following"] as! PFUser)
                    } else {
                        // Not FOLLOWING yet...
                        myRequestedFollowing.append(object["following"] as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        
        
        
        // Query Followers && Users who've requested to be FRIENDS with YOU
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
                    // If FOLLOWERS
                    if object["isFollowing"] as! Bool == true {
                        myFollowers.append(object["follower"] as! PFUser)
                    } else {
                        // Not a follower yet...
                        myRequestedFollowers.append(object["follower"] as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })

        
        
    }
    
    
    // (3) Anonymity Function
    func anonymous() -> Bool {
        
        
        // Set global variable
        anonymity = PFUser.current()!.value(forKey: "anonymous") as! Bool
        
        return anonymity
    }
    
    
    
    
    // (4) Check Birthday --- Checks whether today is the user's birthday or not
    func checkBirthday() {
        print("Checking birthday...")
        
        
        
        if let usersBirthday = PFUser.current()!.value(forKey: "birthday") as? String {
            
            
            // (1) Get user's birthday
            // MONTH DATE
            // 6 Characters Total
            let bEndIndex = usersBirthday.startIndex
            let bStartIndex = usersBirthday.index(bEndIndex, offsetBy: 6)
            let r = Range(uncheckedBounds: (lower: bEndIndex, upper: bStartIndex))
            let finalBday = usersBirthday[r]
            
            
            print("\nFinal Birthday is:\n\(finalBday)\n\n")
            
            // (2) Change String to Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd"
            let birthDate = dateFormatter.date(from: finalBday) // Date()
            

            // (3) Set up today's date as string
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            let todayString = formatter.string(from: date)  // String
            
            
            // (4) Convert todayString to Date()
            let todayFormat = DateFormatter()
            todayFormat.dateFormat = "MMM dd"
            let today = todayFormat.date(from: todayString)
            

            if today == birthDate {
                print("HAPPY BDAY")
                
                let alert = UIAlertController(title: "🎂 🎊 🎉\nHappy Birthday \(PFUser.current()!.username!.uppercased())",
                    message: "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String), we'll send your friends push notifications to remind them it's your birthday.",
                    preferredStyle: .alert)
                
                let ok = UIAlertAction(title: "ok",
                                       style: .default,
                                       handler: {(alertAction: UIAlertAction!) in
                                        
                                        
                                        // use this
                                        for friend in myFriends.indices {
                                            // print(friend)
                                            // TODO::
                                            // Fix the above code.
                                            // When printed, it only prints the number of friends,
                                            // in other words, the array's indices...
                                            
                                            
                                            // TODO::
                                            // Send push notification for friends
                                            
                                            //                                            if friend.value(forKey: "apnsId") != nil {
                                            //                                        // Send push notification
                                            //                                        OneSignal.postNotification(
                                            //                                            ["contents":
                                            //                                                ["en": "Today is \(PFUser.current()!.value(forKey: "realNameOfUser") as! String)'s birthday!"],
                                            //                                             "include_player_ids": ["\(myFriends[i].value(forKey: "apnsId") as! String)"]
                                            //                                            ]
                                            //                                        )
                                            //                                            }
                                        }
                                        
                                        
                                        
                                        
                                        
                })
                
                
                alert.addAction(ok)
                alert.view.tintColor = UIColor.black
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            
            
        }
 

    }
    
    
    
    
    

    // MARK: - Core Data stack
    /*
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Redplanet")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    */

    // MARK: - Core Data Saving support
    /*
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
     */

}

