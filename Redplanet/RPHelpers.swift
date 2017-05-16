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

class RPHelpers: NSObject {
    
    // MARK: - NotificationBanner; used to show statusbar success/error
    func showProgress(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        banner.show()
    }
    func showSuccess(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        banner.show()
    }
    
    func showError(withTitle: String?) {
        // MARK: - NotificationBannerSwift
        let banner = StatusBarNotificationBanner(title: withTitle!, style: .success)
        banner.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        banner.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        banner.show()
    }

    // MARK: - OpenWeatherMap.org API
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
    
    // MARK: - Parse; Function to check for #'s
    open func checkHash(forObject: PFObject?, forText: String?) {
        // Loop through words to check for @ prefixes
        for var word in forText!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            if word.hasPrefix("#") {
                // Get username
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Save hashtag to server
                let hashtags = PFObject(className: "Hashtags")
                hashtags["hashtag"] = word.lowercased()
                hashtags["userHash"] = "#" + word.lowercased()
                hashtags["by"] = PFUser.current()!.username!
                hashtags["pointUser"] = PFUser.current()!
                hashtags["forObjectId"] =  forObject!.objectId!
                hashtags.saveInBackground()
            }
        }
    }
    
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

    // MARK: -  Parse; Function to like object and save notification
    open func likeObject(forObject: PFObject?, notificationType: String?, activeButton: UIButton?) {
        // Disable button
        activeButton!.isUserInteractionEnabled = false
        
        let likes = PFObject(className: "Likes")
        likes["fromUser"] = PFUser.current()!
        likes["from"] = PFUser.current()!.username!
        likes["toUser"] = forObject!.value(forKey: "byUser") as! PFUser
        likes["to"] = (forObject!.value(forKey: "byUser") as! PFUser).username!
        likes["forObjectId"] = forObject!.objectId!
        likes.saveInBackground(block: { (success: Bool, error: Error?) in
            if success {
                print("Successfully saved object: \(likes)")
                
                // Re-enable button
                activeButton!.isUserInteractionEnabled = true
                
                // Change button
                activeButton!.setImage(UIImage(named: "LikeFilled"), for: .normal)
                
                // Animate like button
                UIView.animate(withDuration: 0.6 ,
                               animations: { activeButton!.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                               completion: { finish in
                                UIView.animate(withDuration: 0.5) {
                                    activeButton!.transform = CGAffineTransform.identity
                                }
                })
                
                // Save to Notification in Background
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = forObject!.value(forKey: "byUser") as! PFUser
                notifications["to"] = (forObject!.value(forKey: "byUser") as! PFUser).username!
                notifications["forObjectId"] = forObject!.objectId!
                notifications["type"] = notificationType!
                notifications.saveInBackground()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    // MARK: - Parse; Function to unlike object and remove notification
    open func unlikeObject(forObject: PFObject?, activeButton: UIButton?) {
        // Disable button
        activeButton!.isUserInteractionEnabled = false
        
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: forObject!.objectId!)
        likes.whereKey("fromUser", equalTo: PFUser.current()!)
        likes.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object.deleteInBackground()
                    
                    // Re-enable button
                    activeButton!.isUserInteractionEnabled = true
                    
                    // Set Button Image
                    activeButton!.setImage(UIImage(named: "Like"), for: .normal)
                    
                    // Animate like button
                    UIView.animate(withDuration: 0.6 ,
                                   animations: { activeButton!.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.5) {
                                        activeButton!.transform = CGAffineTransform.identity
                                    }
                    })
                    
                    // Remove from Notifications
                    let notifications = PFQuery(className: "Notifications")
                    notifications.whereKey("forObjectId", equalTo: forObject!.objectId!)
                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                    notifications.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object.deleteInBackground()
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
    
    // MARK: - Parse; Function to set likes, comments, and shares for PFObject
    func setInteractions(forObject: PFObject?, activeButton: UIButton?) {
        
    }
    
    
    // MARK: - Parse; Function to update <ChatsQueue>
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
                        object.incrementKey("score", byAmount: 1)
                        object.saveInBackground()
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    // MARK: - Parse; Function to create a new queue in <ChatsQueue>
    open func createQueue(frontUser: PFObject?, endUser: PFObject?, chatObject: PFObject?) {
        let chatsQueue = PFObject(className: "ChatsQueue")
        chatsQueue["frontUser"] = frontUser!
        chatsQueue["frontName"] = frontUser!.value(forKey: "username") as! String
        chatsQueue["endUser"] = endUser!
        chatsQueue["endName"] = endUser!.value(forKey: "username") as! String
        chatsQueue["lastChat"] = chatObject!
        chatsQueue.incrementKey("score", byAmount: 1)
        chatsQueue.saveInBackground()
    }
    
    
    // MARK: - OneSignal; Function to send Push Notifications
    open func pushNotification(toUser: PFObject?, activityType: String?) {
        // Handle nil for user's apnsId
        if let apnsId = toUser!.value(forKey: "apnsId") as? String {
            // Initialize sentence
            var sentence: String?
            // Distinguish between Chats or something else...
            if activityType == "from" {
                sentence = "from \(PFUser.current()!.username!.lowercased())"
            } else {
                sentence = "\(PFUser.current()!.username!.lowercased()) \(activityType!)"
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
