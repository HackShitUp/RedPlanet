//
//  VideoAsset.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/6/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import SDWebImage

// Global array to hold video asset object
var videoObject = [PFObject]()

// Notification Center to identify video
let videoNotification = Notification.Name("videoNotification")

class VideoAsset: UITableViewController, UINavigationControllerDelegate {
    
    // Array values to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var sharers = [PFObject]()
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        videoObject.removeLast()
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch interactions
        fetchInteractions()
        // End refresher
        self.refresher.endRefreshing()
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Function to fetch interactions
    func fetchInteractions() {
        
        // (1) Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: videoObject.last!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                
                // (2) Fetch Comments
                let comments = PFQuery(className: "Comments")
                comments.whereKey("forObjectId", equalTo: videoObject.last!.objectId!)
                comments.includeKey("byUser")
                comments.order(byDescending: "createdAt")
                comments.findObjectsInBackground {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        // Append objects
                        for object in objects! {
                            self.comments.append(object["byUser"] as! PFUser)
                        }

                        // (3) Fetch Shares
                        let shares = PFQuery(className: "Newsfeeds")
                        shares.whereKey("pointObject", equalTo: videoObject.last!)
                        shares.includeKey("byUser")
                        shares.order(byDescending: "createdAt")
                        shares.findObjectsInBackground(block: {
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
                        })

                    } else {
                        print(error?.localizedDescription as Any)
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Video"
        }
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - MainTabUI
        // Hide button
        rpButton.isHidden = true
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title
        configureView()
    
        // Show Status bar
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Fetch Likes and Comments
        fetchInteractions()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 490
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)

        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: videoNotification, object: nil)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title
        configureView()
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - MainTabUI
        // Show button
        rpButton.isHidden = false
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
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 490
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TimeVideoCell", owner: self, options: nil)?.first as! TimeVideoCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds

        // Set parent VC
        cell.delegate = self.navigationController
        
        // Declare user's object
        cell.userObject = videoObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.postObject = videoObject.last!
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Layout caption views
        cell.textPost.layoutIfNeeded()
        cell.textPost.layoutSubviews()
        cell.textPost.setNeedsLayout()
        
        // Get video object
        // (1) Point to User's Object
        if let user = videoObject.last!["byUser"] as? PFUser {
            user.fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (A) Set username
                    cell.rpUsername.text! = "\(user["username"] as! String)"
                    
                    // (B) Get profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        // (2) Get video preview
        if let videoFile = videoObject.last!["videoAsset"] as? PFFile {
            // LayoutViews
            cell.videoPreview.layoutIfNeeded()
            cell.videoPreview.layoutSubviews()
            cell.videoPreview.setNeedsLayout()
            
            // Make Vide Preview Circular
            cell.videoPreview.layer.cornerRadius = cell.videoPreview.frame.size.width/2
            cell.videoPreview.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            cell.videoPreview.layer.borderWidth = 3.50
            cell.videoPreview.clipsToBounds = true
            
            // MARK: - SDWebImage
            cell.videoPreview.sd_setShowActivityIndicatorView(true)
            cell.videoPreview.sd_setIndicatorStyle(.gray)
            
            // Load Video Preview and Play Video
            let player = AVPlayer(url: URL(string: videoFile.url!)!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = cell.videoPreview.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            cell.videoPreview.contentMode = .scaleAspectFit
            cell.videoPreview.layer.addSublayer(playerLayer)
            player.isMuted = true
            player.play()
            cell.layoutSubviews()
        }
        
        
        // (3) Set Text Post
        cell.textPost.text! = videoObject.last!["textPost"] as! String
        
        // (4) Set time
        let from = videoObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.time.text = difference.getFullTime(difference: difference, date: from)
                
        // (5) Determine whether the current user has liked this object or not
        if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
            // Set button title
            cell.likeButton.setTitle("liked", for: .normal)
            // Set/ button image
            cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
        } else {
            // Set button title
            cell.likeButton.setTitle("notLiked", for: .normal)
            // Set button image
            cell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
        }
        
        // Set number of likes
        if self.likes.count == 0 {
            cell.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        
        // Set number of comments
        if self.comments.count == 0 {
            cell.numberOfComments.setTitle("comments", for: .normal)
        } else if self.comments.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
        }
        
        // Set number of shares
        if self.sharers.count == 0 {
            cell.numberOfShares.setTitle("shares", for: .normal)
        } else if self.sharers.count == 1 {
            cell.numberOfShares.setTitle("1 share", for: .normal)
        } else {
            cell.numberOfShares.setTitle("\(self.sharers.count) shares", for: .normal)
        }

        return cell
    }// end CellForRowAt
    

}
