//
//  RPHelpers.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

import NotificationBannerSwift
import OneSignal
import Parse
import ParseUI
import Bolts


/*
 CUSTOM CLASS USED PERSISTENTLY THROUGHOUT THE APP
 */

class RPHelpers: NSObject {
    /**************************************************************************************************
    // MARK: - NotificationBanner; used to show statusbar progress/success/error --> Color variations
    **************************************************************************************************/
    func showAction(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor.darkGray
        banner.duration = 0.20
        banner.show()
    }
    
    func showProgress(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        banner.duration = 0.20
        banner.show()
    }
    
    func showSuccess(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        banner.duration = 0.20
        banner.show()
    }
    
    func showError(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        banner.duration = 0.20
        banner.show()
    }

    
    
    /******************************************************************************************
    // MARK: - OpenWeatherMap.org API
    *******************************************************************************************/
    open func getWeather(lat: CLLocationDegrees, lon: CLLocationDegrees) {
        // Clear global array --> "CapturedStill.swift"
        temperature.removeAll(keepingCapacity: false)
        
        // MARK: - OpenWeatherMap API
        URLSession.shared.dataTask(with: URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=0abf9dff54ea3ccb6561c3574557594c")!,
                                   completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                                    if error != nil {
                                        print(error?.localizedDescription as Any)
                                        self.showError(withTitle: "Network Error")
                                        return
                                    }
                                    do  {
                                        // Traverse JSON data to "Mutable Containers"
                                        let json = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                                        
                                        // Optionally chain NSDictionary value to prevent from crashing...
                                        if let main = (json as AnyObject).value(forKey: "main") as? NSDictionary {
                                            let kelvin = main["temp"] as! Double
                                            let farenheit = (kelvin * 1.8) - 459.67
                                            let celsius = kelvin - 273.15
                                            let both = "\(Int(farenheit))°F\n\(Int(celsius))°C"
                                            // Append Temperature as String
                                            temperature.append(both)
                                        }
                                        
                                    } catch let error {
                                        print(error.localizedDescription as Any)
                                        self.showError(withTitle: "Network Error")
                                    }
        }) .resume()
    }
    
    
    
    /******************************************************************************************
    // MARK: - Parse; Function to check for #'s and @'s
    *******************************************************************************************/
    // Check for #'s
    open func checkHash(forObject: PFObject?, forText: String?) {
        // Loop through words to check for @ prefixes
        for var word in forText!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            if word.hasPrefix("#") {
                // Get username
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                print("FOR OBJECT: \(forObject!)\n")
                // Save hashtag to server
                let hashtags = PFObject(className: "Hashtags")
                hashtags["hashtag"] = "#" + word.lowercased()
                hashtags["byUsername"] = PFUser.current()!.username!
                hashtags["byUser"] = PFUser.current()!
                hashtags["forObjectId"] =  forObject?.objectId!
                hashtags.saveInBackground()
            }
        }
    }
    
    // Check for @'s
    open func checkTags(forObject: PFObject?, forText: String?, postType: String?) {
        // Loop through words to check for @ prefixes
        for var word in forText!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            // Define @username
            if word.hasPrefix("@") {
                // Get username
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                // Look for user
                let user = PFUser.query()!
                user.whereKey("username", equalTo: word.lowercased())
                user.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            // Send mention to Parse server, class "Notifications"
                            let notifications = PFObject(className: "Notifications")
                            notifications["from"] = PFUser.current()!.username!
                            notifications["fromUser"] = PFUser.current()!
                            notifications["type"] = "tag \(postType!)"
                            notifications["forObjectId"] = forObject!.objectId!
                            notifications["to"] = word
                            notifications["toUser"] = object
                            notifications.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    print("Successfully saved tag in notifications: \(notifications)")
                                    
                                    // MARK: - RPHelpers; send push notification if user's apnsId is not nil
                                    if object.value(forKey: "apnsId") != nil {
                                        switch postType! {
                                            case "tp":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Text Post")
                                            case "ph":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Photo")
                                            case "pp":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Profile Photo")
                                            case "vi":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Video")
                                            case "sp":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Space Post")
                                            case "co":
                                            self.pushNotification(toUser: object, activityType: "tagged you in a Comment")
                                        default:
                                            break
                                        }
                                    }
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
        }
    }
    
    
    
    /******************************************************************************************
    //  MARK: - Reactions Like Function; Called to like/unlike posts in Stories
    *******************************************************************************************/
    // Like Post
    open func reactLike(forPostObject: PFObject) {
        // LIKE POST
        let likes = PFObject(className: "Likes")
        likes["fromUser"] = PFUser.current()!
        likes["from"] = PFUser.current()!.username!
        likes["forObjectId"] = forPostObject.objectId!
        likes["toUser"] = forPostObject.object(forKey: "byUser") as! PFUser
        likes["to"] = (forPostObject.object(forKey: "byUser") as! PFUser).username!
        likes.saveInBackground(block: { (success: Bool, error: Error?) in
            if error == nil {
                print("Successfully liked post: \(likes)")
                
                // MARK: - NotificationBannerSwift
                let banner = NotificationBanner(title: "", subtitle: nil, rightView: UIImageView(image: UIImage(named: "HeartFilled")!))
                banner.backgroundColor = UIColor.clear
                banner.duration = 0.20
                banner.show()
                
                // Save to Notifications
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = forPostObject.object(forKey: "byUser") as! PFUser
                notifications["to"] = (forPostObject.object(forKey: "byUser") as! PFUser).username!
                notifications["forObjectId"] = forPostObject.objectId!
                notifications["type"] = "like \(forPostObject.value(forKey: "contentType") as! String)"
                notifications.saveInBackground()
                
                // MARK: - Self; pushNotification
                switch forPostObject.value(forKey: "contentType") as! String {
                case "tp":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Text Post")
                case "ph":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Photo")
                case "pp":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Profile Photo")
                case "vi":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Video")
                case "sp":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Space Post")
                case "itm":
                    self.pushNotification(toUser: forPostObject.object(forKey: "byUser") as! PFUser,
                                          activityType: "liked your Moment")
                default:
                    break;
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // Show Error
                self.showError(withTitle: "Network Error")
            }
        })
    }
    
    /******************************************************************************************
    // MARK: - Reactions Unlike Function
    *******************************************************************************************/
    // Unlike post
    open func reactUnlike(forLikeObject: PFObject, forPostObject: PFObject) {
        forLikeObject.deleteInBackground(block: { (success: Bool, error: Error?) in
            if success {
                print("Deleted from <Likes>: \(forLikeObject)")
                
                // MARK: - NotificationBannerSwift
                let banner = NotificationBanner(title: "", subtitle: nil, rightView: UIImageView(image: UIImage(named: "HeartBroken")!))
                banner.backgroundColor = UIColor.clear
                banner.duration = 0.20
                banner.show()
                
                // Delete from Notifications
                let notifications = PFQuery(className: "Notifications")
                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                notifications.whereKey("forObjectId", equalTo: forPostObject.objectId!)
                notifications.whereKey("type", equalTo: "like \(forPostObject.value(forKey: "contentType") as! String)")
                notifications.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            object.deleteInBackground()
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        // Show Error
                        self.showError(withTitle: "Network Error")
                    }
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // Show Error
                self.showError(withTitle: "Network Error")
            }
        })
    }

    
    
    /******************************************************************************************
    // MARK: - Parse; Function to update <ChatsQueue>'s pointer, "lastChat" in Database and Server
    *******************************************************************************************/
    open func updateQueue(chatQueue: PFObject?, userObject: PFObject?) {
        let frontChat = PFQuery(className: "ChatsQueue")
        frontChat.whereKey("frontUser", equalTo: PFUser.current()!)
        frontChat.whereKey("endUser", equalTo: userObject!)
        
        let endChat = PFQuery(className: "ChatsQueue")
        endChat.whereKey("endUser", equalTo: PFUser.current()!)
        endChat.whereKey("frontUser", equalTo: userObject!)
        
        let chats = PFQuery.orQuery(withSubqueries: [frontChat, endChat])
        chats.whereKeyExists("lastChat")
        chats.includeKeys(["lastChat", "frontUser", "endUser"])
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Create Queue
                if objects!.isEmpty {
                    _ = self.createQueue(frontUser: PFUser.current()!, endUser: userObject!, chatObject: chatQueue)
                } else {
                    // Update Queue
                    for object in objects! {
                        object["lastChat"] = chatQueue
                        object.saveInBackground()
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    /******************************************************************************************
    // MARK: - Parse; Function to create a new queue in <ChatsQueue>
    *******************************************************************************************/
    open func createQueue(frontUser: PFObject?, endUser: PFObject?, chatObject: PFObject?) {
        let chatsQueue = PFObject(className: "ChatsQueue")
        chatsQueue["frontUser"] = frontUser!
        chatsQueue["frontName"] = frontUser!.value(forKey: "username") as! String
        chatsQueue["endUser"] = endUser!
        chatsQueue["endName"] = endUser!.value(forKey: "username") as! String
        chatsQueue["lastChat"] = chatObject!
        chatsQueue.saveInBackground()
    }
    
    
    
    /******************************************************************************************
    // MARK: - OneSignal; Function to send Push Notifications
    *******************************************************************************************/
    open func pushNotification(toUser: PFObject?, activityType: String?) {
        // Handle nil for user's apnsId
        if let apnsId = toUser!.value(forKey: "apnsId") as? String {
            // Initialize sentence
            var sentence: String?
            // Distinguish between Chats or something else...
            if activityType == "from" {
                sentence = "from \(PFUser.current()!.username!.uppercased())"
            } else {
                sentence = "\(PFUser.current()!.username!.uppercased()) \(activityType!)"
            }
            
            // MARK: - OneSignal
            OneSignal.postNotification(
                ["contents": ["en": "\(sentence!)"],
                 "include_player_ids": ["\(apnsId)"],
                 "ios_badgeType": "Increase",
                 "ios_badgeCount": 1])
        }
    }
}
