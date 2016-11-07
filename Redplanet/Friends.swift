//
//  Friends.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet




// Define identifier
let friendsNewsfeed = Notification.Name("homeFriends")


class Friends: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, CAPSPageMenuDelegate {
    
    // Array to hold friends
    var friends = [PFObject]()
    
    // Array to hold friends' content
    var friendsContent = [PFObject]()
    
    // Initialize parent vc
    var parentNavigator: UINavigationController!
    
    // Page size
    var page: Int = 50
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    
    // Function to refresh data
    func refresh() {
        // Query friends
        queryFriends()
        // End refresher
        refresher.endRefreshing()
    }
    
    
    // Query Current User's Friends
    func queryFriends() {
        
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriends, fFriends])
        friends.includeKey("frontFriend")
        friends.includeKey("endFriend")
        friends.includeKey("frontFriend")
        friends.includeKey("endFriend")
        friends.whereKey("isFriends", equalTo: true)
        friends.findObjectsInBackground(block: { (
            objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                
                // First, append Current User
                self.friends.append(PFUser.current()!)
                
                for object in objects! {
                    if object["frontFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["endFriend"] as! PFUser)
                    }
                    
                    if object["endFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["frontFriend"] as! PFUser)
                    }
                }
                
                print("Friends Count: \(self.friends.count)")
                
                
                // Newsfeeds
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.whereKey("byUser", containedIn: self.friends)
                newsfeeds.order(byDescending: "createdAt")
                newsfeeds.includeKey("byUser")
                newsfeeds.limit = self.page
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        // Dismiss
                        SVProgressHUD.dismiss()
                        
                        // Clear array
                        self.friendsContent.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            /*
                             // Fetch objects only within the past 24 hours
                             let from = object.createdAt!
                             let now = Date()
                             let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                             let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                             
                             // If the difference of the day is less than one day (24 hours),
                             // append the object
                             if difference.hour! <= 24 && difference.day! == 1 {
                             // Append Objects
                             }
                             */
                            
                            self.friendsContent.append(object)
                        }
                        
                        print("Friends feed count: \(self.friendsContent.count)")
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        
                        
                        // Dismiss
                        SVProgressHUD.dismiss()
                        
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
                })
                
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss
                SVProgressHUD.dismiss()
            }
        })
        
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Show Progress
        SVProgressHUD.show()

        // Query Friends
        self.queryFriends()
    
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: friendsNewsfeed, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - UITabBarControllerDelegate Method
//    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
//        
//        if self.parentNavigator?.tabBarController?.selectedIndex == 0 {
//            // Scroll to the top
//            self.tableView!.setContentOffset(CGPoint.zero, animated: true)
//        }
//    }
    
    
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friendsContent.count
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendsCell", for: indexPath) as! FriendsCell
        
        // Set cell's parent VC
        cell.delegate = self
        
        // LayoutViews for rpUserProPic
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // LayoutViews for mediaPreview
        cell.mediaPreview.layoutIfNeeded()
        cell.mediaPreview.layoutSubviews()
        cell.mediaPreview.setNeedsLayout()

        

        // Fetch objects
        friendsContent[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (1) Get user's object
                if let user = object!["byUser"] as? PFUser {
                    
                    // (A) Username
                    cell.rpUsername.text! = user.value(forKey: "realNameOfUser") as! String
                    
                    // (B) Profile Photo
                    // Handle optional chaining for user's profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                    
                    
                    // (C) Set user's object
                    cell.userObject = user
                }
                

                
                
                
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "ph" {
                    
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = 6.00
                    cell.mediaPreview.clipsToBounds = true
                    
                    // Fetch photo
                    if let mediaPreview = object!["photoAsset"] as? PFFile {
                        mediaPreview.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Show mediaPreview
                                cell.mediaPreview.isHidden = false
                                // Set media
                                cell.mediaPreview.image = UIImage(data: data!)

                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                // (B) Text Post
                if object!["contentType"] as! String == "tp" {
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = 6.00
                    cell.mediaPreview.clipsToBounds = true
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    // Set mediaPreview's icon
                    cell.mediaPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                if object!["contentType"] as! String == "sh" {
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = 6.00
                    cell.mediaPreview.clipsToBounds = true
                    
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    
                    // Set background color for mediaPreview
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.mediaPreview.image = UIImage(named: "BlueShared")
                }
                
                

                

                // (D) Profile Photo
                if object!["contentType"] as! String == "pp" {
                    
                    // Make mediaPreview circular
                    cell.mediaPreview.layer.cornerRadius = cell.mediaPreview.layer.frame.size.width/2
                    cell.mediaPreview.layer.borderColor = UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0).cgColor
                    cell.mediaPreview.layer.borderWidth = 1.25
                    cell.mediaPreview.clipsToBounds = true
                    
                    
                    // Fetch Profile photo
                    if let mediaPreview = object!["photoAsset"] as? PFFile {
                        mediaPreview.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Show mediaPreview
                                cell.mediaPreview.isHidden = false
                                // Set media
                                cell.mediaPreview.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                
                
                // (E) In the moment
                // == When user takes a photo and shares it with his/her friends on the spot

                
                // (F) Video
                if object!["contentType"] as! String == "vi" {
                    
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
                
                
                
                /////
                // USER FOR LATER WHEN CONTENT IS DELETED EVERY 24 HOURS
                /////
                //                let dateFormatter = DateFormatter()
                //                dateFormatter.dateFormat = "EEEE"
                //                let timeFormatter = DateFormatter()
                //                timeFormatter.dateFormat = "h:mm a"
                //                let time = "\(dateFormatter.string(from: object!.createdAt!)) \(timeFormatter.string(from: object!.createdAt!))"
                //                cell.rpTime.text! = time
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }

        

        return cell
    }
    
    
    
    // MARK: - Table view delegate method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // TEXT POST
        if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "tp" {
/*
            // Save to Views
            let view = PFObject(className: "Views")
            view["byUser"] = PFUser.current()!
            view["username"] = PFUser.current()!.username!
            view["forObjectId"] = friendsContent[indexPath.row].objectId!
            view.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if error == nil {

                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
*/
            
            
            // Append Object
            textPostObject.append(self.friendsContent[indexPath.row])
            
            
            // Present VC
            let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
            self.parentNavigator.pushViewController(textPostVC, animated: true)
            
        }
        

        
        
        // PHOTO
        if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "ph" {
            /*
             // Save to Views
             let view = PFObject(className: "Views")
             view["byUser"] = PFUser.current()!
             view["username"] = PFUser.current()!.username!
             view["forObjectId"] = friendsContent[indexPath.row].objectId!
             view.saveInBackground(block: {
             (success: Bool, error: Error?) in
             if error == nil {
             
             } else {
             print(error?.localizedDescription as Any)
             }
             })
             */
            
            
            // Append Object
            photoAssetObject.append(self.friendsContent[indexPath.row])
            
            // Present VC
            let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
            self.parentNavigator.pushViewController(photoVC, animated: true)
        }
        
        // SHARED
        if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "sh" {
            if self.friendsContent[indexPath.row].value(forKey: "photoAsset") != nil {
                
                // Append Object
                photoAssetObject.append(self.friendsContent[indexPath.row])
                
                // Push VC
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                self.parentNavigator.pushViewController(photoVC, animated: true)
                
            } else {
                // Append Object
                textPostObject.append(self.friendsContent[indexPath.row])
                
                
                // Push VC
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                self.parentNavigator.pushViewController(textPostVC, animated: true)
            }
        }
        
        
        // PROFILE PHOTO
        if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "pp" {
            // Append user's object
            otherObject.append(self.friendsContent[indexPath.row].value(forKey: "byUser") as! PFUser)
            // Append user's username
            otherName.append(self.friendsContent[indexPath.row].value(forKey: "username") as! String)
            
            // Append object
            proPicObject.append(self.friendsContent[indexPath.row])
            
            // Push VC
            let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
            self.parentNavigator.pushViewController(proPicVC, animated: true)
            
        }
        
        
        // ITM
        /*
        if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "ph" {
            
        }
        */
        
        
        

    }
    
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= friendsContent.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryFriends()
        }
    }

} // End class
