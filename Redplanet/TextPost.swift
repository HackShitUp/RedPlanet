//
//  TextPost.swift
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


// Global variable to hold object
var textPostObject = [PFObject]()

class TextPost: UITableViewController, UINavigationControllerDelegate {
    
    // Arrays to hold likes and comments
    var likes = [PFObject]()
    var comments = [PFObject]()
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Function to count likes
    func fetchInteractions() {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
        likes.order(byAscending: "createdAt")
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
        
        
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch Likes and Comments
        fetchInteractions()

        // Set estimated row height
        self.tableView!.estimatedRowHeight = 180
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Reload data
        self.tableView!.reloadData()
        
        
//        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        // reload data
//        self.tableView!.reloadData()
//    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload data
        self.tableView!.reloadData()
        
        // Hide TabBar
//        self.navigationController?.navigationBar.isHidden = false
        // Show toolBar
//        self.navigationController?.toolbar.isHidden = false
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reload Data
        self.tableView!.reloadData()
        
//        self.navigationController?.navigationBar.isHidden = false

    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return UITableViewAutomaticDimension
        } else {
            return 75
        }
//        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            
            // Content
            let cell = tableView.dequeueReusableCell(withIdentifier: "textPostCell", for: indexPath) as! TextPostCell
            
            // Instantiate parent vc
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
            
            
            textPostObject.last!.fetchInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    
                    // (1) Point to User's Object
                    if let user = object!["byUser"] as? PFUser {
                        // (A) Set username
                        cell.rpUsername.text! = user["username"] as! String
                        
                        // (B) Get profile photo
                        if let proPic = user["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // (B1) Set profile photo
                                    cell.rpUserProPic.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription)
                                    // (B2) Set default
                                    cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                                }
                            })
                        }
                    }
                    
                    // (2) Set Text Post
                    cell.textPost.text! = object!["textPost"] as! String
                    
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
                    
                    
                    
                } else {
                    print(error?.localizedDescription)
                }
            }
            
            tableView.rowHeight = UITableViewAutomaticDimension
            return cell

            
        } else {
            
            
            // Interactions
            let iCell = tableView.dequeueReusableCell(withIdentifier: "interactCell", for: indexPath) as! InteractCell
            
            tableView.rowHeight = 100
            
            
            return iCell
            
        }

    } // End 


} // END
