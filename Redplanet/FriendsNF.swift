//
//  FriendsNF.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import OneSignal
import SVProgressHUD
import SDWebImage

class FriendsNF: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate {
    
    // AppDelegate Constant
    let appDelegate = AppDelegate()
    
    // Array to hold friends (MUTUAL FOLLOWING)
    var friends = [PFObject]()
    // Array to hold posts/skipped
    var posts = [PFObject]()
    var skipped = [PFObject]()
    
    // Hold likers
    var likes = [PFObject]()
    
    // Pipeline method
    var page: Int = 50
    
    // Parent Navigator
    var parentNavigator: UINavigationController!
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
    // Function to refresh data
    func refresh() {
        fetchFriends()
        self.refresher.endRefreshing()
    }
    
    // FETCH MUTUAL
    func fetchFriends() {
        // MARK: - AppDelegate
        _ = appDelegate.queryRelationships()
        
        // Fetch Friends
        let mutuals = PFQuery(className: "FollowMe")
        mutuals.includeKeys(["follower", "following"])
        mutuals.whereKey("following", equalTo: PFUser.current()!)
        mutuals.whereKey("isFollowing", equalTo: true)
        mutuals.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.posts.removeAll(keepingCapacity: false)
                self.friends.removeAll(keepingCapacity: false)
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if myFollowing.contains(where: {$0.objectId! == (object.object(forKey: "follower") as! PFUser).objectId!}) {
                        self.friends.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
                self.fetchFirstPosts()
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
        })
    }
    
    // FETCH POSTS
    func fetchFirstPosts() {
        for user in self.friends {
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: user)
            newsfeeds.includeKeys(["byUser", "pointObject", "toUser"])
            newsfeeds.order(byDescending: "createdAt")
            newsfeeds.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object!.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.posts.append(object!)
                    } else {
                        self.skipped.append(object!)
                    }
                    
                    // Reload UITableViewData
                    self.tableView.reloadData()
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch Friends/Posts
        self.fetchFriends()
        
        // Configure table view
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        self.tableView!.estimatedRowHeight = 65.00
        self.tableView!.rowHeight = 65.00
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
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
        return self.posts.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("NewsFeedCell", owner: self, options: nil)?.first as! NewsFeedCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
        
        // Set delegate
        cell.delegate = self.parentNavigator
        
        // Set PFObject
        cell.postObject = self.posts[indexPath.row]
        
        // (1) Get User's Object
        if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            // (2) Set rpUsername
            if let fullName = user.value(forKey: "realNameOfUser") as? String{
                cell.rpUsername.text = fullName
            }
        }
       
        // (3) Set time
        // Configure initial setup for time
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        cell.time.text = difference.getFullTime(difference: difference, date: from)

        return cell
    }
    

   

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
