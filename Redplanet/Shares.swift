//
//  Shares.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/29/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD


// Array to hold shareObject
var shareObject = [PFObject]()


class Shares: UITableViewController, UINavigationControllerDelegate {
    
    // Array to hold sharers
    var sharers = [PFObject]()
    
    // Pipeline method
    var page: Int = 50
    
    
    // Variable to hold shares
    func queryShares() {
        let shares = PFQuery(className: "Newsfeeds")
        shares.whereKey("pointObject", equalTo: shareObject.last!)
        shares.includeKey("fromUser")
        shares.limit = self.page
        shares.order(byDescending: "createdAt")
        shares.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.sharers.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.sharers.append(object["byUser"] as! PFUser)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Shares"
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch sharers
        queryShares()
        
        // Stylize title
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title
        configureView()
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
        return sharers.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sharesCell", for: indexPath) as! SharesCell
        
        // Declare parent vc
        cell.delegate = self
        
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        

        // Fetch user's objects
        sharers[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
                
                // (2) Set usernames
                cell.rpUsername.text! = object!["realNameOfUser"] as! String
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }

        return cell
    }
 

    // MARK: - UITableView delegate method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append data
        otherName.append(sharers[indexPath.row].value(forKey: "username") as! String)
        otherObject.append(sharers[indexPath.row])
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.navigationController?.pushViewController(otherVC, animated: true)
    }

}
