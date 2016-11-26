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
        // Pop View Controller
        self.navigationController?.popViewController(animated: true)
        
        print("Fired with sender: \(sender)")
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        refresher.endRefreshing()
        
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
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Show the user what to do!
        let openedPost = UserDefaults.standard.bool(forKey: "DidOpenPost")
        if openedPost == false && photoAssetObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenPost")
            
            // TODO::
            // TRY Using the Framework HERE::
            let alert = UIAlertController(title: "🎉\nCongrats",
                                          message: "You just viewed your first Photo!\n•Swipe right to leave.\n•Swipe left for more options.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        
        

        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 570
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Fetch interactions
        fetchInteractions()
        
        // Stylize title
        configureView()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabbarcontroller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: photoNotification, object: nil)
        
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoAssetCell", for: indexPath) as! PhotoAssetCell
        
        // Declare parent vc
        cell.delegate = self
        
        
        // Declare user's object
        cell.userObject = photoAssetObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.contentObject = photoAssetObject.last!
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        

        // Get Media Asset Object
        photoAssetObject.last!.fetchInBackground {
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
                
                
                // (2)
                if let media = object!["photoAsset"] as? PFFile {
                    media.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // set media asset
                            cell.rpMedia.image = UIImage(data: data!)
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
                
                // Set caption
                if object!["textPost"] != nil {
                    cell.caption.text! = object!["textPost"] as! String
                } else {
                    cell.caption.isHidden = true
                }
                
                // (3) Set time
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
    }// end cellForRow
    
    
    
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoAssetCell", for: indexPath) as! PhotoAssetCell
        
        
        
        // (1) Delete Photo
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            // Ask before deleting???
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            
                                            // Delete content
//                                            let newsfeeds = PFQuery(className: "Newsfeeds")
//                                            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
//                                            newsfeeds.whereKey("objectId", equalTo: photoAssetObject.last!.objectId!)
//                                            newsfeeds.whereKey("pointObject", equalTo: photoAssetObject.last!)
                                            
                                            
                                            
                                            let content = PFQuery(className: "Newsfeeds")
                                            content.whereKey("byUser", equalTo: PFUser.current()!)
                                            content.whereKey("objectId", equalTo: photoAssetObject.last!.objectId!)
                                            
                                            let shares = PFQuery(className: "Newsfeeds")
                                            shares.whereKey("pointObject", equalTo: photoAssetObject.last!)
                                            
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
                                        title: "Edit") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Append object
                                            editObjects.append(photoAssetObject.last!)
                                            
                                            
                                            // Push VC
                                            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
                                            self.navigationController?.pushViewController(editVC, animated: true)
                                            
                                            
                                            
                                            
                                            // Close cell
                                            self.tableView!.setEditing(false, animated: true)
                                            
        }
        
        
        // (3) Views
        let views = UITableViewRowAction(style: .normal,
                                         title: "Views") { (UITableViewRowAction, indexPath) in
                                            // Append object
                                            viewsObject.append(photoAssetObject.last!)
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
                                            
        }
        
        
        // (4) Report user
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report",
                                                                          message: "Please provide your reason for reporting \(photoAssetObject.last!.value(forKey: "username") as! String)'s Photo",
                                                preferredStyle: .alert)
                                            
                                            let report = UIAlertAction(title: "Report", style: .destructive) {
                                                [unowned self, alert] (action: UIAlertAction!) in
                                                
                                                let answer = alert.textFields![0]
                                                
                                                
                                                // Save to <Block_Reported>
                                                let report = PFObject(className: "Block_Reported")
                                                report["from"] = PFUser.current()!.username!
                                                report["fromUser"] = PFUser.current()!
                                                report["to"] = photoAssetObject.last!.value(forKey: "username") as! String
                                                report["toUser"] = photoAssetObject.last!.value(forKey: "byUser") as! PFUser
                                                report["forObjectId"] = photoAssetObject.last!.objectId!
                                                report["type"] = answer.text!
                                                report.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved report: \(report)")
                                                        
                                                        // Dismiss
                                                        let alert = UIAlertController(title: "Successfully Reported",
                                                                                      message: "\(photoAssetObject.last!.value(forKey: "username") as! String)'s Photo",
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
        
        // Set background colors
        
        // Light Red
        delete.backgroundColor = UIColor(red:1.00, green:0.29, blue:0.29, alpha:1.0)
        // Baby blue
        edit.backgroundColor = UIColor.darkGray
        //        edit.backgroundColor = UIColor(red:0.45, green:0.69, blue:0.86, alpha:1.0)
        // Light Gray
        views.backgroundColor = UIColor.gray
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
        
        
        if photoAssetObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, edit, views]
        } else {
            return [report]
        }
        
        
        
        
    } // End edit action

    
    
    
    
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y < -70 {
            // Pop view controller
//            self.navigationController?.popViewController(animated: true)
        }
    }
    


}
