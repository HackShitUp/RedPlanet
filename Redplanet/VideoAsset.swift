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
import SimpleAlert

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
        self.tableView!.estimatedRowHeight = 495
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
            
            
            let alert = AlertController(title: "🎉\nCongrats, you viewed your first Video!",
                                          message: "•Tap on the preview to play the video\n• Swipe down to leave the video\n•Swipe left for Views 🙈",
                                          style: .alert)
            
            // Design content view
            alert.configContentView = { view in
                if let view = view as? AlertContentView {
                    view.backgroundColor = UIColor.white
                    view.titleLabel.textColor = UIColor.black
                    view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 17)
                    view.messageLabel.textColor = UIColor.black
                    view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                    view.textBackgroundView.layer.cornerRadius = 3.00
                    view.textBackgroundView.clipsToBounds = true
                }
            }
            // Design corner radius
            alert.configContainerCornerRadius = {
                return 14.00
            }
            
            let ok = AlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 495
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
        
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.contentView.frame

        // Set parent VC
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
        cell.videoPreview.layoutIfNeeded()
        cell.videoPreview.layoutSubviews()
        cell.videoPreview.setNeedsLayout()
        
        // Make Vide Preview Circular
        cell.videoPreview.layer.cornerRadius = cell.videoPreview.frame.size.width/2
        cell.videoPreview.layer.borderColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0).cgColor
        cell.videoPreview.layer.borderWidth = 3.50
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
                        cell.videoPreview.image = UIImage(cgImage: cgImage)
                        
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
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // (1) Delete Text Post
        let delete = UITableViewRowAction(style: .normal,
                                          title: "X\nDelete") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            SVProgressHUD.show(withStatus: "Deleting")
                                            
                                            // Delete content
                                            let content = PFQuery(className: "Newsfeeds")
                                            content.whereKey("byUser", equalTo: PFUser.current()!)
                                            content.whereKey("objectId", equalTo: videoObject.last!.objectId!)
                                            
                                            let shares = PFQuery(className: "Newsfeeds")
                                            shares.whereKey("pointObject", equalTo: videoObject.last!)
                                            
                                            let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
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
                                                                _ = self.navigationController?.popViewController(animated: true)
                                                                
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
                                        title: "🔩\nEdit") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Append object
                                            editObjects.append(videoObject.last!)
                                            
                                            // Push VC
                                            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                            self.navigationController?.pushViewController(editVC, animated: true)
                                            
                                            
                                            // Close cell
                                            self.tableView!.setEditing(false, animated: true)
                                            
        }
        
        
        // (3) Views
        let views = UITableViewRowAction(style: .normal,
                                         title: "🙈\nViews") { (UITableViewRowAction, indexPath) in
                                            // Append object
                                            viewsObject.append(videoObject.last!)
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
                                            
        }
        
        
        // (4) Report Content
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report",
                                                                          message: "Please provide your reason for reporting \(videoObject.last!.value(forKey: "username") as! String)'s Text Post",
                                                preferredStyle: .alert)
                                            
                                            let report = UIAlertAction(title: "Report", style: .destructive) {
                                                [unowned self, alert] (action: UIAlertAction!) in
                                                
                                                let answer = alert.textFields![0]
                                                
                                                // Save to <Block_Reported>
                                                let report = PFObject(className: "Block_Reported")
                                                report["from"] = PFUser.current()!.username!
                                                report["fromUser"] = PFUser.current()!
                                                report["to"] = videoObject.last!.value(forKey: "username") as! String
                                                report["toUser"] = videoObject.last!.value(forKey: "byUser") as! PFUser
                                                report["forObjectId"] = videoObject.last!.objectId!
                                                report["type"] = answer.text!
                                                report.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved report: \(report)")
                                                        
                                                        // Dismiss
                                                        let alert = UIAlertController(title: "Successfully Reported",
                                                                                      message: "\(videoObject.last!.value(forKey: "username") as! String)'s Text Post",
                                                            preferredStyle: .alert)
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .default,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                            }
                                            
                                            
                                            let cancel = UIAlertAction(title: "Cancel",
                                                                       style: .cancel,
                                                                       handler: nil)
                                            
                                            
                                            alert.addTextField(configurationHandler: nil)
                                            alert.addAction(report)
                                            alert.addAction(cancel)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
        }
        
        
        
        
        
        // Set background colors
        /*
         // Red
         delete.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
         // Grey
         edit.backgroundColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0)
         // Yellow
         views.backgroundColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0)
         // Blue
         report.backgroundColor = UIColor(red:0.29, green:0.56, blue:0.89, alpha:1.0)
         */
        
        
        // Super Dark Gray
        delete.backgroundColor = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.0)
        // Dark Gray
        edit.backgroundColor = UIColor(red:0.39, green:0.39, blue:0.39, alpha:1.0)
        // Red
        views.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0)
        
        
        
        if videoObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, edit, views]
        } else {
            return [report]
        }
        
        
        
    } // End edit action
    

    

}
