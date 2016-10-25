//
//  RFollowers.swift
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


// Array to hold who's followers to fetch
var forFollowers = [PFObject]()

class RFollowers: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // Variable to hold followers
    var followers = [PFObject]()
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Remove last value in the array
        forFollowers.removeLast()
        
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Reload data
        queryFollowers()
    }
    
    // Query Followers
    func queryFollowers() {
        // Show Progress
        SVProgressHUD.show()
        
        let followers = PFQuery(className: "FollowMe")
        followers.whereKey("isFollowing", equalTo: true)
        followers.whereKey("following", equalTo: forFollowers.last!)
        followers.includeKey("follower")
//        followers.limit = self.page
        followers.order(byDescending: "createdAt")
        followers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.followers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    //                    self.followers.append(object["follower"] as! PFUser)
                    if let theFollower = object["follower"] as? PFUser {
                        self.followers.append(theFollower)
                    }
                }
                
                
                // DZNEmptyDataSet
                if self.followers.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.tableFooterView = UIView()
                }
                
            } else {
                print(error?.localizedDescription)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(forFollowers.last!.value(forKey: "realNameOfUser") as! String)'s Followers"
        }
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if followers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "😁\nNo Followers"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    // Button title
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find People To Follow"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Show search
        let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController!.pushViewController(search, animated: true)
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Query followers
        queryFollowers()
        
        // Stylize title
        configureView()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
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
        return self.followers.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rFollowersCell", for: indexPath) as! RFollowersCell
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // (1) Get user's object
        followers[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (A) Set username
                //                cell.rpUsername.text! = object!["username"] as! String
                cell.rpUsername.text! = object!["realNameOfUser"] as! String
                
                // (B) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set user's profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription)
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
            } else {
                print(error?.localizedDescription)
                // Set default
                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
            }
        }
        
        return cell
    }
    
    
    
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append to otherObject
        otherObject.append(followers[indexPath.row])
        
        // Append otherName
        otherName.append(followers[indexPath.row].value(forKey: "username") as! String)
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.navigationController?.pushViewController(otherVC, animated: true)
        
    }
    


}
