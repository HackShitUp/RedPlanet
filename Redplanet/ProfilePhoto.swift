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
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
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
        let shares = PFQuery(className: "Shares")
        shares.whereKey("forObjectId", equalTo: proPicObject.last!.objectId!)
        shares.includeKey("fromUser")
        shares.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.shares.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.shares.append(object["fromUser"] as! PFUser)
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
            self.title = "Profile Photo"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Show the user what to do!
        let openedPost = UserDefaults.standard.bool(forKey: "DidOpenPost")
        if openedPost == false && proPicObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {

            // Save
            UserDefaults.standard.set(true, forKey: "DidOpenPost")
            
            // TODO::
            // TRY Using the Framework HERE::
            let alert = UIAlertController(title: "🎉\nCongrats",
                                          message: "You just opened your first Profile Photo!\n\n•Swipe right to leave.\n\n•Swipe left for more options.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        
        

        // Set tableView height
        self.tableView!.estimatedRowHeight = 540
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Stylize title
        configureView()
        
        // Fetch interactions
        fetchInteractions()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: profileNotification, object: nil)
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Stylize title again
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Stylize title again
        configureView()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "proPicCell", for: indexPath) as! ProfilePhotoCell
        
        // Declare parent VC
        cell.delegate = self
        

        // (A) Get profile photo
        if let proPic = proPicObject.last!.value(forKey: "photoAsset") as? PFFile {
            proPic.getDataInBackground(block: {
                (data: Data?, error: Error?) in
                if error == nil {
                    // Set profile photo
                    cell.rpUserProPic.image = UIImage(data: data!)
                } else {
                    print(error?.localizedDescription as Any)
                    // Set default
                    cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                }
            })
        } else {
            // Set default
            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
        }
        
        // (B) Set caption
        if let caption = proPicObject.last!.value(forKey: "textPost") as? String {
            cell.caption.text! = caption
        } else {
            cell.caption.isHidden = true
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
        if self.likes.contains(PFUser.current()!) {
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
    
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        
        // (1) Delete Profile Photo
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            /*
                                            (1) If currentUser is trying to delete his/her's most RECENT Profile Photo...
                                             • Change 'proPicExists' == false
                                             • Save new profile photo
                                             • Delete object from <Newsfeeds>
                                             
                                             (2) OTHERWISE
                                             • Keep 'proPicExists' == true
                                             • Delete object from <Newsfeeds>
                                            
                                            */
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            
                                            
                                            // (1) Check if object is most recent by querying getFirstObject
                                            let recentProPic = PFQuery(className: "Newsfeeds")
                                            recentProPic.whereKey("byUser", equalTo: PFUser.current()!)
                                            recentProPic.whereKey("contentType", equalTo: "pp")
                                            recentProPic.order(byDescending: "createdAt")
                                            recentProPic.getFirstObjectInBackground(block: {
                                                (object: PFObject?, error: Error?) in
                                                if error == nil {
                                                    
                                                    if object! == proPicObject.last! {
                                                        
                                                        // Most recent Profile Photo
                                                        // Delete object
                                                        object?.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Most Recent Profile Photo has been deleted: \(object)")
                                                                
                                                                // Set new profile photo
                                                                let proPicData = UIImageJPEGRepresentation(UIImage(named: "Gender Neutral User-100")!, 0.5)
                                                                let parseFile = PFFile(data: proPicData!)
                                                                
                                                                // User's Profile Photo DOES NOT exist
                                                                PFUser.current()!["proPicExists"] = false
                                                                PFUser.current()!["userProfilePicture"] = parseFile
                                                                PFUser.current()!.saveInBackground(block: {
                                                                    (success: Bool, error: Error?) in
                                                                    if success {
                                                                        
                                                                        print("Deleted current profile photo and saved a new one.")
                                                                        
                                                                        // Dismiss Progress
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
                                                                
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    } else {
                                                        
                                                        // Delete content
//                                                        let newsfeeds = PFQuery(className: "Newsfeeds")
//                                                        newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
//                                                        newsfeeds.whereKey("objectId", equalTo: proPicObject.last!.objectId!)
                                                        
                                                        let content = PFQuery(className: "Newsfeeds")
                                                        content.whereKey("byUser", equalTo: PFUser.current()!)
                                                        content.whereKey("objectId", equalTo: proPicObject.last!.objectId!)
                                                        
                                                        let shares = PFQuery(className: "Newsfeeds")
                                                        shares.whereKey("pointObject", equalTo: proPicObject.last!)
                                                        
                                                        let newsfeeds = PFQuery.orQuery(withSubqueries: [content, shares])
                                                        newsfeeds.findObjectsInBackground(block: {
                                                            (objects: [PFObject]?, error: Error?) in
                                                            if error == nil {
                                                                for object in objects! {
                                                                    // Delete object
                                                                    object.deleteInBackground(block: {
                                                                        (success: Bool, error: Error?) in
                                                                        if success {
                                                                            print("Successfully deleted profile photo: \(object)")
                                                                            
                                                                            // Dismiss
                                                                            SVProgressHUD.dismiss()
                                                                            
                                                                            // Current User's Profile Photo DOES EXIST
                                                                            PFUser.current()!["proPicExists"] = true
                                                                            PFUser.current()!.saveEventually()
                                                                            
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
                                                    
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                
                                                }
                                            })
                                            
                                            
                                            
                                            
        }
        
        
        
        // (2) Edit
        let edit = UITableViewRowAction(style: .normal,
                                        title: "Edit") { (UITableViewRowAction, indexPath) in
                                            
                                            // Append object
                                            editObjects.append(proPicObject.last!)
                                            
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
                                            viewsObject.append(proPicObject.last!)
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
        }
        
        
        
        // (4) Report user and content
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report",
                                                                          message: "Please provide your reason for reporting \(proPicObject.last!.value(forKey: "username") as! String)'s Profile Photo",
                                                preferredStyle: .alert)
                                            
                                            let report = UIAlertAction(title: "Report", style: .destructive) {
                                                [unowned self, alert] (action: UIAlertAction!) in
                                                
                                                let answer = alert.textFields![0]
                                                
                                                let report = PFObject(className: "Block_Reported")
                                                report["from"] = PFUser.current()!.username!
                                                report["fromUser"] = PFUser.current()!
                                                report["to"] = proPicObject.last!.value(forKey: "username") as! String
                                                report["toUser"] = proPicObject.last!.value(forKey: "byUser") as! PFUser
                                                report["forObjectId"] = proPicObject.last!.objectId!
                                                report["type"] = answer.text!
                                                report.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved report: \(report)")
                                                        
                                                        // Dismiss
                                                        let alert = UIAlertController(title: "Successfully Reported",
                                                                                      message: "\(proPicObject.last!.value(forKey: "username") as! String)'s Profile Photo",
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
        
        
        if proPicObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, edit, views]
        } else {
            return [report]
        }
        
        
        
        
    } // End edit action
    
    
    

    



}
