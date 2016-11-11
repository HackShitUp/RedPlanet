//
//  RelationshipRequests.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/1/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import DZNEmptyDataSet



// Global variable to handle different forms of request
// IE: if requestType == "friend" > frinedFunctions(), etc.
var requestType: String?



// Define Notification Identifier
let requestsNotification = Notification.Name("relationshipRequests")

class RelationshipRequests: UICollectionViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold friends, followers, and following
    var nFriends = [PFObject]()
    var nFollowers = [PFObject]()

    // Users you sent requests to
    var sentTo = [PFObject]()
    var friendVSFollow = [String]()
    
    
    // SourceType
    var sourceType: Int = 0
    
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reload data
        if self.sourceType == 0 {
            // Friends
            fetchFriends()
        } else if self.sourceType == 1 {
            // Followers
            fetchFollowers()
        } else {
            // Following
            fetchSent()
        }
        
        // Reload data
        self.collectionView!.reloadData()
    }
    
    func fetchFriends() {
        // Fetch friends
        let friends = PFQuery(className: "FriendMe")
        friends.whereKey("isFriends", equalTo: false)
        friends.includeKey("endFriend")
        friends.includeKey("frontFriend")
        friends.whereKey("endFriend", equalTo: PFUser.current()!)
        friends.order(byDescending: "createdAt")
        friends.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.nFriends.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.nFriends.append(object["frontFriend"] as! PFUser)
                }
                
                // Set DZNEmptyDataSet
                if self.nFriends.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // REload data
            self.collectionView!.reloadData()
        }
    }
    
    
    
    // Query followers
    func fetchFollowers() {
        let followers = PFQuery(className: "FollowMe")
        followers.includeKey("endFriend")
        followers.includeKey("frontFriend")
        followers.whereKey("following", equalTo: PFUser.current()!)
        followers.whereKey("isFollowing", equalTo: false)
        followers.order(byDescending: "createdAt")
        followers.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.nFollowers.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.nFollowers.append(object["follower"] as! PFUser)
                }
                
                
                // Set DZNEmptyDataSet
                if self.nFollowers.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        }
    }
    
    
    // Query following
    func fetchSent() {
        // Fetch all objects where the current user has sent a...
        // (1) Friend Request: "frontFriend" == PFUser.currentUser()!
        // (2) Follow Requests: "follower" == PFUser.currentUser()!
        let friend = PFQuery(className: "FriendMe")
        friend.includeKey("frontFriend")
        friend.includeKey("endFriend")
        friend.whereKey("isFriends", equalTo: false)
        friend.whereKey("frontFriend", equalTo: PFUser.current()!)
        friend.order(byDescending: "createdAt")
        friend.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.sentTo.removeAll(keepingCapacity: false)
                self.friendVSFollow.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.sentTo.append(object["endFriend"] as! PFUser)
                    self.friendVSFollow.append("friend")
                }
                
                
                
                // Fetch Sent Follow Requests
                let follow = PFQuery(className: "FollowMe")
                follow.includeKey("following")
                follow.includeKey("follower")
                follow.whereKey("isFollowing", equalTo: false)
                follow.whereKey("follower", equalTo: PFUser.current()!)
                follow.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        for object in objects! {
                            self.sentTo.append(object["following"] as! PFUser)
                            self.friendVSFollow.append("follow")
                        }
                        
                        
                        print("OBJECTS: \(self.sentTo)")
                        
                        // Set DZNEmptyDataSet
                        if self.sentTo.count == 0 {
                            self.collectionView!.emptyDataSetSource = self
                            self.collectionView!.emptyDataSetDelegate = self
                        }
                        
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                    
                })
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
        
    }
    
    
    
    
    // Function to swithc sourec
    func switchSource(sender: UISegmentedControl) -> Int {
        
        print("Fired")
        
        if sender.selectedSegmentIndex == 0 {
            // Friends
            fetchFriends()
            requestType = "friends"

            sourceType = 0
        } else if sender.selectedSegmentIndex == 1 {
            // Followers
            fetchFollowers()
            requestType = "follow"

            sourceType = 1
        } else {
            // Following
            fetchSent()
            requestType = "sent"

            sourceType = 2
        }
        
        return sourceType
    }
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Relationship Requests"
        }
    }

    
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if nFriends.count == 0 || nFollowers.count == 0 || sentTo.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        
        if sourceType == 0 {
            str = "🦄\nNo Friend Requests"
        } else if sourceType == 1 {
            str = "🦄\nNo Follow Requests"
        } else {
            str = "🦄\nYou haven't requested to Friend or Follow people yet."
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.darkGray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }

    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Set initial query
        if self.sourceType == 0 {
            // Friends
            fetchFriends()
            requestType = "friends"

        } else if self.sourceType == 1 {
            // Followers
            fetchFollowers()
            requestType = "follow"

        } else {
            // Sent
            fetchSent()
            requestType = "sent"

        }
        
        
        // Add Notification 
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: requestsNotification, object: nil)
        
        
        // Set background color
        self.collectionView!.backgroundColor = UIColor.white
        
        
        // Stylize title
        configureView()
        
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - UICollectionReusableView Data source method
    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        // ofSize should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 35)
    }
    
    
    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "relationshipsHeader", for: indexPath) as! RelationshipRequestsHeader
        
        
        // Add target method
        header.friendsFollowersFollowing.addTarget(self, action: #selector(switchSource), for: .allEvents)
        
        return header
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.sourceType == 0 {
            
            return nFriends.count
        } else if self.sourceType == 1 {
            
            return nFollowers.count
        } else {
            
            return sentTo.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "rRelationshipsCell", for: indexPath) as! RelationshipRequestsCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2.0
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Set delegate
        cell.delegate = self
    
        
        if self.sourceType == 0 {
            // Friends
            nFriends[indexPath.row].fetchIfNeededInBackground(block:  {
                (object: PFObject?, error: Error?) in
                if error == nil {

                    
                    // (1) Set user's fullName
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                    // (2) Get username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    // (3) Get profile photo
                    // Handle optional chaining
                    if let proPic = object!["userProfilePicture"] as? PFFile {
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

                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            // (4) Set user's object
            cell.userObject = nFriends[indexPath.row]
            
            
            // Hide button and show relative buttons
            cell.relationState.isHidden = true
            cell.confirmButton.isHidden = false
            cell.ignoreButton.isHidden = false
            
            
        } else if self.sourceType == 1 {
            // Followers
            nFollowers[indexPath.row].fetchIfNeededInBackground(block:  {
                (object: PFObject?, error: Error?) in
                if error == nil {

                    
                    // (1) Set user's fullName
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                    // (2) Get username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    // (3) Get profile photo
                    // Handle optional chaining
                    if let proPic = object!["userProfilePicture"] as? PFFile {
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

                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            // (4) Set user's object
            cell.userObject = nFollowers[indexPath.row]
            
            
            // Hide button and show relative buttons
            cell.relationState.isHidden = true
            cell.confirmButton.isHidden = false
            cell.ignoreButton.isHidden = false
            
            
        } else {
            // Sent To
            sentTo[indexPath.row].fetchIfNeededInBackground(block:  {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    
                    // (1) Set user's fullName
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                    // (2) Get username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    // (3) Get profile photo
                    // Handle optional chaining
                    if let proPic = object!["userProfilePicture"] as? PFFile {
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

                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
            // (4) Set user's object
            cell.userObject = sentTo[indexPath.row]
            
            
            
            // Define which type you sent a request to: friend or follow
            cell.friendFollow = friendVSFollow[indexPath.row]
            
            // Hide button and show relative buttons
            cell.relationState.isHidden = false
            cell.confirmButton.isHidden = true
            cell.ignoreButton.isHidden = true
            
            // Set button: "Rescind Friend Request"
            // If PFUser.currentUser()! sent "friend requested"
            if friendVSFollow[indexPath.row] == "friend" {
                // Hide buttons
                cell.relationState.isHidden = false
                cell.relationState.setTitle("Rescind Friend Request", for: .normal)
            }
            
            // Set button: "Rescind Follow Request"
            // If PFUser.currentUser()! sent "follow requested"
            if friendVSFollow[indexPath.row] == "follow" {
                // Hide buttons
                cell.relationState.isHidden = false
                cell.relationState.setTitle("Rescind Follow Request", for: .normal)
            }
            
            
            
        }
        
    
        return cell
    } // end cellForRowAt


}
