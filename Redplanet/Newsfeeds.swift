//
//  Newsfeeds.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class Newsfeeds: UITableViewController {
    
    
    // Variable to hold friends
    var friends = [PFObject]()
    
    // Variable to hold following
    var following = [PFObject]()
    
    
    // Variable to hold content
    var feedObjects = [PFObject]()
    

    @IBOutlet weak var friendsFollowing: UISegmentedControl!
    @IBAction func switchSource(_ sender: AnyObject) {
        switch friendsFollowing.selectedSegmentIndex {
        case 0:
            queryFriends()
            self.tableView!.reloadData()

        case 1:
            queryFollowing()
            self.tableView!.reloadData()
            
        default:
            break
        }
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // (1) Query Current User's Friends
    func queryFriends() {
        
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
                        
                        // Clear array
                        self.feedObjects.removeAll(keepingCapacity: false)
                        
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
                            
                            self.feedObjects.append(object)
                        }
                        
                        print("Friends feed count: \(self.feedObjects.count)")
                        
                    } else {
                        print("ERROR")
                        print(error?.localizedDescription)
                        
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
                })
                
                
            } else {
                print(error?.localizedDescription)
            }
        })
        
        
    }
    
    
    // (2) Query Current User's Followings
    func queryFollowing() {
        let following = PFQuery(className: "FollowMe")
        following.whereKey("isFollowing", equalTo: true)
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.includeKey("following")
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.following.append(object["following"] as! PFUser)
                }
                
                print("Following Count: \(self.following.count)")
                
                // Newsfeeds
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("byUser", containedIn: self.following)
                newsfeeds.order(byDescending: "createdAt")
                newsfeeds.includeKey("byUser")
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Clear array
                        self.feedObjects.removeAll(keepingCapacity: false)
                        
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
                            
                            self.feedObjects.append(object)
                        }
                        
                        print("Following feed count: \(self.feedObjects.count)")
                        
                    } else {
                        print("ERROR")
                        print(error?.localizedDescription)
                        
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
                })
                
            
            } else {
                print(error?.localizedDescription)
            }
            
        })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set initial query dependent on state of UISegmentedControl
        if friendsFollowing.selectedSegmentIndex == 0 {
            // Fetch Friends Content
            queryFriends()
        } else {
            // Fetch Following Content
            queryFollowing()
        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Show
        print("Number of rows: \(feedObjects.count)")
        return feedObjects.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsfeedsCell", for: indexPath) as! NewsfeedsCell

        
        // Fetch objects
        feedObjects[indexPath.row].fetchInBackground { (object: PFObject?, error: Error?) in
            if error == nil {
                
                // Get user's object
                if let user = object!["byUser"] as? PFUser {
                    // (1) Username
                    cell.rpUsername.text! = user.value(forKey: "username") as! String
                    
                    // (2) Profile Photo
                    // Handle optional chaining for user's profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                            }
                        })
                    }
                }
                
                
                
                // Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])

                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.rpTime.text = "NOW"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    cell.rpTime.text = "\(difference.second!) seconds ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.rpTime.text = "\(difference.minute!) minutes ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.rpTime.text = "\(difference.hour!) hours ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.rpTime.text = "\(difference.day!) days ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    cell.rpTime.text = "\(difference.weekOfMonth!) weeks ago"
                }
                
                
                
                
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
    

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
