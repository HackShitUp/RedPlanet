//
//  HashTags.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/13/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import OneSignal
import SDWebImage

// Array to hold hashtag objects
var hashtags = [String]()


// Define Notification
let hashtagNotification = Notification.Name("hashTag")

class HashTags: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UINavigationControllerDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    
    // Array to hold public users
    var okUsers = [PFObject]()
    
    // Array to hold objects
    var hashtagStrings = [String]()
    var hashtagObjects = [PFObject]()
    var skipped = [PFObject]()
    
    // Array to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Array to determine content types
    let contentTypes = ["tp", "ph", "vi"]
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch hashtags
        fetchHashtags()
        
        // Reload Data
        self.tableView!.reloadData()
    }
    
    // Function to fetch hashtags
    func fetchHashtags() {
        // Fetch users
        _ = appDelegate.queryRelationships()
        
        // Check which users are public
        let publicUsers = PFUser.query()!
        publicUsers.whereKey("private", equalTo: false)
        publicUsers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.okUsers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId!}) {
                        self.okUsers.append(object)
                    }
                }
                
                // Fetch in News Feeds
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.includeKey("byUser")
                newsfeeds.whereKey("byUser", containedIn: self.okUsers)
                newsfeeds.whereKey("objectId", containedIn: self.hashtagStrings)
                newsfeeds.whereKey("contentType", containedIn: self.contentTypes)
                newsfeeds.order(byDescending: "createdAt")
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.hashtagObjects.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            // Ephemeral content
                            let components : NSCalendar.Unit = .hour
                            let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                            if difference.hour! < 24 {
                                self.hashtagObjects.append(object)
                            } else {
                                self.skipped.append(object)
                            }
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
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "#\(hashtags.last!)"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title
        configureView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Get hashtags
        let queryHashtag = PFQuery(className: "Hashtags")
        queryHashtag.whereKey("hashtag", equalTo: hashtags.last!)
        queryHashtag.order(byDescending: "createdAt")
        queryHashtag.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.hashtagStrings.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.hashtagStrings.append(object["forObjectId"] as! String)
                }
                // DZNEmptyDataSet
                if self.hashtagObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                // Fetch hashtags
                self.fetchHashtags()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
        
        // Stylize title
        configureView()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 515
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Rid of lines in tableview
        self.tableView.tableFooterView = UIView()
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Add observer
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: hashtagNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if hashtagObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "＃\nUh Oh\n No Hashtags to show..."
        let font = UIFont(name: "AvenirNext-Medium", size: 21.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.hashtagObjects.count
    }

    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 515
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hashtagsCell", for: indexPath) as! HashTagsCell

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // LayoutViews
        cell.textPost.layoutIfNeeded()
        cell.textPost.layoutSubviews()
        cell.textPost.setNeedsLayout()
        
        // Layout views
        cell.photoAsset.layoutIfNeeded()
        cell.photoAsset.layoutSubviews()
        cell.photoAsset.setNeedsLayout()
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.contentView.frame
        
        // Instantiate parent vc
        cell.delegate = self

        // Set content's object
        cell.contentObject = hashtagObjects[indexPath.row]
        
        // By default, design IBOutlets
        cell.photoAsset.contentMode = .scaleAspectFit
        cell.photoAsset.layer.cornerRadius = 0.0
        cell.photoAsset.layer.borderColor = UIColor.clear.cgColor
        cell.photoAsset.layer.borderWidth = 0.0
        cell.photoAsset.clipsToBounds = true
        
        // (1) Fetch user
        if let user = hashtagObjects[indexPath.row].value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.rpUsername.text! = user["username"] as! String
            
            // (B) Get user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (C) Set fromUser's object
            cell.userObject = user
        }
        
        
        // (2) set time
        let from = hashtagObjects[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (3) Set Content
        // (A) TEXT POST
        if hashtagObjects[indexPath.row].value(forKey:"contentType") as! String == "tp" {
            
            // Hide Photo
            cell.photoAsset.isHidden = true
            cell.textPost.isHidden = false
            
            // Text post
            cell.textPost.text! = hashtagObjects[indexPath.row].value(forKey: "textPost") as! String
        }
        
        // (B) PHOTO
        if hashtagObjects[indexPath.row].value(forKey:"contentType") as! String == "ph" {
            
            cell.photoAsset.isHidden = false
            cell.textPost.isHidden = true
            
            // Set content mode
            cell.photoAsset.contentMode = .scaleAspectFit
            
            // (B1) Fetch photo
            if let photo = hashtagObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                cell.photoAsset.sd_setImage(with: URL(string: photo.url!), placeholderImage: cell.photoAsset.image)
            }
            
            // (B2) Check for textPost
            if hashtagObjects[indexPath.row].value(forKey: "textPost") != nil {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(hashtagObjects[indexPath.row].value(forKey: "textPost") as! String)"
            } else {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            }
            
        }

        // (C) VIDEO
        if hashtagObjects[indexPath.row].value(forKey: "contentType") as! String == "vi" {
            // Show thumbnail
            cell.photoAsset.isHidden = false
            // Hide text post
            cell.textPost.isHidden = true
            
            // Set content mode
            cell.photoAsset.contentMode = .scaleAspectFill

            // Make Vide Preview Circular
            cell.photoAsset.layer.cornerRadius = cell.photoAsset.frame.size.width/2
            cell.photoAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            cell.photoAsset.layer.borderWidth = 3.50
            cell.photoAsset.clipsToBounds = true
            
            // (C1) Get video preview
            if let videoFile = hashtagObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = cell.photoAsset.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                cell.photoAsset.contentMode = .scaleAspectFit
                cell.photoAsset.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            
            
            // (C2) Check for textPost
            if hashtagObjects[indexPath.row].value(forKey: "textPost") != nil {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(hashtagObjects[indexPath.row].value(forKey: "textPost") as! String)"
            } else {
                // Add lines for sizing constraints
                cell.textPost.isHidden = false
                cell.textPost.text! = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            }
            
            
        }
        
        
        
        // (4) Call cell's awakeFromNib
        cell.awakeFromNib()
        
        
        // (5) Set count title for likes
        // (A)
        let likes = PFQuery(className: "Likes")
        likes.includeKey("fromUser")
        likes.whereKey("forObjectId", equalTo: self.hashtagObjects[indexPath.row].objectId!)
        likes.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object["fromUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Check whether user has liked it or not
            if self.likes.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                // unlike
                cell.likeButton.setTitle("liked", for: .normal)
                cell.likeButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
            } else {
                // like
                cell.likeButton.setTitle("notliked", for: .normal)
                cell.likeButton.setTitle("Like", for: .normal)
            }
            
            // Set number of likes
            if self.likes.count == 0 {
                cell.numberOfLikes.setTitle("likes", for: .normal)
            } else if self.likes.count == 1 {
                cell.numberOfLikes.setTitle("1 like", for: .normal)
            } else {
                cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
            }
            
        })
        // (B) Comments
        let comments = PFQuery(className: "Comments")
        comments.includeKey("byUser")
        comments.whereKey("forObjectId", equalTo: self.hashtagObjects[indexPath.row].objectId!)
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.comments.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.comments.append(object["byUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Set number of comments
            if self.comments.count == 0 {
                cell.numberOfComments.setTitle("comments", for: .normal)
            } else if self.comments.count == 1 {
                cell.numberOfComments.setTitle("1 comment", for: .normal)
            } else {
                cell.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
            }
        })
        // (C) Shares
        let shares = PFQuery(className: "Newsfeeds")
        shares.includeKey("byUser")
        shares.whereKey("pointObject", equalTo: self.hashtagObjects[indexPath.row])
        shares.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.shares.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.shares.append(object["byUser"] as! PFUser)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Set number of shares
            if self.shares.count == 0 {
                cell.numberOfShares.setTitle("shares", for: .normal)
            } else if self.shares.count == 1 {
                cell.numberOfShares.setTitle("1 share", for: .normal)
            } else {
                cell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
            }
        })
        

        return cell
    }// end cellForRowAt method
     */
}
