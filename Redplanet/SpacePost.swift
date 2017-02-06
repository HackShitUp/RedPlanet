//
//  SpacePost.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//


import AVFoundation
import AVKit
import CoreData
import MobileCoreServices
import Photos
import PhotosUI
import UIKit

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import OneSignal
import SimpleAlert


// Array to hold space post object
var spaceObject = [PFObject]()


// Define Notification
let spaceNotification = Notification.Name("spaceNotification")

class SpacePost: UITableViewController, UINavigationControllerDelegate {
    
    
    // Variable to determine string
    var layoutText: String?
    
    
    // Array to hold likers, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last object
        spaceObject.removeLast()
        
        // Pop VC
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch interactions
        fetchInteractions()
        
        // End refresher
        self.refresher.endRefreshing()

        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to fetch interactions
    func fetchInteractions() {
        // Fetch likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append objects
                    self.likes.append(object["fromUser"] as! PFUser)
                }
                
                
                // Fetch comments
                let comments = PFQuery(className: "Comments")
                comments.includeKey("byUser")
                comments.whereKey("forObjectId", equalTo: spaceObject.last!.objectId!)
                comments.order(byDescending: "createdAt")
                comments.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.comments.removeAll(keepingCapacity: false)
                        
                        // Append objects
                        for object in objects! {
                            self.comments.append(object)
                        }
                        
                        
                        
                        // Fetch shares
                        let shares = PFQuery(className: "Newsfeeds")
                        shares.whereKey("contentType", equalTo: "sh")
                        shares.whereKey("pointObject", equalTo: spaceObject.last!)
                        shares.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                // Clear array
                                self.shares.removeAll(keepingCapacity: false)
                                
                                // Append objects
                                for object in objects! {
                                    self.shares.append(object)
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
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName:  UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "\(otherName.last!.uppercased())'s Space"
        }
        
        // Configure nav bar && hide tab bar (last line)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    
    
    // Function to go to owner's space 
    func goToUser() {
        if let userSpace = spaceObject.last!.value(forKey: "toUser") as? PFUser {
            // Append object
            otherObject.append(userSpace)
            
            // Append othername
            otherName.append(userSpace["username"] as! String)
            
            // Push VC
            let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherVC, animated: true)
        }
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Stylize navigation bar
        configureView()
        
        // Fetch interactions
        fetchInteractions()
        
        // Add method tap
        let goUserTap = UITapGestureRecognizer(target: self, action: #selector(goToUser))
        goUserTap.numberOfTapsRequired = 1
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        self.navigationController?.navigationBar.addGestureRecognizer(goUserTap)
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 505
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: spaceNotification, object: nil)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Stylize title
        configureView()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Function to calculate how many new lines UILabel should create before laying out the text
    func createText() -> String? {
        
        
        // Check for textPost & handle optional chaining
        if spaceObject.last!.value(forKey: "textPost") != nil {
            
            // (A) Set textPost
            // Calculate screen height
            if UIScreen.main.nativeBounds.height == 960 {
                // iPhone 4
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\(spaceObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 1136 {
                // iPhone 5 √
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(spaceObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 1334 {
                // iPhone 6 √
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(spaceObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                // iPhone 6+ √???
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(spaceObject.last!.value(forKey: "textPost") as! String)"
            }
            
        } else {
            // Caption DOES NOT exist
            
            // (A) Set textPost
            // Calculate screen height
            if UIScreen.main.nativeBounds.height == 960 {
                // iPhone 4
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 1136 {
                // iPhone 5
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 1334 {
                // iPhone 6
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                // iPhone 6+
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            }
        }
    
        return layoutText!
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

    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 505
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "spacePostCell", for: indexPath) as! SpacePostCell

        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // set parent vc
        cell.delegate = self
        
        // (1) Get byUser's data
        if let user = spaceObject.last!.value(forKey: "byUser") as? PFUser {
            // (A) Set username
            cell.rpUsername.text! = user["username"] as! String
            
            // (B) Get and set user's profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set pro pic
                        cell.rpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                    }
                })
            }
            
            // (C) Set byUser's object
            cell.byUserObject = user
        }
        
        
        // (2) Fetch toUser's data
        if let toUser = spaceObject.last!.value(forKey: "toUser") as? PFUser {
            // (A) Set toUser's Object
            cell.toUserObject = toUser
        }
        
        // (3) Fetch content
        if spaceObject.last!.value(forKey: "photoAsset") != nil {
            
            // ======================================================================================================================
            // PHOTO ================================================================================================================
            // ======================================================================================================================
            
            // (A) Configure image
            cell.mediaAsset.contentMode = .scaleAspectFit
            cell.mediaAsset.layer.cornerRadius = 0.0
            cell.mediaAsset.layer.borderColor = UIColor.clear.cgColor
            cell.mediaAsset.layer.borderWidth = 0.0
            cell.mediaAsset.clipsToBounds = true
            
            // (B) Fetch Photo
            if let photo = spaceObject.last!.value(forKey: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set photo
                        cell.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            // (C) Configure textPost
            // show mediaAsset
            cell.mediaAsset.isHidden = false
            // show textPost
            cell.textPost.isHidden = false
            // create text's height
            _ = createText()
            cell.textPost.text! = self.layoutText!
            
        } else if spaceObject.last!.value(forKey: "videoAsset") != nil {
            
            // ======================================================================================================================
            // VIDEO ================================================================================================================
            // ======================================================================================================================
            
            // (A) Configure video preview
            cell.mediaAsset.layer.cornerRadius = cell.mediaAsset.frame.size.width/2
            cell.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            cell.mediaAsset.layer.borderWidth = 3.50
            cell.mediaAsset.clipsToBounds = true
            
            
            // (B) Fetch Video Thumbnail
            if let video = spaceObject.last!.value(forKey: "videoAsset") as? PFFile {
                let videoUrl = NSURL(string: video.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    cell.mediaAsset.image = UIImage(cgImage: cgImage)
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // (C) Configure textPost
            // show mediaAsset
            cell.mediaAsset.isHidden = false
            // show textPost
            cell.textPost.isHidden = false
            // create text's height
            _ = createText()
            cell.textPost.text! = self.layoutText!
            
        } else {
            
            // ======================================================================================================================
            // TEXT POST ============================================================================================================
            // ======================================================================================================================
            
            // No Photo
            // hide mediaAsset
            cell.mediaAsset.isHidden = true
            // show textPost
            cell.textPost.isHidden = false
            
            // (A) Set textPost
            cell.textPost.text! = "\(spaceObject.last!.value(forKey: "textPost") as! String)"
        }
        
        
        // (4) Layout taps
        cell.layoutTaps()
        
        
        // (5) Set time
        let from = spaceObject.last!.createdAt!
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
            cell.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
        }
        
        
        
        
        // (6) Determine whether the current user has liked this object or not
        if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
            // Set button title
            cell.likeButton.setTitle("liked", for: .normal)
            // Set/ button image
            cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
        } else {
            // Set button title
            cell.likeButton.setTitle("notLiked", for: .normal)
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
        
        // Set number of shares
        if self.shares.count == 0 {
            cell.numberOfShares.setTitle("shares", for: .normal)
        } else if self.shares.count == 1 {
            cell.numberOfShares.setTitle("1 share", for: .normal)
        } else {
            cell.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
        }

        
        
        
        return cell
    } // end cellForRowAt


}
