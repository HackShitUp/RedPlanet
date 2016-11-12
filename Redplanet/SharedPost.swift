//
//  SharedPost.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/11/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel
import OneSignal
import SVProgressHUD


// Array to hold the sharedObject
var sharedObject = [PFObject]()

class SharedPost: UITableViewController, UINavigationControllerDelegate {
    
    // Arrays to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
    }
    
    // Function to fetch the shared object
    func fetchInteractions() {
        
        // (1) Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.includeKey("fromUser")
        likes.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                
                
                
                // (2) Fetch comments
                let comments = PFQuery(className: "Comments")
                comments.whereKey("forObjectId", equalTo: sharedObject.last!.objectId!)
                comments.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        // Append object
                        for object in objects! {
                            self.comments.append(object)
                        }
                        
                        
                        
                        // (3) Fetch shares
                        let newsfeeds = PFQuery(className: "Newsfeeds")
                        newsfeeds.whereKey("contentType", equalTo: "sh")
                        newsfeeds.whereKey("pointObject", equalTo: sharedObject.last!.value(forKey: "pointObject") as! PFObject)
                        newsfeeds.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // Clear array
                                self.shares.removeAll(keepingCapacity: false)
                                
                                // Append object
                                for object in objects! {
                                    self.shares.append(object)
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
                })
                
                
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
            self.navigationController?.navigationBar.topItem?.title = "Shared Post"
        }
    }
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch interactions
        fetchInteractions()
        
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 350
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Show navBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sharedPostCell", for: indexPath) as! SharedPostCell
        
        
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = 6.00
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // LayoutViews
        cell.fromRpUserProPic.layoutIfNeeded()
        cell.fromRpUserProPic.layoutSubviews()
        cell.fromRpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.fromRpUserProPic.layer.cornerRadius = cell.fromRpUserProPic.frame.size.width/2
        cell.fromRpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.fromRpUserProPic.layer.borderWidth = 0.5
        cell.fromRpUserProPic.clipsToBounds = true
        
        
        // Design border fpr shared content
        cell.container.layer.borderColor = UIColor.lightGray.cgColor
        cell.container.layer.cornerRadius = 8.00
        cell.container.layer.borderWidth = 0.50
        cell.container.clipsToBounds = true
        
        // By User
        
        // (1) Fetch user
        if let user = sharedObject.last!.value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.fromRpUsername.text! = user["username"] as! String
            
            // (B) Get user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set profile photo
                        cell.fromRpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                        // Set default
                        cell.fromRpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                    }
                })
            }
        }
        
        // (2) set time
        let from = sharedObject.last!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            cell.sharedTime.text = "right now"
        }
        
        if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                cell.sharedTime.text = "1 second ago"
            } else {
                cell.sharedTime.text = "\(difference.second!) seconds ago"
            }
        }
        
        if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                cell.sharedTime.text = "1 minute ago"
            } else {
                cell.sharedTime.text = "\(difference.minute!) minutes ago"
            }
        }
        
        if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                cell.sharedTime.text = "1 hour ago"
            } else {
                cell.sharedTime.text = "\(difference.hour!) hours ago"
            }
        }
        
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                cell.sharedTime.text = "1 day ago"
            } else {
                cell.sharedTime.text = "\(difference.day!) days ago"
            }
        }
        
        if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            cell.sharedTime.text = createdDate.string(from: sharedObject.last!.createdAt!)
        }

        // Content
        // Fetch content
        if let content = sharedObject.last!.value(forKey: "pointObject") as? PFObject {
            content.fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's object
                    if let user = object!["byUser"] as? PFUser {
                        // (A) Set username
                        cell.rpUsername.text! = user["username"] as! String
                        
                        // (C) Get user's profile photo
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
                    }
                    
                    
                    // (2) Fetch content
                    
                    // (A) Text Post
                    if object!["contentType"] as! String == "tp" {
                        
                        // Hide Photo
                        cell.mediaAsset.isHidden = true
                        cell.textPost.isHidden = false
                        
                        // Text post
                        cell.textPost.text! = object!["textPost"] as! String
                    }
                    
                    // (B) Photo OR Profile Photo
                    if object!["contentType"] as! String == "ph" || object!["contentType"] as! String == "pp" || object!["contentType"] as! String == "itm" {
                        
                        cell.mediaAsset.isHidden = false
                        cell.textPost.isHidden = true
                        
                        // (B1) Fetch photo
                        if let photo = object!["photoAsset"] as? PFFile {
                            photo.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // Set Photo
                                    cell.mediaAsset.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                        
                        // (B2) Check for textPost
                        if object!["textPost"] != nil {
                            cell.textPost.isHidden = false
                            cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\(object!["textPost"] as! String)"
                        }
                        
                    }
                    
                    
                    // (3) set time
                    let from = object!.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        cell.sharedTime.text = "right now"
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
                    
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        
        return cell
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
