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
    var friendObjects = [PFObject]()
    
    // Set friends
    var friends = ["l5L2xZuhIi", // Alex LaVersa (1)
                   "8ZztVf7CEw", // Michael Furman (2)
                   "OoZRHmiNpX", // Jake Cadez (3)
                   "uvjf6LmD2t", // Yusuf Ahmed (4)
                   "2AOI4vtcSI" // Josh Choi (5)
    ]
    
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
        // :)
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        UIApplication.shared.keyWindow?.rootViewController = masterTab

    }
    
    // Function to fetch these users
    func fetchUsers() {
        
        let team = PFUser.query()!
        team.whereKey("objectId", containedIn: self.friends)
        
        let follow = PFUser.query()!
        follow.whereKey("private", equalTo: false)
        
        let people = PFQuery.orQuery(withSubqueries: [team, follow])
        people.order(byDescending: "createdAt")
        people.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.followObjects.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    
                    if object.objectId! == "2AOI4vtcSI" || object.objectId! == "uvjf6LmD2t" || object.objectId! == "OoZRHmiNpX" || object.objectId! == "8ZztVf7CEw" || object.objectId! == "l5L2xZuhIi" {
                        
                        self.friendObjects.append(object)
                        
                    } else {
                        
                        self.followObjects.append(object)
                    }
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
        self.title = "Friend Or Follow"
        
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return friendObjects.count
        } else {
            return followObjects.count
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        label.font = UIFont(name: "AvenirNext-Medium", size: 19.00)
        
        if section == 0 {
            
            label.text = " • Friend the Redplanet Team"
            return label
            
        } else {
            
            label.text = " • Follow Public Accounts"
            return label

        }

    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44
        } else {
            return 44
        }
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
        
    
        if indexPath.section == 0 {
            // Set user's object
            cell.userObject = self.friendObjects[indexPath.row]
            
            
            // (A) Fetch user's objects
            friendObjects[indexPath.row].fetchIfNeededInBackground {
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
            if myRequestedFriends.contains(self.friendObjects[indexPath.row]) {
                // FOLLOWING
                // Set button's title and design
                cell.followButton.setTitle("Friend Requested", for: .normal)
                cell.followButton.setTitleColor(UIColor.white, for: .normal)
                cell.followButton.backgroundColor =  UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                cell.followButton.layer.cornerRadius = 22.0
                cell.followButton.clipsToBounds = true
            } else {
                // FOLLOW
                // Set button's title and design
                cell.followButton.setTitle("Friend", for: .normal)
                cell.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                cell.followButton.backgroundColor = UIColor.white
                cell.followButton.layer.cornerRadius = 22.00
                cell.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                cell.followButton.layer.borderWidth = 2.00
                cell.followButton.clipsToBounds = true
            }
        } else {
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
                cell.followButton.backgroundColor =  UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                cell.followButton.layer.cornerRadius = 22.0
                cell.followButton.clipsToBounds = true
            } else {
                // FOLLOW
                // Set button's title and design
                cell.followButton.setTitle("Follow", for: .normal)
                cell.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                cell.followButton.backgroundColor = UIColor.white
                cell.followButton.layer.cornerRadius = 22.00
                cell.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                cell.followButton.layer.borderWidth = 2.00
                cell.followButton.clipsToBounds = true
            }

        }
        

        return cell
    }
 

}
