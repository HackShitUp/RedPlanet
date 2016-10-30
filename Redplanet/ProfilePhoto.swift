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



// Define identifier
let profileNotification = Notification.Name("profileLike")


// ProfilePhoto's Object Id
var proPicObject = [PFObject]()

class ProfilePhoto: UITableViewController, UINavigationControllerDelegate {
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Fetch interactions
        fetchInteractions()
        
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
                print(error?.localizedDescription)
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
                print(error?.localizedDescription)
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
                print(error?.localizedDescription)
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
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Profile Photo"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set tableView height
        self.tableView!.estimatedRowHeight = 540
        self.tableView!.rowHeight = UITableViewAutomaticDimension

        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: profileNotification, object: nil)
        
        // Stylize title
        configureView()
        
        // Fetch interactions
        fetchInteractions()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: profileNotification, object: nil)

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        if let proPic = proPicObject.last!.value(forKey: "userProfilePicture") as? PFFile {
            proPic.getDataInBackground(block: {
                (data: Data?, error: Error?) in
                if error == nil {
                    // Set profile photo
                    cell.rpUserProPic.image = UIImage(data: data!)
                } else {
                    print(error?.localizedDescription)
                    // Set default
                    cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                }
            })
        } else {
            // Set default
            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
        }
        
        // (B) Set caption
        if let caption = proPicObject.last!.value(forKey: "proPicCaption") as? String {
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
        
        // (E) Logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            cell.time.text = "now"
        }
        
        if difference.second! > 0 && difference.minute! == 0 {
            cell.time.text = "\(difference.second!) seconds ago"
        }
        
        if difference.minute! > 0 && difference.hour! == 0 {
            cell.time.text = "\(difference.minute!) minutes ago"
        }
        
        if difference.hour! > 0 && difference.day! == 0 {
            cell.time.text = "\(difference.hour!) hours ago"
        }
        
        if difference.day! > 0 && difference.weekOfMonth! == 0 {
            cell.time.text = "\(difference.day!) days ago"
        }
        
        if difference.weekOfMonth! > 0 {
            cell.time.text = "\(difference.weekOfMonth!) weeks ago"
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
        } else if self.likes.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.likes.count) comments", for: .normal)
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
    }
    



}
