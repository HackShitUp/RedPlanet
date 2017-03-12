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

import SDWebImage
import DZNEmptyDataSet

// Global variable to handle different forms of request
var requestType: String?

// Define Notification Identifier
let requestsNotification = Notification.Name("relationshipRequests")

class RelationshipRequests: UICollectionViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold followers, and following
    var nFollowers = [PFObject]()

    // Users you sent requests to
    var sentTo = [PFObject]()

    // SourceType
    var sourceType: Int = 0
    
    // Refresher
    var refresher: UIRefreshControl!

    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reload data
        if self.sourceType == 0 {
            // Followers
            fetchFollowers()
        } else {
            // Following
            fetchSent()
        }
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.collectionView!.reloadData()
    }
    
    // Query followers
    func fetchFollowers() {
        let followers = PFQuery(className: "FollowMe")
        followers.includeKeys(["follower", "following"])
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
        
        // Fetch Sent Follow Requests
        let follow = PFQuery(className: "FollowMe")
        follow.includeKeys(["following", "follower"])
        follow.whereKey("isFollowing", equalTo: false)
        follow.whereKey("follower", equalTo: PFUser.current()!)
        follow.order(byDescending: "createdAt")
        follow.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.sentTo.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.sentTo.append(object.object(forKey: "following") as! PFUser)
                }
                
                // Set DZNEmptyDataSet
                if self.sentTo.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    
    
    
    
    // Function to swithc sourec
    func switchSource(sender: UISegmentedControl) -> Int {
        
        if sender.selectedSegmentIndex == 0 {
            // Followers
            fetchFollowers()
            requestType = "follow"

            sourceType = 0
        } else {
            // Following
            fetchSent()
            requestType = "sent"

            sourceType = 1
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
            self.title = "Follow Requests"
        }
        
        // Show nav bar && show tabBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }

  
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if nFollowers.count == 0 || sentTo.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        if sourceType == 0 {
            str = "🦄\nNo Follow Requests"
        } else {
            str = "🦄\nYou haven't requested to Follow anyone recently."
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }

    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Set initial query
        if self.sourceType == 0 {
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
        
        // Set collectionview's cell size
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width, height: 105.00)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout

        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        self.collectionView!.addSubview(refresher)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    // MARK: - UICollectionReusableView Data source method
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSize(width: self.view.frame.size.width, height: 30)
    }
    
    
    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "relationshipsHeader", for: indexPath) as! RelationshipRequestsHeader
        
        // Add target method
        header.segmentControl.addTarget(self, action: #selector(switchSource), for: .allEvents)
        
        return header
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.sourceType == 0 {
            
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
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
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
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                    }

                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
            // (4) Set user's object
            cell.userObject = sentTo[indexPath.row]
            
            // Hide button and show relative buttons
            cell.relationState.isHidden = false
            cell.confirmButton.isHidden = true
            cell.ignoreButton.isHidden = true

            // Set button: "Rescind Follow Request"
            // If PFUser.currentUser()! sent "follow requested"
            // Hide buttons
            cell.relationState.isHidden = false
            cell.relationState.setTitle("Rescind Follow Request", for: .normal)
        }
        
    
        return cell
    } // end cellForRowAt


}
