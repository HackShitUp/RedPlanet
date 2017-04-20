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

import OneSignal
import Parse
import ParseUI
import Bolts

/*
 MARK: - Extensions add a shuffle() method to any mutable collection and a shuffled() method to any sequence
 */
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of given collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}
extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}


/*
 MARK: - DateComponents Time Display
 • getFullTime() = calculate time with full text
 • getShortTime() = calculate time with shortened text
 */
extension DateComponents {
    
    // Get Full Time
    func getFullTime(difference: DateComponents?, date: Date?) -> String {
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference!.second! <= 0 {
            return "now"
        } else if difference!.second! > 0 && difference!.minute! == 0 {
            if difference!.second! == 1 {
                return "1 second ago"
            }
            return "\(difference!.second!) seconds ago"
            
        } else if difference!.minute! > 0 && difference!.hour! == 0 {
            if difference!.minute! == 1 {
                return "1 minute ago"
            }
            return "\(difference!.minute!) minutes ago"
            
        } else if difference!.hour! > 0 && difference!.day! == 0 {
            if difference!.hour! == 1 {
                return "1 hour ago"
            }
            return "\(difference!.hour!) hours ago"
        } else if difference!.day! > 0 && difference!.weekOfMonth! == 0 {
            if difference!.day! == 1 {
                return "1 day ago"
            }
            
            return "\(difference!.day!) days ago"
        }
        
        let createdDate = DateFormatter()
        createdDate.dateFormat = "MMM dd"
        return createdDate.string(from: date!)
    }
    
    // Get Time w/Shortened Text
    func getShortTime(difference: DateComponents?, date: Date?) -> String {
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference!.second! <= 0 {
            return "now"
        } else if difference!.second! > 0 && difference!.minute! == 0 {
            return "\(difference!.second!)s ago"
            
        } else if difference!.minute! > 0 && difference!.hour! == 0 {
            return "\(difference!.minute!)m ago"
            
        } else if difference!.hour! > 0 && difference!.day! == 0 {
            if difference!.hour! == 1 {
                return "1hr ago"
            }
            return "\(difference!.hour!)hrs ago"
        } else if difference!.day! > 0 && difference!.weekOfMonth! == 0 {

            return "\(difference!.day!)d ago"
        }
        
        let createdDate = DateFormatter()
        createdDate.dateFormat = "MMM dd"
        return createdDate.string(from: date!)
    }
}


// MARK: - UINavigationBar design configuration
/*
 'Whitens-out' the UINavigationbar and removes the lower grey line border
 (1) Shows the UINavigationBar
 (2) Set UIImage() instance as background
 (3) Apply UIImage to UINavigationBar
 (4) Makes it NOT translucent
 */
extension UINavigationBar {
    func whitenBar(navigator: UINavigationController?) {
        navigator?.setNavigationBarHidden(false, animated: false)
        navigator?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigator?.navigationBar.shadowImage = UIImage()
        navigator?.navigationBar.isTranslucent = false
    }
}


/*
 MARK: - Function to generate random colors
 */
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1)
    }
}



class RPHelpers: NSObject {

    // MARK: - OpenWeatherMap.org API
    open func getWeather(lat: CLLocationDegrees, lon: CLLocationDegrees) {
        // Clear global array --> "CapturedStill.swift"
        temperature.removeAll(keepingCapacity: false)
        
        // MARK: - OpenWeatherMap API
        let wheatherURL = URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=0abf9dff54ea3ccb6561c3574557594c")
        let session = URLSession.shared
        let task = session.dataTask(with: wheatherURL!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                if let webContent = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        let main = json["main"] as! NSDictionary
                        let kelvin = main["temp"] as! Double
                        let farenheit = (kelvin * 1.8) - 459.67
                        let celsius = kelvin - 273.15
                        let both = "\(Int(farenheit))°F\n\(Int(celsius))°C"
                        
                        // Append Temperature
                        temperature.append(both)
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        // Resume query if ended
        task.resume()
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
    open func pushNotification(fromUser: PFUser?, toUser: PFUser?, activityType: String?, postType: String?) {
//        // Send Push Notification to user
//        // Handle optional chaining
//        // Handle optional chaining
//        if chatUserObject.last!.value(forKey: "apnsId") != nil {
//            // MARK: - OneSignal
//            // Send push notification
//            OneSignal.postNotification(
//                ["contents":
//                    ["en": "from \(PFUser.current()!.username!.uppercased())"],
//                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
//                 "ios_badgeType": "Increase",
//                 "ios_badgeCount": 1
//                ]
//            )
//        }
        
//        switch activityType {
//        case "Chats":
//            <#code#>
//        default:
//            <#code#>
//        }
        
//        if toUser!.value(forKey: "apnsId") != nil {
//            
//            
//            if activityType == "from" {
//                
//            } else if activityType == "Comment" {
//                
//            }
//            
//            OneSignal.postNotification(
//                ["contents":
//                    ["en": "from \(fromUser!.username!.uppercased())"],
//                 "include_player_ids": ["\(toUser!.value(forKey: "apnsId") as! String)"],
//                 "ios_badgeType": "Increase",
//                 "ios_badgeCount": 1
//                ]
//            )
//
//        }
        
        
    }
    
}
