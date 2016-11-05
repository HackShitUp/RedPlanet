//
//  Following.swift
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


class Following: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Array to hold following's content
    var followingContent = [PFObject]()
    
    // Initialize Parent navigationController
    var parentNavigator: UINavigationController!
    
    
    // Page size
    var page: Int = 50
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    // Function to refresh data
    func refresh() {
        // Query following
        queryFollowing()
        // End refresher
        refresher.endRefreshing()
    }
    
    
    
    // Query Following
    func queryFollowing() {
        
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: myFollowing)
        newsfeeds.limit = self.page
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.followingContent.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.followingContent.append(object)
                }
                
                
                // DZNEmptyDataSet
                if self.followingContent.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.tableFooterView = UIView()
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()

        // Query Following
        self.queryFollowing()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return followingContent.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followingCell", for: indexPath) as! FollowingCell
        
        
        // Initiliaze and set parent VC
        cell.delegate = self
        
        // LayoutViews
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
        
        // Make mediaPreview cornered square
        cell.mediaPreview.layer.cornerRadius = 6.00
        cell.mediaPreview.clipsToBounds = true
        
        // Fetch content
        self.followingContent[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get and set user's object
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set usrername
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
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    // Set mediaPreview's icon
                    cell.mediaPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                // Complete this
                if object!["contentType"] as! String == "sh" {
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    
                    // Set background color for mediaPreview
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.mediaPreview.image = UIImage(named: "BlueShared")
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

                
                
                
            } else{
                print(error?.localizedDescription as Any)
            }
        }
        

        return cell
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.followingContent[indexPath.row].value(forKey: "photoAsset") == nil {
            
            // Show Progress
//            SVProgressHUD.show()
            
            print("Tapped")
            /*
            // Save to Views
            let view = PFObject(className: "Views")
            view["byUser"] = PFUser.current()!
            view["username"] = PFUser.current()!.username!
            view["forObjectId"] = followingContent[indexPath.row].objectId!
            view.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                }
            })
            */
            
            // Append Object
            textPostObject.append(self.followingContent[indexPath.row])
            
            // Present VC
            let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
            self.parentNavigator.pushViewController(textPostVC, animated: true)
            
            
        } else {
            
            /*
             // Save to Views
             let view = PFObject(className: "Views")
             view["byUser"] = PFUser.current()!
             view["username"] = PFUser.current()!.username!
             view["forObjectId"] = followingContent[indexPath.row].objectId!
             view.saveInBackground(block: {
             (success: Bool, error: Error?) in
             if error == nil {
             
             } else {
             print(error?.localizedDescription as Any)
             }
             })
             */
            
            
            // Append Object
            photoAssetObject.append(self.followingContent[indexPath.row])
            
            // Present VC
            let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
            self.parentNavigator.pushViewController(photoVC, animated: true)
            
        }
        
    } // end didSelect delegate
    

    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= followingContent.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryFollowing()
        }
    }

}
