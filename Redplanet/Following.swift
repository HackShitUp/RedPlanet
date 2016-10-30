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
                print(error?.localizedDescription)
                
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
        
        
        // Set bounds for textPreview
        cell.textPreview.clipsToBounds = true
        
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
                                print(error?.localizedDescription)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                    
                    // (C) Set user's object
                    cell.userObject = user
                }
                
                
                
                // (2) Determine Content Type
                if let mediaPreview = object!["mediaAsset"] as? PFFile {
                    mediaPreview.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Show media
                            cell.mediaPreview.isHidden = false
                            // Set media
                            cell.mediaPreview.image = UIImage(data: data!)
                            // Hide text
                            cell.textPreview.isHidden = true
                        } else {
                            print(error?.localizedDescription)
                        }
                    })
                } else {
                    // Show text
                    cell.textPreview.isHidden = false
                    // Hide media
                    cell.mediaPreview.isHidden = true
                    // Set text
                    cell.textPreview.text! = object!["textPost"] as! String
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
                    cell.time.text = "\(difference.second!)s ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.time.text = "\(difference.minute!)m ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.time.text = "\(difference.hour!)h ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.time.text = "\(difference.day!)d ago"
                }

                if difference.weekOfMonth! > 0 {
                    let createdDate = DateFormatter()
                    createdDate.dateFormat = "MMM d"
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
                print(error?.localizedDescription)
            }
        }
        

        return cell
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.followingContent[indexPath.row].value(forKey: "mediaAsset") == nil {
            
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
                    print(error?.localizedDescription)
                    
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
             print(error?.localizedDescription)
             }
             })
             */
            
            
            // Append Object
            mediaAssetObject.append(self.followingContent[indexPath.row])
            
            // Present VC
            let mediaVC = self.storyboard?.instantiateViewController(withIdentifier: "mediaAssetVC") as! MediaAsset
            self.parentNavigator.pushViewController(mediaVC, animated: true)
            
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
