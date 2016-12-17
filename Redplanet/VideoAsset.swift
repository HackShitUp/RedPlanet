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
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        refresher.endRefreshing()
        
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
            self.title = "Video"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 540
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        
        // Fetch Likes and Comments
        fetchInteractions()
        
        // Stylize title
        configureView()
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: videoNotification, object: nil)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabbarcontroller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        
        
        
        // Show the user what to do!
        let openedPost = UserDefaults.standard.bool(forKey: "DidOpenPost")
        if openedPost == false && videoObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenPost")
            
            
            let alert = UIAlertController(title: "🎉\nCongrats, you viewed your first Video!\n•Tap on the preview to play the video\n• Swipe down once the video plays\n•Swipe right to leave\n•Swipe left for Views 🙈",
                                          message: nil,
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }

        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 540
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoCell

        // Set parent VC
        cell.delegate = self
        
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        
        // Instantiate parent vc
        cell.delegate = self
        
        // Declare user's object
        cell.userObject = videoObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.contentObject = videoObject.last!
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Vide Preview Circular
        cell.videoPreview.layer.cornerRadius = cell.videoPreview.frame.size.width/2
        cell.videoPreview.layer.borderColor = UIColor.lightGray.cgColor
        cell.videoPreview.layer.borderWidth = 0.5
        cell.videoPreview.clipsToBounds = true
        
        
        // Layout caption views
        cell.caption.layoutIfNeeded()
        cell.caption.layoutSubviews()
        cell.caption.setNeedsLayout()
        
        // Get video object
        videoObject.last!.fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (1) Point to User's Object
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set username
                    //                    cell.rpUsername.text! = (user["username"] as! String).uppercased()
                    cell.rpUsername.text! = "\(user["username"] as! String)"
                    
                    
                    // (B) Get profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // (B1) Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // (B2) Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                }
                
                // (2) Get video preview
                if let videoFile = object!["videoAsset"] as? PFFile {
                    let videoUrl = NSURL(string: videoFile.url!)
                    do {
                        let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        let thumbnail = UIImage(cgImage: cgImage)
                        cell.videoPreview.image = thumbnail
                        // thumbnail here
                        
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
                }
                
                
                
                // (3) Set Text Post
                cell.caption.text! = object!["textPost"] as! String
                
                // (4) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "right now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    if difference.second! == 1 {
                        cell.time.text = "1 second ago"
                    } else {
                        cell.time.text = "\(difference.second!) seconds ago"
                    }
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    if difference.minute! == 1 {
                        cell.time.text = "1 minute ago"
                    } else {
                        cell.time.text = "\(difference.minute!) minutes ago"
                    }
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    if difference.hour! == 1 {
                        cell.time.text = "1 hour ago"
                    } else {
                        cell.time.text = "\(difference.hour!) hours ago"
                    }
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    if difference.day! == 1 {
                        cell.time.text = "1 day ago"
                    } else {
                        cell.time.text = "\(difference.day!) days ago"
                    }
                }
                
                if difference.weekOfMonth! > 0 {
                    let createdDate = DateFormatter()
                    createdDate.dateFormat = "MMM d, yyyy"
                    cell.time.text = createdDate.string(from: object!.createdAt!)
                }
                
                
                
                // (5) Determine whether the current user has liked this object or not
                if self.likes.contains(PFUser.current()!) {
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
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        
        // Grow height
        cell.layoutIfNeeded()

        return cell
    }
    

    

}
