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


// Define Notification
let followingNewsfeed = Notification.Name("followingNewsfeed")


class Following: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Array to hold following's content
    var followingContent = [PFObject]()
    
    // Initialize Parent navigationController
    var parentNavigator: UINavigationController!
    
    
    // Page size
    var page: Int = 50
    
    // Handle objects skipped
    var skipped = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Array to hold contenTypes
    var contentTypes = ["ph",
                        "tp",
                        "sh",
                        "vi",
                        "itm"]
    
    
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
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.whereKey("byUser", containedIn: myFollowing)
        newsfeeds.whereKey("contentType", containedIn: self.contentTypes)
        newsfeeds.limit = self.page
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.followingContent.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time configs
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    
                    if object.value(forKey: "contentType") as! String == "itm" {
                        if difference.hour! < 24 {
                            self.followingContent.append(object)
                        } else {
                            self.followingContent.append(object)
                        }
                    } else {
                        self.followingContent.append(object)
                    }
                }
                
                
                // DZNEmptyDataSet
                if self.followingContent.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.tableFooterView = UIView()
                }
                
            } else {
                if (error?.localizedDescription.hasSuffix("offline."))! {
                    SVProgressHUD.dismiss()
                }
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)

        // Query Following
        self.queryFollowing()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: followingNewsfeed, object: nil)
    }
    

    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if followingContent.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nYour Following's News Feed is empty."
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Redplanet is more fun when you're following the things you love."
        let font = UIFont(name: "AvenirNext-Medium", size: 17.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Button title
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find Things to Follow"
        let font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Show search
        let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.parentNavigator.pushViewController(search, animated: true)
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
        
        // LayoutViews for iconicPreview
        cell.iconicPreview.layoutIfNeeded()
        cell.iconicPreview.layoutSubviews()
        cell.iconicPreview.setNeedsLayout()
        
        // Set default contentMode
        cell.iconicPreview.contentMode = .scaleAspectFill
        // Make iconicPreview cornered square
        cell.iconicPreview.layer.cornerRadius = 12.00
        cell.iconicPreview.clipsToBounds = true

        
        // Fetch content
        self.followingContent[indexPath.row].fetchIfNeededInBackground(block: {
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
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    // (C) Set user's object
                    cell.userObject = user
                }
                
                
                
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "ph" {
                    if let iconicPreview = object!["photoAsset"] as? PFFile {
                        iconicPreview.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Show iconicPreview
                                cell.iconicPreview.isHidden = false
                                // Set media
                                cell.iconicPreview.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                // (B) Text Post
                if object!["contentType"] as! String == "tp" {
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    // Set iconicPreview's icon
                    cell.iconicPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                // Complete this
                if object!["contentType"] as! String == "sh" {
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "SharedPostIcon")
                }
                
                // (D) VIDEO
                if object!["contentType"] as! String == "vi" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "VideoIcon")
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
        })
        

        return cell
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        // Save to Views
        let view = PFObject(className: "Views")
        view["byUser"] = PFUser.current()!
        view["username"] = PFUser.current()!.username!
        view["forObjectId"] = self.followingContent[indexPath.row].objectId!
        view.saveInBackground {
            (success: Bool, error: Error?) in
            if success {
                // TEXT POST
                if self.followingContent[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                    // Append Object
                    textPostObject.append(self.followingContent[indexPath.row])
                    
                    
                    // Present VC
                    let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                    self.parentNavigator.pushViewController(textPostVC, animated: true)
                    
                }
                
                
                
                
                // PHOTO
                if self.followingContent[indexPath.row].value(forKey: "contentType") as! String == "ph" {
                    // Append Object
                    photoAssetObject.append(self.followingContent[indexPath.row])
                    
                    // Present VC
                    let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                    self.parentNavigator.pushViewController(photoVC, animated: true)
                }
                
                // SHARED
                if self.followingContent[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                    // Append object
                    sharedObject.append(self.followingContent[indexPath.row])
                    // Push VC
                    let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                    self.parentNavigator.pushViewController(sharedPostVC, animated: true)
                    
                }

                
                // VIDEO
                if self.followingContent[indexPath.row].value(forKey: "contentType") as! String == "vi" {
                    // Append content object
                    videoObject.append(self.followingContent[indexPath.row])
                    
                    // Push VC
                    let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                    self.parentNavigator.pushViewController(videoVC, animated: true)
                }

            } else {
                print(error?.localizedDescription as Any)
            }
        } // end saving to views
        

    } // end didSelect delegate
    

    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= followingContent.count + self.skipped.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryFollowing()
        }
    }

}
