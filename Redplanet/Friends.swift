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
let friendsNewsfeed = Notification.Name("friendsNewsfeed")


class Friends: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, CAPSPageMenuDelegate {
    
    let friendsType = ["tp",
                      "ph",
                      "pp",
                      "sh",
                      "sp",
                      "itm",
                      "vi"]
    
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
                newsfeeds.whereKey("contentType", containedIn: self.friendsType)
                newsfeeds.whereKey("byUser", containedIn: self.friends)
                newsfeeds.includeKey("byUser")
                newsfeeds.includeKey("pointObject")
                newsfeeds.order(byDescending: "createdAt")
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
                        
                        
                        // Set DZN
                        if self.friendsContent.count == 0 {
                            self.tableView!.emptyDataSetSource = self
                            self.tableView!.emptyDataSetDelegate = self
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
        SVProgressHUD.setBackgroundColor(UIColor.white)

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
    
    
    
    

    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if friendsContent.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nYour Friends' News Feed is empty."
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Redplanet is more fun with your friends."
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
        let str = "Find My Friends"
        let font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // If iOS 9
        if #available(iOS 9, *) {
            // Push VC
            let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
            self.parentNavigator.pushViewController(contactsVC, animated: true)
        } else {
            // Fallback on earlier versions
            // Show search
            let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
            self.parentNavigator.pushViewController(search, animated: true)
        }
    }
    
    
    
    
    

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
        
        // LayoutViews for iconicPreview
        cell.iconicPreview.layoutIfNeeded()
        cell.iconicPreview.layoutSubviews()
        cell.iconicPreview.setNeedsLayout()

        // Set aspectFill by default
        cell.iconicPreview.contentMode = .scaleAspectFill
        

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
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    
                    // (C) Set user's object
                    cell.userObject = user
                }
                

                
                
                // *************************************************************************************************************************
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "ph" {
                    
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Fetch photo
                    if let photo = object!["photoAsset"] as? PFFile {
                        photo.getDataInBackground(block: {
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
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    // Set iconicPreview's icon
                    cell.iconicPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                if object!["contentType"] as! String == "sh" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = 12.00
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "SharedPostIcon")
                }
                
                

                

                // (D) Profile Photo
                if object!["contentType"] as! String == "pp" {
                    
                    // Make iconicPreview circular
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.layer.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    
                    // Fetch Profile photo
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
                
                
                
                // (E) In the moment
                if object!["contentType"] as! String == "itm" {

                    // Add blur -- this doesn't work because cell issues
//                    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
//                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
//                    blurEffectView.frame = cell.iconicPreview.frame
//                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                    cell.iconicPreview.addSubview(blurEffectView)
                    
                    
                    
                    // SHADOW?
                    // :/
//                    cell.iconicPreview.layer.shadowOffset = CGSize(width: cell.iconicPreview.frame.size.width, height: cell.iconicPreview.frame.size.height)
//                    cell.iconicPreview.layer.shadowOpacity = 0.7
//                    cell.iconicPreview.layer.shadowRadius = 2.00
                    
                    // None of the above methods work :(
                    
                    // Make iconicPreview cornerd Squared and blur image
                    cell.iconicPreview.layer.cornerRadius = 0
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    cell.iconicPreview.contentMode = .scaleAspectFit
                    cell.iconicPreview.clipsToBounds = true

                    
                    // Fetch photo
                    if let itm = object!["photoAsset"] as? PFFile {
                        itm.getDataInBackground(block: {
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
                
                
                
                // (F) Space Post
                if object!["contentType"] as! String == "sp" {
                    // Make iconicPreview cornered square
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "SpacePost")
                }

                
                // (G) Video
                if object!["contentType"] as! String == "vi" {
                    // Make iconicPreview circular
                    cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                    cell.iconicPreview.clipsToBounds = true
                    
                    // Show iconicPreview
                    cell.iconicPreview.isHidden = false
                    
                    // Set background color for iconicPreview
                    cell.iconicPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.iconicPreview.image = UIImage(named: "VideoIcon")
                }
                
                // *************************************************************************************************************************
                
                
                
                
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
                // USE FOR LATER WHEN CONTENT IS DELETED EVERY 24 HOURS
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
        
        // Save to Views
        let view = PFObject(className: "Views")
        view["byUser"] = PFUser.current()!
        view["username"] = PFUser.current()!.username!
        view["forObjectId"] = friendsContent[indexPath.row].objectId!
        view.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if success {
                
                // TEXT POST
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                    
                    // Append Object
                    textPostObject.append(self.friendsContent[indexPath.row])
                    
                    // Present VC
                    let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                    self.parentNavigator.pushViewController(textPostVC, animated: true)
                }
                
                // PHOTO
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "ph" {
                    
                    // Append Object
                    photoAssetObject.append(self.friendsContent[indexPath.row])
                    
                    // Present VC
                    let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                    self.parentNavigator.pushViewController(photoVC, animated: true)
                }
                
                // SHARED
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                    
                    // Append object
                    sharedObject.append(self.friendsContent[indexPath.row])
                    
                    // Push VC
                    let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                    self.parentNavigator.pushViewController(sharedPostVC, animated: true)
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
                
                
                // SPACE POST
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                    // Append object
                    spaceObject.append(self.friendsContent[indexPath.row])
                    
                    // Append otherObject
                    otherObject.append(self.friendsContent[indexPath.row].value(forKey: "toUser") as! PFUser)
                    
                    // Append otherName
                    otherName.append(self.friendsContent[indexPath.row].value(forKey: "toUsername") as! String)
                    
                    // Push VC
                    let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                    self.parentNavigator.pushViewController(spacePostVC, animated: true)
                }
                
                // ITM
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                    // Append content object
                    itmObject.append(self.friendsContent[indexPath.row])
                    
                    // Push VC
                    let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                    self.parentNavigator.pushViewController(itmVC, animated: true)
                }
                
                // VIDEO
                if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "vi" {
                    // Append content object
                    videoObject.append(self.friendsContent[indexPath.row])
                    
                    // Push VC
                    let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                    self.parentNavigator.pushViewController(videoVC, animated: true)
                }

                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
 
 

        // Append the correct VC along with the correct object
//        timelineObjects.removeAll(keepingCapacity: false)
//        returnIndex = indexPath.row
//        timelineObjects.append(self.friendsContent[indexPath.row])
//        timelineObjects.append(contentsOf: self.friendsContent)
//        let timelineVC = self.storyboard?.instantiateViewController(withIdentifier: "timelineVC") as! Timeline
//        self.parentNavigator.pushViewController(timelineVC, animated: true)

    } // end didSelectRowAt
    
    
    
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
