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

import SwipeNavigationController
import SDWebImage

class OnboardFollow: UITableViewController, UINavigationControllerDelegate {
    
    
    // Array to hold user object
    var followObjects = [PFObject]()
    var teamObjects = [PFObject]()
    
    // Set Team's ObjectId's
    var team = ["8ZztVf7CEw", // Michael Furman (3)
                   "OoZRHmiNpX", // Jake Cadez (2)
                   "2AOI4vtcSI" // Josh Choi (1)
    ]
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func refresh(_ sender: Any) {
        // query relationships
        _ = appDelegate.queryRelationships()
        
        // Fetch users
        fetchUsers()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    @IBAction func doneButton(_ sender: Any) {
        // Send user chat from TeamRP
        PFUser.query()!.getObjectInBackground(withId: "NgIJplW03t") {
            (object: PFObject?, error: Error?) in
            if error == nil {
                let chats = PFObject(className: "Chats")
                chats["sender"] = object!
                chats["senderUsername"] = "teamrp"
                chats["receiver"] = PFUser.current()!
                chats["receiverUsername"] = PFUser.current()!.username!
                chats["read"] = false
                chats["Message"] = "Hi \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), welcome to the community! Feel free to chat us if you have any questions or concerns using Redplanet.🎉🦄😇"
                chats.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        // Show main interface once succeeded
                        self.showMain()
                        
                        // MARK: - HEAP Analytics
                        // Track who signed up
                        Heap.track("SignedUp", withProperties:
                            ["byUserId": "\(PFUser.current()!.objectId!)",
                                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                            ])
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
                // Show main interface if failed
                self.showMain()
            }
        }
    }
    
    
    // Function to show main interface
    func showMain() {
        // :)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraVC = storyboard.instantiateViewController(withIdentifier: "mid") as! UINavigationController
        let swipeNavigationController = SwipeNavigationController(centerViewController: cameraVC)
        swipeNavigationController.rightViewController = storyboard.instantiateViewController(withIdentifier: "right") as! UINavigationController
        swipeNavigationController.leftViewController = storyboard.instantiateViewController(withIdentifier: "left") as! UINavigationController
        swipeNavigationController.bottomViewController = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! MasterTab
        UIApplication.shared.keyWindow?.rootViewController = swipeNavigationController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }
    
    
    // Function to fetch these users
    func fetchUsers() {
        let team = PFUser.query()!
        team.whereKey("objectId", containedIn: self.team)
        let follow = PFUser.query()!
        follow.whereKey("private", equalTo: false)
        let people = PFQuery.orQuery(withSubqueries: [team, follow])
        people.order(byAscending: "createdAt")
        people.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.followObjects.removeAll(keepingCapacity: false)
                self.teamObjects.removeAll(keepingCapacity: false)
                // Append object
                for object in objects! {
                    if object.objectId! == "2AOI4vtcSI" || object.objectId! == "uvjf6LmD2t" || object.objectId! == "OoZRHmiNpX" || object.objectId! == "8ZztVf7CEw" || object.objectId! == "l5L2xZuhIi" {
                        self.teamObjects.append(object)
                    } else {
                        self.followObjects.append(object)
                    }
                }
                // Reload data
                self.tableView!.reloadData()
            } else {
                print(error?.localizedDescription as Any)
            }
        })
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
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Fetch users
        fetchUsers()
        
        // Set title
        self.title = "Follow People"
        
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
            return teamObjects.count
        } else {
            return followObjects.count
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "AvenirNext-Demibold", size: 12.00)
        label.textColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        
        if section == 0 {
            label.text = "   FOLLOW THE REDPLANET TEAM"
            return label
        } else {
            label.text = "   FOLLOW PUBLIC ACCOUNTS"
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
        
        _ = appDelegate.queryRelationships()
        
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
            // (1) Set user's object
            cell.userObject = self.teamObjects[indexPath.row]
            // (2) Set User's Name
            cell.name.text! = self.teamObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            // (3) Set user's bio
            if self.teamObjects[indexPath.row].value(forKey: "userBiography") != nil {
                cell.bio.text! = self.teamObjects[indexPath.row].value(forKey: "userBiography") as! String
            } else {
                cell.bio.text! = ""
            }
            // (4) Set Pro Pic
            if let proPic = self.teamObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            
            if myFollowing.contains(where: {$0.objectId! == self.teamObjects[indexPath.row].objectId!}) {
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

        } else {
            // (1) Set user's object
            cell.userObject = self.followObjects[indexPath.row]
            // (2) Set User's Name
            cell.name.text! = self.followObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            // (3) Set user's bio
            if self.followObjects[indexPath.row].value(forKey: "userBiography") != nil {
                cell.bio.text! = self.followObjects[indexPath.row].value(forKey: "userBiography") as! String
            } else {
                cell.bio.text! = ""
            }
            // (4) Set Pro Pic
            if let proPic = self.followObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            if myFollowing.contains(where: {$0.objectId! == self.followObjects[indexPath.row].objectId!}) {
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
