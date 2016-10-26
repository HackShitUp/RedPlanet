//
//  ShareTo.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/24/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import SVProgressHUD
import DZNEmptyDataSet


class ShareTo: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    
    // Array to hold friends
    var friends = [PFObject]()
    
    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    
    // Array to hold search objects
    var searchObjects = [PFObject]()
    
    // Search Bar
    var searchBar = UISearchBar()
    
    
    // Query Friends
    func queryFriends() {
        
        // Show Progress
        SVProgressHUD.show()
        
        let fFriend = PFQuery(className: "FriendMe")
        fFriend.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriend.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriend = PFQuery(className: "FriendMe")
        eFriend.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriend.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriend, fFriend])
        friends.whereKey("isFriends", equalTo: true)
        friends.order(byDescending: "createdAt")
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.friends.append(object)
                }
                
            } else {
                print(error?.localizedDescription)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch friends
        queryFriends()
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
        if searchActive == true && searchBar.text! != "" {
            return self.searchObjects.count
        } else {
            return self.friends.count
        }
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        if searchActive == true && searchBar.text! != "" {
            
        } else {
            
        }

        return cell
    }
    


}
