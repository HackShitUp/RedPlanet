//
//  Friends.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet




// Define identifier
let friendsNewsfeed = Notification.Name("friendsNewsfeed")


class Friends: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, CAPSPageMenuDelegate {
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Reload data
        self.queryFriends()
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
            NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
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
        
        // LayoutViews for mediaPreview
        cell.mediaPreview.layoutIfNeeded()
        cell.mediaPreview.layoutSubviews()
        cell.mediaPreview.setNeedsLayout()

        // Set aspectFill by default
        cell.mediaPreview.contentMode = .scaleAspectFill
        

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
                    
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = 10.00
                    cell.mediaPreview.clipsToBounds = true
                    
                    // Fetch photo
                    if let photo = object!["photoAsset"] as? PFFile {
                        photo.getDataInBackground(block: {
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
                    cell.mediaPreview.layer.cornerRadius = 10.00
                    cell.mediaPreview.clipsToBounds = true
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    // Set mediaPreview's icon
                    cell.mediaPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                // (C) SHARED
                if object!["contentType"] as! String == "sh" {
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = 10.00
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
                if object!["contentType"] as! String == "itm" {

                    // Add blur -- this doesn't work because cell issues
//                    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
//                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
//                    blurEffectView.frame = cell.mediaPreview.frame
//                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                    cell.mediaPreview.addSubview(blurEffectView)
                    
                    
                    
                    // SHADOW?
                    // :/
//                    cell.mediaPreview.layer.shadowOffset = CGSize(width: cell.mediaPreview.frame.size.width, height: cell.mediaPreview.frame.size.height)
//                    cell.mediaPreview.layer.shadowOpacity = 0.7
//                    cell.mediaPreview.layer.shadowRadius = 2.00
                    
                    // None of the above methods work :(
                    
                    // Make mediaPreview cornerd Squared and blur image
                    cell.mediaPreview.layer.cornerRadius = 0
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    cell.mediaPreview.contentMode = .scaleAspectFit
                    cell.mediaPreview.clipsToBounds = true

                    
                    // Fetch photo
                    if let itm = object!["photoAsset"] as? PFFile {
                        itm.getDataInBackground(block: {
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
                
                
                
                // (F) Space Post
                if object!["contentType"] as! String == "sp" {
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = cell.mediaPreview.frame.size.width/2
                    cell.mediaPreview.clipsToBounds = true
                    
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    
                    // Set background color for mediaPreview
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.mediaPreview.image = UIImage(named: "SpacePost")
                }

                
                // (G) Video
                if object!["contentType"] as! String == "vi" {
                    // Make mediaPreview cornered square
                    cell.mediaPreview.layer.cornerRadius = cell.mediaPreview.frame.size.width/2
                    cell.mediaPreview.clipsToBounds = true
                    
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    
                    // Set background color for mediaPreview
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.mediaPreview.image = UIImage(named: "igcVideo")
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
    
    
    // define these as class properties:
    var player:AVPlayer!
    var playerLayer:AVPlayerLayer!
    
    func setupVideoPlayerWithURL(url:NSURL) {
        
        player = AVPlayer(url: url as URL)
        playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.frame = self.view.frame   // take up entire screen
        self.view.layer.addSublayer(self.playerLayer)
        player.play()
        
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
            if error == nil {
                
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
                    if let video = self.friendsContent[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                        
                        /*
                         //                let videoData = URL(string: video.url!)
                         //                let videoViewController = VideoViewController(videoURL: videoData!)
                         //                self.parentNavigator.pushViewController(videoViewController, animated: true)
                         /*
                         let filemanager = NSFileManager.defaultManager()
                         
                         let documentsPath : AnyObject = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0]
                         let destinationPath:NSString = documentsPath.stringByAppendingString("/file.mov")
                         movieData!.writeToFile ( destinationPath as String, atomically:true)
                         
                         
                         let playerItem = AVPlayerItem(asset: AVAsset(URL: NSURL(fileURLWithPath: destinationPath as String)))
                         let player = AVPlayer(playerItem: playerItem)
                         playerController.player = player
                         player.play()
                         */
                         
                         
                         
                         print("fired vi")
                         print("VIDEO URL: \(video.url)")
                         
                         //                let videoUrl = NSURL(string: video.url!)
                         //                // Create player
                         //                let playerController = AVPlayerViewController()
                         //                let avPlayer = AVPlayer(url: videoUrl as! URL)
                         //                playerController.player = avPlayer
                         //                self.present(playerController, animated: true, completion: {() -> Void in
                         //                    playerController.player?.play()
                         //                })
                         
                         video.getDataInBackground(block: {
                         (data: Data?, error: Error?) in
                         if error == nil {
                         
                         let filemanager = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                         let destinationPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                         //                        data!.write(toFile: destinationPath as! String, atomic: true)
                         data!.write(to: URL(string: video.url!)!, options: .atomic)
                         let playerItem = AVPlayerItem(asset: AVAsset(url: NSURL(fileURLWithPath: destinationPath as! String) as URL))
                         let player = AVPlayer(playerItem: playerItem)
                         
                         
                         
                         
                         
                         } else {
                         print(error?.localizedDescription as Any)
                         }
                         })
                         */
                        
                    }
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        

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
