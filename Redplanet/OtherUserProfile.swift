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
                print(error?.localizedDescription)
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
                print(error?.localizedDescription)
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
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make navigationBar's color white
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
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
        return CGSize(width: self.view.frame.size.width, height: 425 + label.frame.size.height)
    }


    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! OtherUserHeader
        
        
        // Query relationships
        appDelegate.queryRelationships()
        
        // Declare parent VC
        header.delegate = self
        
        
        // Layout views
        header.rpUserProPic.layoutIfNeeded()
        header.rpUserProPic.layoutSubviews()
        header.rpUserProPic.setNeedsLayout()
        
        // Set header
        header.rpUserProPic.layer.cornerRadius = 125.00
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
                            print(error?.localizedDescription)
                            // Set default
                            header.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription)
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
        return self.spaceObjects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherContentCell", for: indexPath) as! OtherContentCell
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
