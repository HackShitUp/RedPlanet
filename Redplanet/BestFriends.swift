//
//  BestFriends.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/10/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class BestFriends: UITableViewController {
    
    // (1) Fetch all the user's messages
    // (2) Count how many the user sent 
    // (3) Find users who received otherUser's messages
    // (4) Fetch receiver's messages
    // (5) Count how many the receiver sent to current
    // (7) If specific numbers are set, then display best friends
    
    
    
    
    
    // Array to hold user's messages
    var userObjectChats: Dictionary = [PFObject: String]()
    var friendOneCount: Int?
    var friendTwoCount: Int?
    var friendThreeCount: Int?
    
    
    func fetchBestFriends() {
        let chats = PFQuery(className: "Chats")
        chats.includeKey("sender")
        chats.includeKey("receiver")
        chats.whereKey("sender", equalTo: otherObject.last!)
        chats.whereKey("receiver", equalTo: otherObject.last!)
        chats.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.userObjectChats.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if object["receiver"] as! PFUser == otherObject.last! {
                        
                    }
                    
                    if object["sender"] as! PFUser == otherObject.last! {
                        
                    }
                }
                
                
            
                
                
                /*
            
                 // Sort objects here:
                 
                 
                 If otherUser's Messages' count <= friendOne's Messages Count {
                 // Skip 
                 }
                 
                 If otherUser's Messages' count <= friendOne's Messages Count {
                 // Skip
                 }
                 
                 If otherUser's Messages' count <= friendOne's Messages Count {
                 // Skip
                 }
                 
                 */
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch best friends
        fetchBestFriends()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }

}
