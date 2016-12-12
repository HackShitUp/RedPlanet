//
//  BestFriends.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/11/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Variable to hold best BestFriends
var forBFObject = [PFObject]()


class BestFriends: UITableViewController {
    
    // Array to hold...
    // First Best Friend
    // Second Best Friend
    // Third Best Friend
    var firstBF: PFObject?
    var secondBF: PFObject?
    var thirdBF: PFObject?
    
    
    // Function to fetch best frineds
    func fetchBF() {
        let bf = PFQuery(className: "BestFriends")
        bf.whereKey("theFriend", equalTo: forBFObject.last!)
        bf.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data
            self.tableView!.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Clear table view
        self.tableView!.tableFooterView = UIView()
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
        return 3
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bfCell", for: indexPath) as! BestFriendsCell
        

        return cell
    }
 

}
