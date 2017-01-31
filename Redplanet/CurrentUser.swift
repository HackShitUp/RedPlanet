//
//  CurrentUser.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SDWebImage
import SimpleAlert

// Define identifier
let myProfileNotification = Notification.Name("myProfile")

class CurrentUser: UITableViewController, UITabBarControllerDelegate, UINavigationControllerDelegate {
    
    // Variable to hold my content
    var myContentObjects = [PFObject]()
    
    // Set ephemeral types
    let ephemeralTypes = ["itm", "sp", "sh"]
    
    // Fetch likes, count comments and shares
    var likes = [PFObject]()
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Set pipeline method
    var page: Int = 50
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!

    @IBAction func findFriends(_ sender: Any) {
        // If iOS 9
        if #available(iOS 9, *) {
            // Push VC
            let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
            self.navigationController?.pushViewController(contactsVC, animated: true)
        } else {
            // Fallback on earlier versions
            // Show search
            let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
            self.navigationController!.pushViewController(search, animated: true)
        }
    }
    
    // Function to fetch my content
    func fetchMine() {
        // User's Posts
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: PFUser.current()!)
        // User's Space Posts
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: PFUser.current()!)
        // Both
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.limit = self.page
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.myContentObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time configs
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if object.value(forKey: "contentType") as! String == "itm" || object.value(forKey: "contentType") as! String == "sh" {
                        if difference.hour! < 24 {
                            self.myContentObjects.append(object)
                        } else {
                            self.skipped.append(object)
                        }
                    } else {
                        self.myContentObjects.append(object)
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView?.reloadData()
        }
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = PFUser.current()!.username!.uppercased()
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.delegate = self
    }
    
    // Refresh function
    func refresh() {
        // fetch data
        fetchMine()
        
        // End refresher
        self.refresher.endRefreshing()
    }
    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize and set title
        configureView()
        
        // Fetch current user's content
        fetchMine()
        
        // Configure table view
        self.tableView?.backgroundColor = UIColor.white
        self.tableView?.estimatedRowHeight = 658
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView?.tableFooterView = UIView()
        
        // Add refresher
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.tableView?.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: myProfileNotification, object: nil)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        let nib = UINib(nibName: "CurrentUserHeader", bundle: nil)
        tableView?.register(nib, forHeaderFooterViewReuseIdentifier: "CurrentUserHeader")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // MARK: - UITableViewHeader Section View
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // created a constant that stores a registered header
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CurrentUserHeader") as! CurrentUserHeader

        // Declare delegate
        header.delegate = self
        
        //set contentView frame and autoresizingMask
        header.frame = header.frame
        
        // Query relationships
        appDelegate.queryRelationships()
        
        // Layout subviews
        header.myProPic.layoutSubviews()
        header.myProPic.layoutIfNeeded()
        header.myProPic.setNeedsLayout()
        
        // Make profile photo circular
        header.myProPic.layer.cornerRadius = header.myProPic.frame.size.width/2.0
        header.myProPic.layer.borderColor = UIColor.lightGray.cgColor
        header.myProPic.layer.borderWidth = 0.5
        header.myProPic.clipsToBounds = true
        
        // (1) Get User's Object
        if let myProfilePhoto = PFUser.current()!["userProfilePicture"] as? PFFile {
            myProfilePhoto.getDataInBackground(block: {
                (data: Data?, error: Error?) in
                if error == nil {
                    // (A) Set profile photo
                    header.myProPic.image = UIImage(data: data!)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // (B) Set default
                    header.myProPic.image = UIImage(named: "Gender Neutral User-100")
                }
            })
        }
        
        
        // (2) Set user's bio and information
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!["userBiography"] as! String)"
        } else {
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)"
        }
        
        // (3) Set count for friends, followers, and following
        if myFriends.count == 0 {
            header.numberOfFriends.setTitle("\nfriends", for: .normal)
        } else if myFriends.count == 1 {
            header.numberOfFriends.setTitle("1\nfriend", for: .normal)
        } else {
            header.numberOfFriends.setTitle("\(myFriends.count)\nfriends", for: .normal)
        }
        
        
        if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("\nfollowers", for: .normal)
        } else if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("1\nfollower", for: .normal)
        } else {
            header.numberOfFollowers.setTitle("\(myFollowers.count)\nfollowers", for: .normal)
        }
        
        
        if myFollowing.count == 0 {
            header.numberOfFollowing.setTitle("\nfollowing", for: .normal)
        } else if myFollowing.count == 1 {
            header.numberOfFollowing.setTitle("1\nfollowing", for: .normal)
        } else {
            header.numberOfFollowing.setTitle("\(myFollowing.count)\nfollowing", for: .normal)
        }
        
        
        return header
        
    }
    
    
    // header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 304, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            // Set fullname
            let fullName = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            
            label.text = "\(fullName.uppercased())\n\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            label.text = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)"
        }
        
        label.sizeToFit()
        
        return CGFloat(375 + label.frame.size.height)
    }
    
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.myContentObjects.count
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.ephemeralTypes.contains(self.myContentObjects[indexPath.row].value(forKeyPath: "contentType") as! String) {
            return 65
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Intialize UITableViewCells
        let eCell = Bundle.main.loadNibNamed("EphemeralCell", owner: self, options: nil)?.first as! EphemeralCell
        let tpCell = Bundle.main.loadNibNamed("TimeTextPostCell", owner: self, options: nil)?.first as! TimeTextPostCell
        let mCell = Bundle.main.loadNibNamed("TimeMediaCell", owner: self, options: nil)?.first as! TimeMediaCell
        
        // Declare delegates
        eCell.delegate = self.navigationController
        tpCell.delegate = self.navigationController
        mCell.delegate = self.navigationController
        
        // Initialize all level configurations: rpUserProPic && rpUsername
        let proPics = [eCell.rpUserProPic, tpCell.rpUserProPic, mCell.rpUserProPic]
        let usernames = [eCell.rpUsername, tpCell.rpUsername, mCell.rpUsername]
        
        // Initialize text for time
        var rpTime: String?
        
        // (I) Fetch user's data and unload them
        self.myContentObjects[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if let user = object!["byUser"] as? PFUser {
                    // (A) User's Full Name
                    for u in usernames {
                        u?.text! = user["realNameOfUser"] as! String
                    }
                    
                    // (B) Profile Photo
                    for p in proPics {
                        // LayoutViews for rpUserProPic
                        p?.layoutIfNeeded()
                        p?.layoutSubviews()
                        p?.setNeedsLayout()
                        // Make Profile Photo Circular
                        p?.layer.cornerRadius = (p?.frame.size.width)!/2
                        p?.layer.borderColor = UIColor.lightGray.cgColor
                        p?.layer.borderWidth = 0.5
                        p?.clipsToBounds = true
                        // Fetch profile photo
                        if let proPic = user["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    p?.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                    p?.image = UIImage(named: "Gender Neutral User-100")
                                }
                            })
                            
                            // MARK: - SDWebImage
                            p?.sd_setImage(with: URL(string: proPic.url!), placeholderImage: p?.image)
                        }
                    }
                    
                    // SET user's objects
                    eCell.userObject = user
                    tpCell.userObject = user
                    mCell.userObject = user
                } // end fetching PFUser object
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // (II) Configure time for Photos, Profile Photos, Text Posts, and Videos
        let from = self.myContentObjects[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference.second! <= 0 {
            rpTime = "now"
        } else if difference.second! > 0 && difference.minute! == 0 {
            if difference.second! == 1 {
                rpTime = "1 second ago"
            } else {
                rpTime = "\(difference.second!) seconds ago"
            }
        } else if difference.minute! > 0 && difference.hour! == 0 {
            if difference.minute! == 1 {
                rpTime = "1 minute ago"
            } else {
                rpTime = "\(difference.minute!) minutes ago"
            }
        } else if difference.hour! > 0 && difference.day! == 0 {
            if difference.hour! == 1 {
                rpTime = "1 hour ago"
            } else {
                rpTime = "\(difference.hour!) hours ago"
            }
        } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
            if difference.day! == 1 {
                rpTime = "1 day ago"
            } else {
                rpTime = "\(difference.day!) days ago"
            }
        } else if difference.weekOfMonth! > 0 {
            let createdDate = DateFormatter()
            createdDate.dateFormat = "MMM d, yyyy"
            rpTime = createdDate.string(from: self.myContentObjects[indexPath.row].createdAt!)
        }
        
        // (II) Layout content
        if self.ephemeralTypes.contains(self.myContentObjects[indexPath.row].value(forKeyPath: "contentType") as! String) {
            // ****************************************************************************************************************
            // MOMENTS, SPACE POSTS, SHARED POSTS *****************************************************************************
            // ****************************************************************************************************************
            
            // High level configurations
            // Configure IconicPreview by laying out views
            eCell.iconicPreview.layoutIfNeeded()
            eCell.iconicPreview.layoutSubviews()
            eCell.iconicPreview.setNeedsLayout()
            eCell.iconicPreview.layer.cornerRadius = eCell.iconicPreview.frame.size.width/2
            eCell.iconicPreview.layer.borderColor = UIColor.clear.cgColor
            eCell.iconicPreview.layer.borderWidth = 0.00
            eCell.iconicPreview.contentMode = .scaleAspectFill
            eCell.iconicPreview.clipsToBounds = true
            
            // (1) Set contentObject and user's object
            eCell.postObject = self.myContentObjects[indexPath.row]
            
            // (2) Configure time
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            eCell.time.text! = "\(timeFormatter.string(from: self.myContentObjects[indexPath.row].createdAt!))"
            
            // (3) Layout content
            // (3A) MOMENT
            if self.myContentObjects[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                
                // Make iconicPreview circular with red border color
                eCell.iconicPreview.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                eCell.iconicPreview.layer.borderWidth = 3.50
                
                if let still = self.myContentObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // STILL PHOTO
                    still.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            eCell.iconicPreview.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                } else if let videoFile = self.myContentObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // VIDEO
                    let videoUrl = NSURL(string: videoFile.url!)
                    do {
                        let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        eCell.iconicPreview.image = UIImage(cgImage: cgImage)
                        
                        // MARK: - SDWebImage
                        eCell.iconicPreview.sd_setImage(with: URL(string: videoFile.url!), placeholderImage: UIImage(cgImage: cgImage))
                        
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
                }
                
                // (3B) SPACE POST
            } else if self.myContentObjects[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "CSpacePost")
                
                // (3C) SHARED POSTS
            } else if self.myContentObjects[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                eCell.iconicPreview.backgroundColor = UIColor.clear
                eCell.iconicPreview.image = UIImage(named: "SharedPostIcon")
            }
            
            return eCell // return EphemeralCell.swift
            
        } else if myContentObjects[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            // ****************************************************************************************************************
            // TEXT POST ******************************************************************************************************
            // ****************************************************************************************************************
            // (1) Set Text Post
            tpCell.textPost.text! = self.myContentObjects[indexPath.row].value(forKey: "textPost") as! String
            
            // (2) Set time
            tpCell.time.text! = rpTime!
            
            // (3) Set post object
            tpCell.postObject = self.myContentObjects[indexPath.row]
            
            // (4) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.myContentObjects[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        tpCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        tpCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        tpCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        tpCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        tpCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.myContentObjects[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        tpCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        tpCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        tpCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.myContentObjects[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        tpCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        tpCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        tpCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            return tpCell   // return TimeTextPostCell.swift
            
        } else {
            // ****************************************************************************************************************
            // PHOTOS, PROFILE PHOTOS, VIDEOS *********************************************************************************
            // ****************************************************************************************************************
            // (1) Set post object
            mCell.postObject = self.myContentObjects[indexPath.row]
            
            // (2) Fetch Photo or Video
            // PHOTO
            
            if let photo = self.myContentObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        mCell.mediaAsset.contentMode = .scaleAspectFit
                        mCell.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                // MARK: - SDWebImage
                let fileURL = URL(string: photo.url!)
                mCell.mediaAsset.sd_setImage(with: fileURL, placeholderImage: nil)
                
            } else if let videoFile = self.myContentObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // VIDEO
                
                // LayoutViews
                mCell.mediaAsset.layoutIfNeeded()
                mCell.mediaAsset.layoutSubviews()
                mCell.mediaAsset.setNeedsLayout()
                
                // Make Vide Preview Circular
                mCell.mediaAsset.layer.cornerRadius = mCell.mediaAsset.frame.size.width/2
                mCell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                mCell.mediaAsset.layer.borderWidth = 3.50
                mCell.mediaAsset.clipsToBounds = true
                
                let videoUrl = NSURL(string: videoFile.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    mCell.mediaAsset.contentMode = .scaleAspectFill
                    mCell.mediaAsset.image = UIImage(cgImage: cgImage)
                    
                    // MARK: - SDWebImage
                    mCell.mediaAsset.sd_setImage(with: URL(string: videoFile.url!), placeholderImage: UIImage(cgImage: cgImage))
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // (2) Handle caption (text post) if it exists
            if let caption = self.myContentObjects[indexPath.row].value(forKey: "textPost") as? String {
                mCell.textPost.text! = caption
            } else {
                mCell.textPost.isHidden = true
            }
            
            // (3) Set time
            mCell.time.text! = rpTime!
            
            // (4) Fetch likes, comments, and shares
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: self.myContentObjects[indexPath.row].objectId!)
            likes.includeKey("fromUser")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.likes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.likes.append(object.object(forKey: "fromUser") as! PFUser)
                    }
                    
                    if self.likes.count == 0 {
                        mCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        mCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        mCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                        mCell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        mCell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let comments = PFQuery(className: "Comments")
            comments.whereKey("forObjectId", equalTo: self.myContentObjects[indexPath.row].objectId!)
            comments.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        mCell.numberOfComments.setTitle("comments", for: .normal)
                    } else if count == 1 {
                        mCell.numberOfComments.setTitle("1 comment", for: .normal)
                    } else {
                        mCell.numberOfComments.setTitle("\(count) comments", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            let shares = PFQuery(className: "Newsfeeds")
            shares.whereKey("contentType", equalTo: "sh")
            shares.whereKey("pointObject", equalTo: self.myContentObjects[indexPath.row])
            shares.countObjectsInBackground(block: {
                (count: Int32, error: Error?) in
                if error == nil {
                    if count == 0 {
                        mCell.numberOfShares.setTitle("shares", for: .normal)
                    } else if count == 1 {
                        mCell.numberOfShares.setTitle("1 share", for: .normal)
                    } else {
                        mCell.numberOfShares.setTitle("\(count) shares", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            // (5) Add tap methods
            mCell.layoutTap()
            
            return mCell // return TimeMediaCell
        }
    } // end cellForRowAt
    
    
    // MARK: - UIScrollViewDelegate method
    // MARK: - RP Pipeline method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.myContentObjects.count + self.skipped.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query content
            fetchMine()
        }
    }
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            self.refresher.endRefreshing()
        }
    }
    
}
