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
                                        
                                        let main = (json as AnyObject).value(forKey: "main") as! NSDictionary
                                        let kelvin = main["temp"] as! Double
                                        let farenheit = (kelvin * 1.8) - 459.67
                                        let celsius = kelvin - 273.15
                                        let both = "\(Int(farenheit))°F\n\(Int(celsius))°C"
                                        
                                        // Append Temperature as String
                                        temperature.append(both)
                                        
                                    } catch let error {
                                        print(error.localizedDescription as Any)
                                        self.showError(withTitle: "Network Error")
                                    }
        }) .resume()
    }
    
    
    // MARK: -  Parse; Function to like object and save notification
    open func likeObject(forObject: PFObject?, notificationType: String?, activeButton: UIButton?) {
        let likes = PFObject(className: "Likes")
        likes["fromUser"] = PFUser.current()!
        likes["from"] = PFUser.current()!.username!
        likes["toUser"] = forObject!.value(forKey: "byUser") as! PFUser
        likes["to"] = (forObject!.value(forKey: "byUser") as! PFUser).username!
        likes["forObjectId"] = forObject!.objectId!
        likes.saveInBackground { (success: Bool, error: Error?) in
            if success {
                print("Successfully saved object: \(likes)")
                
                // Save to Notification in Background
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = forObject!.value(forKey: "byUser") as! PFUser
                notifications["to"] = (forObject!.value(forKey: "byUser") as! PFUser).username!
                notifications["forObjectId"] = forObject!.objectId!
                notifications["type"] = notificationType!
                notifications.saveInBackground()
                
                // TODO:: Change UIButton State
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // MARK: - Parse; Function to unlike object and remove notification
    open func unlikeObject(forObject: PFObject?) {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("objectId", equalTo: forObject!.objectId!)
        likes.whereKey("fromUser", equalTo: PFUser.current()!)
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object.deleteInBackground()
                    
                    // TODO:: Change UIButton state
                    
                    // Remove from Notifications
                    let notifications = PFQuery(className: "Notifications")
                    notifications.whereKey("objectId", equalTo: forObject!.objectId!)
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
        }
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
        // Initialize sentence
        var sentence: String?
        
        if activityType == "from" {
            sentence = "from \(PFUser.current()!.username!.lowercased())"
        } else {
            sentence = "\(PFUser.current()!.username!.lowercased()) \(activityType!)"
        }
        
        // MARK: - OneSignal
        OneSignal.postNotification(
            ["contents": ["en": "\(sentence!)"],
             "include_player_ids": ["\(toUser!.value(forKey: "apnsId") as! String)"],
             "ios_badgeType": "Increase",
             "ios_badgeCount": 1
            ]
        )
    }
   
}
