//
//  ProfilePhoto.swift
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
import SimpleAlert
import SDWebImage

// ProfilePhoto's Object Id
var proPicObject = [PFObject]()

// Define identifier
let profileNotification = Notification.Name("profileLike")


class ProfilePhoto: UITableViewController, UINavigationControllerDelegate {
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Remove last
        proPicObject.removeLast()
        
        // Pop view controller
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
        
        // (1) Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: proPicObject.last!.objectId!)
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
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
        
        // (2) Comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: proPicObject.last!.objectId!)
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
                
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data
            self.tableView!.reloadData()
        }
        
        
        // (3) Shares
        let shares = PFQuery(className: "Newsfeeds")
        shares.whereKey("pointObject", equalTo: proPicObject.last!)
        shares.includeKey("fromUser")
        shares.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.shares.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.shares.append(object["byUser"] as! PFUser)
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
            self.navigationController?.navigationBar.topItem?.title = "Profile Photo"
        }
        
        // Configure nav bar && hide tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Stylize title
        configureView()
        
        // Fetch interactions
        fetchInteractions()

        // Set tableView height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 540
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: profileNotification, object: nil)
        
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
        return 540
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("ProPicCell", owner: self, options: nil)?.first as! ProPicCell
        
        // Declare parent VC
        cell.delegate = self.navigationController
        
        cell.postObject = proPicObject.last!
        cell.userObject = proPicObject.last!.value(forKey: "byUser") as! PFUser
        
        // Configure size
        cell.contentView.frame = cell.contentView.frame
        cell.smallProPic.layoutIfNeeded()
        cell.smallProPic.layoutSubviews()
        cell.smallProPic.setNeedsLayout()
        cell.smallProPic.layer.cornerRadius = cell.smallProPic.frame.size.width/2
        cell.smallProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.smallProPic.layer.borderWidth = 0.50
        cell.smallProPic.clipsToBounds = true
        
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.darkGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 1.50
        cell.rpUserProPic.clipsToBounds = true
        
        // (A) Get profile photo
        if let proPic = proPicObject.last!.value(forKey: "photoAsset") as? PFFile {
            // MARK: - SDWebImage
            cell.smallProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: cell.rpUserProPic.image)
        }
        
        // (B) Set caption
        if let caption = proPicObject.last!.value(forKey: "textPost") as? String {
            cell.textPost.text! = caption
        } else {
            cell.textPost.isHidden = true
        }
        
        // (C) Set user's fullName
        cell.rpUsername.text! = otherObject.last!.value(forKey: "realNameOfUser") as! String
        
        // (D) Set time
        let from = proPicObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            cell.time.text = "right now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                cell.time.text = "1 second ago"
            } else {
                cell.time.text = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                cell.time.text = "1 minute ago"
            } else {
                cell.time.text = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                cell.time.text = "1 hour ago"
            } else {
                cell.time.text = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                cell.time.text = "1 day ago"
            } else {
                cell.time.text = "\(difference.day!) days ago"
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            cell.time.text = createdDate.string(from: proPicObject.last!.createdAt!)
        }

        // (F) Set likes
        if self.likes.count == 0 {
            cell.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        
        // (FA) Manipulate likes
        if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
            // liked
            cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
            cell.likeButton.setTitle("liked", for: .normal)
        } else {
            // notliked
            cell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            cell.likeButton.setTitle("notLiked", for: .normal)
        }
        
        // (G) Count comments
        if self.comments.count == 0 {
            cell.numberOfComments.setTitle("comments", for: .normal)
        } else if self.comments.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
        }
        
        // (H) Count shares
        if self.shares.count == 0 {
            cell.numberOfShares.setTitle("shares", for: .normal)
        } else if self.shares.count == 1 {
            cell.numberOfShares.setTitle("1 share", for: .normal)
        } else {
            cell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
        }


        return cell
    } // end cellForRow


}
