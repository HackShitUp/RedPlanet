//
//  TFollowing.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class TFollowing: UITableViewController {
    
    // Array to hold friends, posts, and skipped objects
    var following = [PFObject]()
    var posts = [PFObject]()
    var skipped = [PFObject]()
    
    // Pipeline method
    var page: Int = 50
    
    // Parent Navigator
    var parentNavigator: UINavigationController!
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
    
    // Likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()

    // Function to refresh data
    func refresh() {
        // Reload news feed
        fetchPosts()
    }
    
    // Function to fetch following
    func fetchFollowing() {
        let following = PFQuery(className: "FollowMe")
        following.includeKeys(["following", "follower"])
        following.whereKey("isFollowing", equalTo: true)
        following.whereKey("following", equalTo: PFUser.current()!)
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.following.append(object.object(forKey: "follower") as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    // Function to fetch posts
    func fetchPosts() {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
