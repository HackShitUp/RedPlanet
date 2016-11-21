//
//  HashTags.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/13/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import OneSignal
import SVProgressHUD


// Array to hold hashtag objects
var hashtags = [String]()


// Define Notification
let hashtagNotification = Notification.Name("hashTag")

class HashTags: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UINavigationControllerDelegate {
    
    // Array to hold objects
    var hashtagStrings = [String]()
    var hashtagObjects = [PFObject]()
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Array to determine content types
    let contentTypes = ["tp", "ph"]
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch hashtags
        fetchHashtags()
        
        // Reload Data
        self.tableView!.reloadData()
    }
    
    
    // Function to fetch hashtags
    func fetchHashtags() {
        // Fetch in News Feeds
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", containedIn: self.hashtagStrings)
        newsfeeds.whereKey("contentType", containedIn: self.contentTypes)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.hashtagObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.hashtagObjects.append(object)
                }
                
                print("Number: \(self.hashtagObjects.count)")
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "#\(hashtags.last!)"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        
        
        let queryHashtag = PFQuery(className: "Hashtags")
        queryHashtag.whereKey("hashtag", equalTo: hashtags.last!)
        queryHashtag.order(byDescending: "createdAt")
        queryHashtag.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss
                SVProgressHUD.dismiss()
                
                // Clear array
                self.hashtagStrings.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.hashtagStrings.append(object["forObjectId"] as! String)
                }
                
                // DZNEmptyDataSet
                if self.hashtagObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                // Fetch hashtags
                self.fetchHashtags()
                
            } else {
                print(error?.localizedDescription as Any)
                // Dismiss
                SVProgressHUD.dismiss()
            }
        })

        // Stylize title
        configureView()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 515
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Rid of lines in tableview
        self.tableView.tableFooterView = UIView()
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Add observer
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: hashtagNotification, object: nil)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if hashtagObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "＃\nUh Oh\n No Hashtags to show..."
        let font = UIFont(name: "AvenirNext-Medium", size: 21.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        print("ITEMS: \(self.hashtagObjects.count)")
        return self.hashtagObjects.count
    }

    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 515
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hashtagsCell", for: indexPath) as! HashTagsCell

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
        
        
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        
        // Instantiate parent vc
        cell.delegate = self

        // Set content's object
        cell.contentObject = hashtagObjects[indexPath.row]
        
        // (1) Fetch user
        if let user = hashtagObjects[indexPath.row].value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.rpUsername.text! = user["username"] as! String
            
            // (B) Get user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
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
            }
            
            // (C) Set fromUser's object
            cell.userObject = user
        }
        
        
        // (2) set time
        let from = hashtagObjects[indexPath.row].createdAt!
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
            cell.time.text = createdDate.string(from: hashtagObjects[indexPath.row].createdAt!)
        }
        
        
        
        
        // (3) Set Content
        // (A) Text Post
        if hashtagObjects[indexPath.row].value(forKey:"contentType") as! String == "tp" {
            
            // Hide Photo
            cell.photoAsset.isHidden = true
            cell.textPost.isHidden = false
            
            // Text post
            cell.textPost.text! = hashtagObjects[indexPath.row].value(forKey: "textPost") as! String
        }
        
        // (B) Photo OR Profile Photo
        if hashtagObjects[indexPath.row].value(forKey:"contentType") as! String == "ph" {
            
            cell.photoAsset.isHidden = false
            cell.textPost.isHidden = true
            
            // (B1) Fetch photo
            if let photo = hashtagObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set Photo
                        cell.photoAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            // (B2) Check for textPost
            if hashtagObjects[indexPath.row].value(forKey: "textPost") != nil {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(hashtagObjects[indexPath.row].value(forKey: "textPost") as! String)"
            } else {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            }
            
        }

        
        
        // (4) Set count title for likes
        // (A)
        let likes = PFQuery(className: "Likes")
        likes.includeKey("fromUser")
        likes.whereKey("forObjectId", equalTo: self.hashtagObjects[indexPath.row].objectId!)
        likes.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            
            
            // Check whether user has liked it or not
            if self.likes.contains(PFUser.current()!) {
                // unlike
                cell.likeButton.setTitle("liked", for: .normal)
                cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
            } else {
                // like
                cell.likeButton.setTitle("notliked", for: .normal)
                cell.likeButton.setTitle("Like-100", for: .normal)
            }
            
            // Set number of likes
            if self.likes.count == 0 {
                cell.numberOfLikes.setTitle("likes", for: .normal)
            } else if self.likes.count == 1 {
                cell.numberOfLikes.setTitle("1 like", for: .normal)
            } else {
                cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
            }
            
        })
        // (B) Comments
        let comments = PFQuery(className: "Comments")
        comments.includeKey("byUser")
        comments.whereKey("forObjectId", equalTo: self.hashtagObjects[indexPath.row].objectId!)
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.comments.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.comments.append(object["byUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Set number of comments
            if self.comments.count == 0 {
                cell.numberOfComments.setTitle("comments", for: .normal)
            } else if self.comments.count == 1 {
                cell.numberOfComments.setTitle("1 comment", for: .normal)
            } else {
                cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
            }
        })
        // (C) Shares
        let shares = PFQuery(className: "Newsfeeds")
        shares.includeKey("byUser")
        shares.whereKey("pointObject", equalTo: self.hashtagObjects[indexPath.row])
        shares.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.shares.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.shares.append(object["byUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Set number of shares
            if self.shares.count == 0 {
                cell.numberOfShares.setTitle("shares", for: .normal)
            } else if self.shares.count == 1 {
                cell.numberOfShares.setTitle("1 share", for: .normal)
            } else {
                cell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
            }
        })
        

        return cell
    }
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // (1) Delete Text Post
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.show()

                                            let content = PFQuery(className: "Newsfeeds")
                                            content.whereKey("byUser", equalTo: PFUser.current()!)
                                            content.whereKey("objectId", equalTo: self.hashtagObjects[indexPath.row].objectId!)
                                            
                                            let shares = PFQuery(className: "Newsfeeds")
                                            shares.whereKey("pointObject", equalTo: self.hashtagObjects[indexPath.row].objectId!)
                                            
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
                                                                
                                                                // Refresh
                                                                NotificationCenter.default.post(name: hashtagNotification, object: nil)
                                                                
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
                                            editObjects.append(self.hashtagObjects[indexPath.row])
                                            
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
                                            viewsObject.append(self.hashtagObjects[indexPath.row])
                                            
                                            // Push VC
                                            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                                            self.navigationController?.pushViewController(viewsVC, animated: true)
                                            
        }
        
        
        // (4) Report Content
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
                                            let alert = UIAlertController(title: "Report",
                                                                          message: "Please provide your reason for reporting \(self.hashtagObjects[indexPath.row].value(forKey: "username") as! String)'s Post",
                                                preferredStyle: .alert)
                                            
                                            let report = UIAlertAction(title: "Report", style: .destructive) {
                                                [unowned self, alert] (action: UIAlertAction!) in
                                                
                                                let answer = alert.textFields![0]
                                                
                                                // Save to <Block_Reported>
                                                let report = PFObject(className: "Block_Reported")
                                                report["from"] = PFUser.current()!.username!
                                                report["fromUser"] = PFUser.current()!
                                                report["to"] = self.hashtagObjects[indexPath.row].value(forKey: "username") as! String
                                                report["toUser"] = self.hashtagObjects[indexPath.row].value(forKey: "byUser") as! PFUser
                                                report["forObjectId"] = self.hashtagObjects[indexPath.row].objectId!
                                                report["type"] = answer.text!
                                                report.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved report: \(report)")
                                                        
                                                        // Dismiss
                                                        let alert = UIAlertController(title: "Successfully Reported",
                                                                                      message: "\(self.hashtagObjects[indexPath.row].value(forKey: "username") as! String)'s Post",
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
        
        // Light Red
        delete.backgroundColor = UIColor(red:1.00, green:0.29, blue:0.29, alpha:1.0)
        // Baby blue
        edit.backgroundColor = UIColor.darkGray
        // Light Gray
        views.backgroundColor = UIColor.gray
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
        
        
        if self.hashtagObjects[indexPath.row].value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, edit, views]
        } else {
            return [report]
        }
        
        
        
        
    } // End edit action
    
 

}
