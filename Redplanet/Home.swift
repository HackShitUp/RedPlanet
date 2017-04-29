//
//  Home.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import DZNEmptyDataSet

import Parse
import ParseUI
import Bolts

import OneSignal
import SVProgressHUD
import SDWebImage


class Home: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, TwicketSegmentedControlDelegate {
    
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
    
    // Refresher
    var refresher: UIRefreshControl!
    
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
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: self.friends)
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.posts.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Ephemeral content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.posts.append(object)
                        
                    } else {
                        self.skipped.append(object)
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    func didSelect(_ segmentIndex: Int) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: 5, y: view.frame.height / 2 - 20, width: view.frame.width - 10, height: 40)
        let segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.delegate = self
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["FRIENDS", "FOLLOWING"])
        segmentedControl.defaultTextColor = UIColor.darkGray
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0.00, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Demibold", size: 15)!
        self.navigationController?.navigationBar.topItem?.titleView = segmentedControl
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        
        // Fetch Friends/Posts
        _ = fetchFriends()
        
        // Configure table view
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        self.tableView!.estimatedRowHeight = 65
        self.tableView!.rowHeight = 65
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        //        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
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
        cell.delegate = self.navigationController
        
        // Set PFObject
        cell.postObject = self.posts[indexPath.row]
        
        // (1) Get User's Object
        if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
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
        
        
        
        
        // (4) Set mediaPreview or textPreview
        cell.textPreview.isHidden = true
        cell.mediaPreview.isHidden = true
        
        if self.posts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            cell.textPreview.text = self.posts[indexPath.row].value(forKey: "textPost") as! String
            cell.textPreview.isHidden = false
            
            
        } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
            cell.mediaPreview.image = UIImage(named: "SharedPostIcon")
            cell.mediaPreview.isHidden = false
        } else if self.posts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
            cell.mediaPreview.image = UIImage(named: "CSpacePost")
            cell.mediaPreview.isHidden = false
        } else {
            
            if let photo = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                cell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
                cell.mediaPreview.isHidden = false
            } else if let video = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                cell.mediaPreview.isHidden = false
                let rpVideoPlayer = RPVideoPlayerView()
                rpVideoPlayer.setupVideo(videoURL: URL(string: video.url!)!)
                cell.mediaPreview.addSubview(rpVideoPlayer)
                rpVideoPlayer.muted = true
                rpVideoPlayer.autoplays = true
                rpVideoPlayer.playbackLoops = true
                rpVideoPlayer.play()
            }
        }
        
        cell.textPreview.roundAllCorners(sender: cell.textPreview)
        cell.mediaPreview.roundAllCorners(sender: cell.mediaPreview)
        
        return cell
    }


}
