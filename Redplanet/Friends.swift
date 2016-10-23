//
//  Friends.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD

class Friends: UITableViewController, UINavigationControllerDelegate, CAPSPageMenuDelegate {
    
    // Array to hold friends
    var friends = [PFObject]()
    
    // Array to hold friends' content
    var friendsContent = [PFObject]()
    
    
    // Initialize UINavigationController
    weak var friendsNavigator: UINavigationController?
    
    
    // Query Current User's Friends
    func queryFriends() {
        
        // Show Progress
        SVProgressHUD.show()
        
        
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriends, fFriends])
        friends.includeKey("frontFriend")
        friends.includeKey("endFriend")
        friends.includeKey("frontFriend")
        friends.includeKey("endFriend")
        friends.whereKey("isFriends", equalTo: true)
        friends.findObjectsInBackground(block: { (
            objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                
                // First, append Current User
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if object["frontFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["endFriend"] as! PFUser)
                    }
                    
                    if object["endFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["frontFriend"] as! PFUser)
                    }
                }
                
                print("Friends Count: \(self.friends.count)")
                
                
                // Newsfeeds
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("byUser", containedIn: self.friends)
                newsfeeds.order(byDescending: "createdAt")
                newsfeeds.includeKey("byUser")
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Dismiss
                        SVProgressHUD.dismiss()
                        
                        // Clear array
                        self.friendsContent.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            /*
                             // Fetch objects only within the past 24 hours
                             let from = object.createdAt!
                             let now = Date()
                             let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                             let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                             
                             // If the difference of the day is less than one day (24 hours),
                             // append the object
                             if difference.hour! <= 24 && difference.day! == 1 {
                             // Append Objects
                             }
                             */
                            
                            self.friendsContent.append(object)
                        }
                        
                        print("Friends feed count: \(self.friendsContent.count)")
                        
                    } else {
                        print(error?.localizedDescription)
                        
                        
                        // Dismiss
                        SVProgressHUD.dismiss()
                        
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
                })
                
                
            } else {
                print(error?.localizedDescription)
                
                // Dismiss
                SVProgressHUD.dismiss()
            }
        })
        
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Query Friends
        self.queryFriends()
        
        // Declare UINavigationController
        self.friendsNavigator = parent?.navigationController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friendsContent.count
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell", for: indexPath) as! FriendsCell
        
        // Set cell's parent VC
        cell.delegate = self
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        

        // Fetch objects
        friendsContent[indexPath.row].fetchInBackground { (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (1) Get user's object
                if let user = object!["byUser"] as? PFUser {
                    // (A) Username
                    cell.rpUsername.text! = user.value(forKey: "realNameOfUser") as! String
                    
                    // (B) Profile Photo
                    // Handle optional chaining for user's profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                                
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                }
                

                // (2) Determine Content Type
                if object!["mediaAsset"] == nil {
                    cell.contentColor.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                    cell.contentType.image = UIImage(named: "Text Height-96")
                } else {
                    cell.contentColor.backgroundColor = UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0)
                    cell.contentType.image = UIImage(named: "Stack of Photos-96")
                }
                
                
                // (3) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    cell.time.text = "\(difference.second!)s ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.time.text = "\(difference.minute!)m ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.time.text = "\(difference.hour!)h ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.time.text = "\(difference.day!)d ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    cell.time.text = "\(difference.weekOfMonth!)w ago"
                }
                
                
                
                /////
                // USER FOR LATER WHEN CONTENT IS DELETED EVERY 24 HOURS
                /////
                //                let dateFormatter = DateFormatter()
                //                dateFormatter.dateFormat = "EEEE"
                //                let timeFormatter = DateFormatter()
                //                timeFormatter.dateFormat = "h:mm a"
                //                let time = "\(dateFormatter.string(from: object!.createdAt!)) \(timeFormatter.string(from: object!.createdAt!))"
                //                cell.rpTime.text! = time
                
                
                
            } else {
                print(error?.localizedDescription)
            }
        }

        

        return cell
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if self.friendsContent[indexPath.row].value(forKey: "mediaAsset") == nil {
            
            /*
            // Save to Views
            let view = PFObject(className: "Views")
            view["byUser"] = PFUser.current()!
            view["username"] = PFUser.current()!.username!
            view["forObjectId"] = friendsContent[indexPath.row].objectId!
            view.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                } else {
                    print(error?.localizedDescription)
                }
            })
            */
            
            
            // Append Object
            textPostObject.append(self.friendsContent[indexPath.row])
            
            // Present VC
            let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "tpNavigator") as! TextPostNavigator
            self.present(textPostVC, animated: true)

        } else {

        }
    }

}
