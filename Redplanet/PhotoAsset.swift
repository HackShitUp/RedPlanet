//
//  MediaAsset.swift
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

import SVProgressHUD
import SDWebImage

// Global array to hold the object
var photoAssetObject = [PFObject]()

// Define identifier
let photoNotification = Notification.Name("photoAsset")

class PhotoAsset: UITableViewController, UINavigationControllerDelegate {
    
    
    // Arrays to hold likes and comments
    var likes = [PFObject]()
    var comments = [PFObject]()
    var sharers = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Remove last
        photoAssetObject.removeLast()
        
        // Pop View Controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Fetch interactions
    func fetchInteractions() {
        
        // (1) Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: photoAssetObject.last!.objectId!)
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
                comments.whereKey("forObjectId", equalTo: photoAssetObject.last!.objectId!)
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
                        shares.whereKey("pointObject", equalTo: photoAssetObject.last!)
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
            self.navigationController?.navigationBar.topItem?.title = "Photo"
        }
        
        // MARK: - UINavigationBar Extension
        // Configure UINavigationBar, and show UITabBar
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
        
        // Fetch interactions
        fetchInteractions()

        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 565
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: photoNotification, object: nil)

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 565
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TimeMediaCell", owner: self, options: nil)?.first as! TimeMediaCell
        
        // Declare parent vc
        cell.delegate = self.navigationController
        
        // Declare user's object
        cell.userObject = photoAssetObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.postObject = photoAssetObject.last!
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        

        // Get Photo Assets
        // (1) Point to User's Object
        if let user = photoAssetObject.last!["byUser"] as? PFUser {
            user.fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // (A) Set username
                    cell.rpUsername.text! = "\(object!["username"] as! String)"
                    
                    // (B) Get profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        
        
        // (2) Fetch Photo
        if let media = photoAssetObject.last!["photoAsset"] as? PFFile {
            // MARK: - SDWebImage
            cell.mediaAsset.sd_setImage(with: URL(string: media.url!), placeholderImage: cell.mediaAsset.image)
        }
        
        // Set caption
        if photoAssetObject.last!["textPost"] != nil {
            cell.textPost.text! = photoAssetObject.last!["textPost"] as! String
        } else {
            cell.textPost.isHidden = true
        }
        
        // (3) Set time
        let from = photoAssetObject.last!.createdAt!
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
            cell.time.text = createdDate.string(from: photoAssetObject.last!.createdAt!)
        }
        
        
        
        // (4) Determine whether the current user has liked this object or not
        if self.likes.contains(where: {$0.objectId == PFUser.current()!.objectId!}) {
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

        // Grow height
        cell.layoutIfNeeded()

        return cell
    }// end cellForRow



}
