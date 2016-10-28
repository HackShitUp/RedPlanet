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


// Global array to hold the object
var mediaAssetObject = [PFObject]()

class MediaAsset: UITableViewController, UINavigationControllerDelegate {
    
    
    // Arrays to hold likes and comments
    var likes = [PFObject]()
    var comments = [PFObject]()
        
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop View Controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    // Fetch interactions
    func fetchInteractions() {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: mediaAssetObject.last!.objectId!)
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
        
        
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: mediaAssetObject.last!.objectId!)
        comments.order(byDescending: "createdAt")
        comments.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.comments.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.comments.append(object)
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
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Photo"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 555
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaAssetCell", for: indexPath) as! MediaAssetCell
        
        // Declare parent vc
        cell.delegate = self
        
        
        // Declare user's object
        cell.userObject = mediaAssetObject.last!.value(forKey: "byUser") as! PFUser
        
        // Declare content's object
        cell.contentObject = mediaAssetObject.last!
        
        
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
        mediaAssetObject.last!.fetchInBackground {
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
                                print(error?.localizedDescription)
                                // (B2) Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                }
                
                
                // (2)
                if let media = object!["mediaAsset"] as? PFFile {
                    media.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // set media asset
                            cell.rpMedia.image = UIImage(data: data!)
                            
                        } else {
                            print(error?.localizedDescription)
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
                    let createdDate = DateFormatter()
                    createdDate.dateFormat = "MMM d"
                    cell.time.text = createdDate.string(from: object!.createdAt!)
                }
                
                
                
                // (4) Determine whether the current user has liked this object or not
                if self.likes.contains(PFUser.current()!) {
                    // Set button title
                    cell.likeButton.setTitle("like", for: .normal)
                    // Set/ button image
                    cell.likeButton.setImage(UIImage(named: "Like Filled=100"), for: .normal)
                } else {
                    // Set button title
                    cell.likeButton.setTitle("unlike", for: .normal)
                    
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

                
                
            } else {
                print(error?.localizedDescription)
            }
        }
        
        // Grow height
        cell.layoutIfNeeded()

        return cell
    }// end cellForRow
    
    
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y < -70 {
            // Pop view controller
            self.navigationController!.popViewController(animated: true)
        }
    }
    


}
