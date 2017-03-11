//
//  BlockedUsers.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/10/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage

class BlockedUsers: UITableViewController {
    
    var blockedUsers = [PFObject]()
    
    // Function to fetch blocked users
    func fetchBlocked() {
        let blocked = PFQuery(className: "Blocked")
        blocked.whereKey("byUser", equalTo: PFUser.current()!)
        blocked.includeKey("toUser")
        blocked.order(byDescending: "createdAt")
        blocked.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.blockedUsers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.blockedUsers.append(object.object(forKey: "toUser") as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchBlocked()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.blockedUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Get users' usernames and user's profile photos
        cell.rpUsername.text! = self.blockedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String
        if let proPic = self.blockedUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
        
        return cell
    }

    
}
