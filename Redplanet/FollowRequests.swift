//
//  FollowRequests.swift
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

// Define Notification Identifier
let requestsNotification = Notification.Name("FollowRequests")

class FollowRequests: UICollectionViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold followers, and following
    var nFollowers = [PFObject]()
    // Users you sent requests to
    var sentTo = [PFObject]()

    @IBOutlet weak var followSent: UISegmentedControl!
    @IBAction func toggleSource(_ sender: Any) {
        if self.followSent.selectedSegmentIndex == 0 {
            // Followers
            fetchFollowers()
        } else {
            // Following
            fetchSent()
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reload data
        if self.followSent.selectedSegmentIndex == 0 {
            // Followers
            fetchFollowers()
        } else {
            // Following
            fetchSent()
        }
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


    // MARK: DZNEmptyDataSet Framework
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
        
        if self.followSent.selectedSegmentIndex == 0 {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add style font for UISegmentedControl
        let style = NSDictionary(object: UIFont(name: "AvenirNext-Demibold", size: 12.00) as Any, forKey: NSFontAttributeName as NSCopying)
        self.followSent.setTitleTextAttributes(style as! [NSObject: Any], for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set initial query
        if self.followSent.selectedSegmentIndex == 0 {
            // Followers
            fetchFollowers()
        } else {
            // Sent
            fetchSent()
        }
        
        // Add Notification 
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: requestsNotification, object: nil)
        
        // Configure UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width, height: 105.00)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.backgroundColor = UIColor.white
        
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
        // width X 40
        return CGSize(width: self.view.frame.size.width, height: 40)
    }
    
    
    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "followRequestsHeader", for: indexPath) as! FollowRequestsHeader
        
        // Set title
        if self.followSent.selectedSegmentIndex == 0 {
            header.title.text! = "FOLLOW REQUESTS"
        } else {
            header.title.text! = "SENT FOLLOW REQUESTS"
        }
        
        // Underline header's title
        let titleStyle = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "\(header.title.text!)", attributes: titleStyle)
        header.title.attributedText = underlineAttributedString
        
        return header
    }


    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.followSent.selectedSegmentIndex == 0 {
            return nFollowers.count
        } else {
            return sentTo.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "followRequestsCell", for: indexPath) as! FollowRequestsCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Set delegate
        cell.delegate = self
    
        if self.followSent.selectedSegmentIndex == 0 {
        // FOLLOWER REQUESTED
            
            // (1) Set user's fullName
            cell.rpFullName.text! = self.nFollowers[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // (2) Get username
            cell.rpUsername.text! = self.nFollowers[indexPath.row].value(forKey: "username") as! String
            
            // (3) Get profile photo
            // Handle optional chaining
            if let proPic = self.nFollowers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            // (4) Set user's object
            cell.userObject = nFollowers[indexPath.row]
            
            // Hide button and show relative buttons
            cell.relationState.isHidden = true
            cell.confirmButton.isHidden = false
            cell.ignoreButton.isHidden = false
            
            
        } else {
        // SENT TO
            // (1) Set user's fullName
            cell.rpFullName.text! = self.sentTo[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // (2) Get username
            cell.rpUsername.text! = self.sentTo[indexPath.row].value(forKey: "username") as! String
            
            // (3) Get profile photo
            // Handle optional chaining
            if let proPic = self.sentTo[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
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
