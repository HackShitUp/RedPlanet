//
//  OtherUserProfile.swift
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



// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()


class OtherUserProfile: UICollectionViewController, UINavigationControllerDelegate {
    
    // Query Relationships
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    

    // Other User's Friends
    var oFriends = [PFObject]()
    
    // Other User's Followers
    var oFollowers = [PFObject]()
    
    // Other User's Following
    var oFollowing = [PFObject]()
    
    
    

    // Array to hold other user's content
    var contentObjects = [PFObject]()

    
    // Array to hold other user's space posts
    var spaceObjects = [PFObject]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Remove last values in arrays
        otherObject.removeLast()
        // Remove last value in array
        otherName.removeLast()
        
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func moreButton(_ sender: AnyObject) {
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        // (1) Write in space
        let space = UIAlertAction(title: "Write in Space 🚀",
                                  style: .default,
                                  handler: {(alertAction: UIAlertAction!) in
                                    // TODO::
        })
        
        // (2) Chat
        let chat = UIAlertAction(title: "Chat 💬",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    
                                    // Append user's object
                                    chatUserObject.append(otherObject.last!)
                                    // Append user's username
                                    chatUsername.append(otherName.last!)
                                    
                                    // Push VC
                                    let chatRoomVC = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
                                    self.navigationController?.pushViewController(chatRoomVC, animated: true)
                                    
        })
        
        // (3) Best Friends
        let bestFriends = UIAlertAction(title: "Best Friends 👫",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    // TODO::
                                    
        })
        
        // (3) Mutual
        let mutual = UIAlertAction(title: "Mutual Relationships 🤗",
                                   style: .default,
                                   handler: {(alertAction: UIAlertAction!) in
                                    
                                    // Append object
                                    forMutual.append(otherObject.last!)
                                    
                                    // Push VC
                                    let mutualVC = self.storyboard?.instantiateViewController(withIdentifier: "mutualVC") as! MutualRelationships
                                    self.navigationController?.pushViewController(mutualVC, animated: true)
        })
        
        // (5) Report
        let report = UIAlertAction(title: "Report ✋",
                                   style: .destructive,
                                   handler: {(alertAction: UIAlertAction!) in
                                    // TODO::
        })
        
        // (6) Block
        let block = UIAlertAction(title: "Block 🚫",
                                  style: .destructive,
                                  handler: {(alertAction: UIAlertAction!) in
                                    // TODO::
        })
        
        // (7) Cancel
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        

        
        // TODO::
        // Add best friend,
        // And show only few options depending on whether they're friends or not
        
        if myFriends.contains(otherObject.last!) {
            alert.addAction(space)
            alert.addAction(chat)
            alert.addAction(bestFriends)
            alert.addAction(mutual)
            alert.addAction(report)
            alert.addAction(block)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        } else {
            alert.addAction(chat)
            alert.addAction(mutual)
            alert.addAction(report)
            alert.addAction(block)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    
    
    // Function to query other user's content
    func queryContent() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: otherObject.last!)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // clear array
                self.contentObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.contentObjects.append(object)
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        }
    }
    
    
    // Function to query other user's Space Posts
    func querySpace() {
        let wall = PFQuery(className: "Wall")
        wall.whereKey("toUser", equalTo: otherObject.last!)
        wall.order(byDescending: "createdAt")
        wall.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.spaceObjects.removeAll(keepingCapacity: false)
                
                
                for object in objects! {
                    self.spaceObjects.append(object)
                }
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(otherName.last!.uppercased())"
        }
    }
    
    
    // Function to check other user's privacy
    func checkPrivacy() {
        if otherObject.last!.value(forKey: "private") as! Bool == true {
            
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize and set title
        configureView()
        
        // Query content
        queryContent()
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true

        // Show navigationController
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        // TODO::
        // Show which button to tap!
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore  {
            print("Not first launch.")
        }
        else {
            print("First launch, setting NSUserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            
            let alert = UIAlertController(title: "Friend VS Follow",
                                          message: "Being friends with this person lets you\n(1) See their best friends.\n(2) Write in their Space.\n(3) See what they've been up to.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title again
        configureView()
        
        // Show tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 356, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if otherObject.last!.value(forKey: "userBiography") != nil {
            // Set fullname
            let fullName = otherObject.last!.value(forKey: "realNameOfUser") as! String
            
            label.text = "\(fullName.uppercased())\n\(otherObject.last!.value(forKey: "userBiography") as! String)"
        } else {
            label.text = "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)\n\(otherObject.last!.value(forKey: "birthday") as! String)"
        }
        
        label.sizeToFit()
        
        
        // ofSize should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: CGFloat(425 + label.frame.size.height))
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: self.view.frame.size.width, height: 35)
    }
    
    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! OtherUserHeader
        
        
        // Query relationships
        appDelegate.queryRelationships()
        
        // Declare parent VC
        header.delegate = self
        
        //set contentView frame and autoresizingMask
        header.frame = header.frame
        
        
        // Layout views
        header.rpUserProPic.layoutIfNeeded()
        header.rpUserProPic.layoutSubviews()
        header.rpUserProPic.setNeedsLayout()
        
        // Set header
        header.rpUserProPic.layer.cornerRadius = header.rpUserProPic.frame.size.width/2.0
        header.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        header.rpUserProPic.layer.borderWidth = 0.5
        header.rpUserProPic.clipsToBounds = true
        
        
        // (1) Get user's object
        otherObject.last!.fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // (A) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            header.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            header.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        
        // (2) Get user's bio and information
        if otherObject.last!.value(forKey: "userBiography") != nil {
            // Set fullname
            let fullName = otherObject.last!.value(forKey: "realNameOfUser") as! String
            
            header.userBio.text! = "\(fullName.uppercased())\n\(otherObject.last!.value(forKey: "userBiography") as! String)"
        } else {
            header.userBio.text! = "\(otherObject.last!.value(forKey: "realNameOfUser") as! String)\n\(otherObject.last!.value(forKey: "birthday") as! String)"
        }
        
        
        // (3) Set CurrentUser & OtherUser's relatinship state
        // Hide and show buttons depending on relationship
        // Also set title depending on relationship state
        
        
        
        // DEFAULT
        // Not yet connected
        header.relationType.isUserInteractionEnabled = true
        header.relationType.isHidden = true
        
        header.friendButton.isHidden = false
        header.friendButton.isEnabled = true
        
        header.followButton.isHidden = false
        header.followButton.isEnabled = true
        
        
        
        
        if myFriends.contains(otherObject.last!) {
            // FRIENDS
            header.relationType.isHidden = false
            header.relationType.setTitle("Friends", for: .normal)
        }
        
        
        // Friend Requested
        if myRequestedFriends.contains(otherObject.last!) || requestedToFriendMe.contains(otherObject.last!) {
            // FRIEND REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Friend Requested", for: .normal)
        }
        
        
        // Follower
        if myFollowers.contains(otherObject.last!) && !myFollowing.contains(otherObject.last!) {
            // FOLLOWER
            header.relationType.isHidden = false
            header.relationType.setTitle("Follower", for: .normal)
            
        }
        
        
        // Following
        if myFollowing.contains(otherObject.last!) {
            // FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        
        // Follow Requested
        if myRequestedFollowing.contains(otherObject.last!) || myRequestedFollowers.contains(otherObject.last!) {
            // FOLLOW REQUESTED
            header.relationType.isHidden = false
            header.relationType.setTitle("Follow Requested", for: .normal)
        }
        
        
        // Following
        if myFollowers.contains(otherObject.last!) && myFollowing.contains(otherObject.last!) {
            // FOLLOWER & FOLLOWING
            header.relationType.isHidden = false
            header.relationType.setTitle("Following", for: .normal)
        }
        
        
        // PFUser.currentUser()'s Profile
        if otherObject.last! == PFUser.current()! {
            header.friendButton.isHidden = true
            header.followButton.isHidden = true
            header.relationType.isHidden = true
        }
        
        
        
        
        return header
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.contentObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        print("Returning: \(contentObjects.count) count")
        return CGSize(width: self.view.frame.size.width, height: 105)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherContentCell", for: indexPath) as! OtherContentCell
        
        
        
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
        
        // Make mediaPreview cornered square
        cell.mediaPreview.layer.cornerRadius = 6.00
        cell.mediaPreview.clipsToBounds = true
        
        
        // Set bounds for textPreview
        cell.textPreview.clipsToBounds = true
        
        
    
        // Configure the cell
        contentObjects[indexPath.row].fetchIfNeededInBackground(block: {
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

                }
                
                
                
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "pv" {
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
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                }
                
                // (B) Text Post
                if object!["contentType"] as! String == "tp" {
                    // Show text
                    cell.textPreview.isHidden = false
                    // Hide media
                    cell.mediaPreview.isHidden = true
                    // Set text
                    cell.textPreview.text! = object!["textPost"] as! String
                }
                
                
                
                // (C) SHARED
                // TODO::
                // Complete this
                if object!["contentType"] as! String == "sh" {
                    // Show media
                    cell.mediaPreview.isHidden = false
                    // Set background color
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // Set SHARED ICON
                    cell.mediaPreview.image = UIImage(named: "RedShared")
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
                
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if contentObjects[indexPath.row].value(forKey: "contentType") as! String == "tp" {
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
            textPostObject.append(self.contentObjects[indexPath.row])
            
            
            // Present VC
            let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
            self.navigationController?.pushViewController(textPostVC, animated: true)
        }

        
        if contentObjects[indexPath.row].value(forKey: "contentType") as! String == "pv" {
            
            
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
            mediaAssetObject.append(self.contentObjects[indexPath.row])
            
            // Present VC
            let mediaVC = self.storyboard?.instantiateViewController(withIdentifier: "mediaAssetVC") as! MediaAsset
            self.navigationController?.pushViewController(mediaVC, animated: true)
        }
        
        
        
        if contentObjects[indexPath.row].value(forKey: "contentType") as! String == "sh" {
            
        }
        
    }

}
