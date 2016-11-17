//
//  OnboardFollow.swift
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


// Define Notification
let onBoardNotification = Notification.Name("onboard")

class OnboardFollow: UITableViewController, UINavigationControllerDelegate {
    
    
    // Array to hold user object
    var followObjects = [PFObject]()
    
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch users
        fetchUsers()
        
        // query relationships
        appDelegate.queryRelationships()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    @IBAction func doneButton(_ sender: Any) {
        
        // Load main interface :)
//        let masterVC = self.storyboard?.instantiateViewController(withIdentifier: "theMasterTab") as! MasterTab
//        self.navigationController?.present(masterVC, animated: true, completion: nil)
        
        // :)
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        UIApplication.shared.keyWindow?.rootViewController = masterTab

    }
    
    // Function to fetch these users
    func fetchUsers() {
        let user = PFUser.query()!
        user.whereKey("private", equalTo: false)
        user.order(byDescending: "createdAt")
        user.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.followObjects.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.followObjects.append(object)
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
        
        // Show navigation controller
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 115
        self.tableView!.rowHeight = UITableViewAutomaticDimension

        
        // Fetch users
        fetchUsers()
        
        // Set title
        self.title = "Follow"
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: friendsNewsfeed, object: nil)
        
        // Get rid of back button
        self.navigationController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
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
        return self.followObjects.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "onBoardCell", for: indexPath) as! OnBoardFollowCell
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Give Profile Photo Corner Radius
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
    
        
        // Set user's object
        cell.userObject = self.followObjects[indexPath.row]
        
        
        // (A) Fetch user's objects
        followObjects[indexPath.row].fetchIfNeededInBackground {
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
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                // (2) Set user's name
                cell.name.text! = object!["realNameOfUser"] as! String
                
                // (3) Set user's bio
                if object!["userBiography"] != nil {
                    cell.bio.text! = object!["userBiography"] as! String
                } else {
                    cell.bio.text! = ""
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        
        // Set title
        if myFollowing.contains(self.followObjects[indexPath.row]) {
            // FOLLOWING
            // Set button's title and design
            cell.followButton.setTitle("Following", for: .normal)
            cell.followButton.setTitleColor(UIColor.white, for: .normal)
            cell.followButton.backgroundColor =  UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
            cell.followButton.layer.cornerRadius = 22.0
            cell.followButton.clipsToBounds = true
        } else {
            // FOLLOW
            // Set button's title and design
            cell.followButton.setTitle("Follow", for: .normal)
            cell.followButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
            cell.followButton.backgroundColor = UIColor.white
            cell.followButton.layer.cornerRadius = 22.00
            cell.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
            cell.followButton.layer.borderWidth = 2.00
            cell.followButton.clipsToBounds = true
        }
        

        return cell
    }
 

}
