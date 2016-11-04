//
//  TextPost.swift
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



// Global variable to hold object
var textPostObject = [PFObject]()


// Define identifier
let textPostNotification = Notification.Name("textPost")


class TextPost: UITableViewController, UINavigationControllerDelegate {
    
    // Arrays to hold likes and comments
    var likes = [PFObject]()
    var comments = [PFObject]()
    var sharers = [PFObject]()
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Function to count likes
    func fetchInteractions() {
        // (1) Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
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
                comments.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
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
                        shares.whereKey("pointObject", equalTo: textPostObject.last!)
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
            self.navigationController?.navigationBar.topItem?.title = "Text Post"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()


        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 250
        self.tableView!.rowHeight = UITableViewAutomaticDimension

        
        // Fetch Likes and Comments
        fetchInteractions()
        
        // Stylize title
        configureView()
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: textPostNotification, object: nil)
        
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
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
     
        // Show tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Stylize title
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Stylize title
        configureView()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
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
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Content
        let cell = tableView.dequeueReusableCell(withIdentifier: "textPostCell", for: indexPath) as! TextPostCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        
        // Instantiate parent vc
        cell.delegate = self
        
        // Declare user's object
        cell.userObject = textPostObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.contentObject = textPostObject.last!
        
        
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
        cell.textPost.layoutIfNeeded()
        cell.textPost.layoutSubviews()
        cell.textPost.setNeedsLayout()
        
        // Get Text Post Object
        textPostObject.last!.fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                
                // (1) Point to User's Object
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set username
                    cell.rpUsername.text! = user["username"] as! String
                    
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
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                }
                
                // (2) Set Text Post
                cell.textPost.text! = object!["textPost"] as! String
                
                // (3) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    cell.time.text = "\(difference.second!) seconds ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.time.text = "\(difference.hour!) minutes ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.time.text = "\(difference.hour!) hours ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.time.text = "\(difference.day!) days ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    let createdDate = DateFormatter()
                    createdDate.dateFormat = "MMM d, yyyy"
                    cell.time.text = createdDate.string(from: object!.createdAt!)
                }
                
                
                
                // (4) Determine whether the current user has liked this object or not
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
        

    } // End cellForRowAt
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "textPostCell", for: indexPath) as! TextPostCell

        
        
        // (1) Delete Text Post
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            
                                            // Delete content
                                            let newsfeeds = PFQuery(className: "Newsfeeds")
                                            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
                                            newsfeeds.whereKey("objectId", equalTo: textPostObject.last!.objectId!)
                                            newsfeeds.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        // Delete object
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted object: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                                
                                                                // Reload newsfeed
                                                                NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                                
                                                                // Reload myProfile
                                                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                                
                                                                // Pop view controller
                                                                self.navigationController?.popViewController(animated: true)
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })

        }
        
        // (2) Edit
        let edit = UITableViewRowAction(style: .normal,
                                         title: " Edit ") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            
                                            // TODO::
                                            // Edit Content
                                            
                                            // Close cell
                                            self.tableView!.setEditing(false, animated: true)
                                            
        }
        
        
        // (3) Views
        let views = UITableViewRowAction(style: .normal,
                                        title: " Views ") { (UITableViewRowAction, indexPath) in
                                            // Append object
                                            viewsObject.append(textPostObject.last!)
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
                                            
        }
        
        
        // (4) Block user
        let report = UITableViewRowAction(style: .normal,
                                          title: "Block") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report this Text Post?",
                                                                          message: "Are you sure you'd like to report \(textPostObject.last!.value(forKey: "username") as! String)'s Text Post?",
                                                                          preferredStyle: .alert)
                                            
                                            let yes = UIAlertAction(title: "yes",
                                                                    style: .destructive,
                                                                    handler: { (alertAction: UIAlertAction!) -> Void in
                                                                        // I have to manually delete all "blocked objects..." -__-
                                                                        let block = PFObject(className: "Block_Reported")
                                                                        block["from"] = PFUser.current()!.username!
                                                                        block["fromUser"] = PFUser.current()!
                                                                        block["to"] = cell.rpUsername.text!
                                                                        block["forObjectId"] = self.comments[indexPath.row].objectId!
                                                                        block.saveInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully reported \(block)")
                                                                                
                                                                            } else {
                                                                                print(error?.localizedDescription as Any)
                                                                            }
                                                                        })
                                                                        // Close cell
                                                                        tableView.setEditing(false, animated: true)
                                            })
                                            
                                            let no = UIAlertAction(title: "no",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            alert.addAction(yes)
                                            alert.addAction(no)
                                            self.present(alert, animated: true, completion: nil)
                                            
        }
        
        
        
        
        
        // Set background images
        // Red
        delete.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        // Baby blue
        edit.backgroundColor = UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0)
        // Gray
        views.backgroundColor = UIColor.lightGray
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.91, blue:0.04, alpha:1.0)
        

        if textPostObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, edit, views]
        } else {
            return [report]
        }
        

        
        
    } // End edit action
    
    
    
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y < -70 {
            // Pop view controller
//            self.navigationController!.popViewController(animated: true)
        }
    }
    


} // End
