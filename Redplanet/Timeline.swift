//
//  Timeline.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import OneSignal
import SimpleAlert
import SVProgressHUD


// TODO:
// Define notification to reload data

class Timeline: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate {
    
    // Array to hold friends, posts, and skipped objects
    var friends = [PFObject]()
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
    
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    
    // TODO::
    // Function to refresh data
    func refresh() {
        
    }
    
    // TODO::
    // Function to fetch friends
    func fetchFriends() {
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [fFriends, eFriends])
        friends.includeKeys(["endFriend", "frontFriend"])
        friends.whereKey("isFriends", equalTo: true)
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if (object.object(forKey: "frontFriend") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        // Append end friend
                        self.friends.append(object.object(forKey: "endFriend") as! PFUser)
                    } else {
                        // Append front friend
                        self.friends.append(object.object(forKey: "frontFriend") as! PFUser)
                    }
                }
                
                print(self.friends.count)
                // Fire function to fetch news feed
                self.fetchPosts()
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            // self.tableView!.reloadData()
            
        })
        
    }
    
    
    
    func fetchPosts() {
        // Get News Feed content
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: self.friends)
        newsfeeds.includeKeys(["byUser", "pointObject", "toUser"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.limit = self.page
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Ephemeral content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if object.value(forKey: "contentType") as! String == "itm" || object.value(forKey: "contentType") as! String == "sh" || object.value(forKey: "contentType") as! String == "sp" {
                        if difference.hour! < 24 {
                            self.posts.append(object)
                        } else {
                            self.skipped.append(object)
                        }
                    } else {
                        self.posts.append(object)
                    }
                }
                
                print(self.posts.count)
                
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    // MARK: - TabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if self.parentNavigator.tabBarController?.selectedIndex == 0 {
            // Scroll to top
            self.tableView?.setContentOffset(CGPoint.zero, animated: true)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch friends
        fetchFriends()
        // Configure table view
        self.tableView?.estimatedRowHeight = 658
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.tableFooterView = UIView()
        // Set tabBarController delegate
        self.parentNavigator.tabBarController?.delegate = self
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
        return self.posts.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.ephemeralTypes.contains(self.posts[indexPath.row].value(forKeyPath: "contentType") as! String) {
            return 65
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Intialize UITableViewCells
        let eCell = Bundle.main.loadNibNamed("EphemeralCell", owner: self, options: nil)?.first as! EphemeralCell
        let tpCell = Bundle.main.loadNibNamed("TimeTextPostCell", owner: self, options: nil)?.first as! TimeTextPostCell
        let mCell = Bundle.main.loadNibNamed("TimeMediaCell", owner: self, options: nil)?.first as! TimeMediaCell
        
        // Declare delegates
        tpCell.delegate = self
        mCell.delegate = self
        
        // Initialize all level configurations: rpUserProPic && rpUsername
        let proPics = [eCell.rpUserProPic, tpCell.rpUserProPic, mCell.rpUserProPic]
        let usernames = [eCell.rpUsername, tpCell.rpUsername, mCell.rpUsername]
        
        // Initialize text for time
        var rpTime: String?
        
        
        // (I) Fetch user's data and unload them
        self.posts[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if let user = object!["byUser"] as? PFUser {
                    // (A) User's Full Name
                    for u in usernames {
                        u?.text! = user["realNameOfUser"] as! String
                    }
                    
                    // (B) Profile Photo
                    for p in proPics {
                        // LayoutViews for rpUserProPic
                        p?.layoutIfNeeded()
                        p?.layoutSubviews()
                        p?.setNeedsLayout()
                        // Make Profile Photo Circular
                        p?.layer.cornerRadius = (p?.frame.size.width)!/2
                        p?.layer.borderColor = UIColor.lightGray.cgColor
                        p?.layer.borderWidth = 0.5
                        p?.clipsToBounds = true
                        
                        if let proPic = user["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    p?.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                    p?.image = UIImage(named: "Gender Neutral User-100")
                                }
                            })
                        }
                    }
                } // end fetching PFUser object
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // (II) Configure time for Photos, Profile Photos, Text Posts, and Videos
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            rpTime = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                rpTime = "1 second ago"
            } else {
                rpTime = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                rpTime = "1 minute ago"
            } else {
                rpTime = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                rpTime = "1 hour ago"
            } else {
                rpTime = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                rpTime = "1 day ago"
            } else {
                rpTime = "\(difference.day!) days ago"
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            rpTime = createdDate.string(from: self.posts[indexPath.row].createdAt!)
        }
        
        
        
        
        // (II) Layout content
        if self.ephemeralTypes.contains(self.posts[indexPath.row].value(forKeyPath: "contentType") as! String) {
        // ****************************************************************************************************************
        // MOMENTS, SPACE POSTS, SHARED POSTS *****************************************************************************
        // ****************************************************************************************************************
            
            // High level configurations
            // Configure IconicPreview by laying out views
            eCell.iconicPreview.layoutIfNeeded()
            eCell.iconicPreview.layoutSubviews()
            eCell.iconicPreview.setNeedsLayout()
            eCell.iconicPreview.layer.cornerRadius = eCell.iconicPreview.frame.size.width/2
            eCell.iconicPreview.layer.borderColor = UIColor.clear.cgColor
            eCell.iconicPreview.layer.borderWidth = 0.00
            eCell.iconicPreview.contentMode = .scaleAspectFill
            eCell.iconicPreview.clipsToBounds = true
            
            // (1) Configure time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            eCell.time.text! = "\(timeFormatter.string(from: self.posts[indexPath.row].createdAt!))"

            
            // (2) Layout content
            // (2A) MOMENT
            if self.posts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                
                // Make iconicPreview circular with red border color
                eCell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                eCell.iconicPreview.layer.borderWidth = 3.50
                
                if let still = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // STILL PHOTO
                    still.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            eCell.iconicPreview.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // VIDEO
                    let videoUrl = NSURL(string: videoFile.url!)
                    do {
                        let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        eCell.iconicPreview.image = UIImage(cgImage: cgImage)
                        
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
                }
                
                
            // (2B) SPACE POST
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "CSpacePost")
                
            // (2C) SHARED POSTS
            } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "SharedPostIcon")
            }

            
            
            return eCell
            
            
            
        } else if posts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
        // ****************************************************************************************************************
        // TEXT POST ******************************************************************************************************
        // ****************************************************************************************************************
            // Set Text Post
            tpCell.textPost.text! = self.posts[indexPath.row].value(forKey: "textPost") as! String
            // Set time
            tpCell.time.text! = rpTime!
            // Set post object
            tpCell.postObject = self.posts[indexPath.row]
            
            return tpCell

        } else {
        // ****************************************************************************************************************
        // PHOTOS, PROFILE PHOTOS, VIDEOS *********************************************************************************
        // ****************************************************************************************************************
            // (1) Set post object
            mCell.postObject = self.posts[indexPath.row]
            
            // (2) Fetch Photo or Video
            // PHOTO
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        mCell.mediaAsset.contentMode = .scaleAspectFit
                        mCell.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else if let videoFile = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
            // VIDEO
                
                // LayoutViews
                mCell.mediaAsset.layoutIfNeeded()
                mCell.mediaAsset.layoutSubviews()
                mCell.mediaAsset.setNeedsLayout()
                
                // Make Vide Preview Circular
                mCell.mediaAsset.layer.cornerRadius = mCell.mediaAsset.frame.size.width/2
                mCell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                mCell.mediaAsset.layer.borderWidth = 3.50
                mCell.mediaAsset.clipsToBounds = true
                
                let videoUrl = NSURL(string: videoFile.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    mCell.mediaAsset.contentMode = .scaleAspectFill
                    mCell.mediaAsset.image = UIImage(cgImage: cgImage)
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // (2) Handle caption (text post) if it exists
            if let caption = self.posts[indexPath.row].value(forKey: "textPost") as? String {
                mCell.textPost.text! = caption
            } else {
                mCell.textPost.isHidden = true
                mCell.textPost.removeFromSuperview()
            }
            
            // (3) Set time
            mCell.time.text! = rpTime!
            
            
            
            return mCell

            
            
        }

        
    }
 


}
