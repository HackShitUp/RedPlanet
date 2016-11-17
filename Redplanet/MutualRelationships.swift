//
//  MutualRelationships.swift
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
import SVProgressHUD



// Global variable to show mutual relationships
var forMutual = [PFObject]()


class MutualRelationships: UICollectionViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Arrays to hold users
    var mFriends = [PFObject]()
    var mFollowers = [PFObject]()
    var mFollowing = [PFObject]()
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Source Type
    var sourceType: Int = 0
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
    }
    
    // Query friends
    func queryFriends() {
        
        // Query PFUser.currentUser()'s relationships
        appDelegate.queryRelationships()
        
        
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("frontFriend", containedIn: myFriends)
        fFriends.whereKey("endFriend", equalTo: forMutual.last!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("endFriend", containedIn: myFriends)
        eFriends.whereKey("frontFriend", equalTo: forMutual.last!)
        
        // Query other user's friends
        let mFriends = PFQuery.orQuery(withSubqueries: [fFriends, eFriends])
        mFriends.includeKey("endFriend")
        mFriends.includeKey("frontFriend")
        mFriends.whereKey("isFriends", equalTo: true)
        mFriends.order(byDescending: "createdAt")
        mFriends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.mFriends.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    if object["endFriend"] as! PFUser == forMutual.last! {
                        self.mFriends.append(object["frontFriend"] as! PFUser)
                    }
                    
                    if object["frontFriend"] as! PFUser == forMutual.last! {
                        self.mFriends.append(object["endFriend"] as! PFUser)
                    }
                }
                
                
                // Set Friends
                if self.mFriends.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
        })
        
    }
    
    
    // Query followers
    func queryFollowers() {
        // Query PFUser.currentUser()'s relationships
        appDelegate.queryRelationships()
        
        // Fetch OtherUser's followers
        let followers = PFQuery(className: "FollowMe")
        followers.includeKey("follower")
        followers.whereKey("following", equalTo: forMutual.last!)
        followers.whereKey("follower", containedIn: myFollowers)
        followers.order(byDescending: "createdAt")
        followers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.mFollowers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.mFollowers.append(object["follower"] as! PFUser)
                }
                
                
                
                // Set Followers
                if self.mFollowers.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
        })
        
    }
    
    
    
    // Query following
    func queryFollowing() {
        // Query PFUser.currentUser()'s relationships
        appDelegate.queryRelationships()
        
        // Fetch OtherUser's followings
        let following = PFQuery(className: "FollowMe")
        following.includeKey("following")
        following.whereKey("follower", equalTo: forMutual.last!)
        following.whereKey("following", containedIn: myFollowing)
        following.order(byDescending: "createdAt")
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.mFollowing.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.mFollowing.append(object["following"] as! PFUser)
                }
                
                
                // Set Following
                if self.mFollowing.count == 0 {
                    self.collectionView!.emptyDataSetSource = self
                    self.collectionView!.emptyDataSetDelegate = self
                }
                
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
        })
        
    }
    
    
    
    // Function to switch sources
    func switchSource(sender: UISegmentedControl) -> Int {
        switch sender.selectedSegmentIndex {
        case 0:
            queryFriends()
            sourceType = 0
//            self.collectionView!.reloadData()
        case 1:
            queryFollowers()
            sourceType = 1
//            self.collectionView!.reloadData()
        case 2:
            queryFollowing()
//            self.collectionView!.reloadData()
            sourceType = 2
        default:
            break;
        }
        
        
        return sourceType
    }
    
    
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.mFriends.count == 0 || self.mFollowers.count == 0 || self.mFollowing.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        var str: String?
        
        if sourceType == 0 {
            // Friends
            str = "🤔\nNo Mutual Friends"
        } else if sourceType == 1 {
            // Followers
            str = "🤔\nNo Mutual Followers"
        } else {
            // Following
            str = "🤔\nNo Mutual Followings"
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
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
            self.title = "Mutual Relationships"
        }
    }
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Show Progress
        SVProgressHUD.show()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout

        
        // Get initial relationships
        if sourceType == 0 {
            // Friends
            queryFriends()
        } else if sourceType == 1 {
            // Followers
            queryFollowers()
        } else {
            // Following
            queryFollowing()
        }
        
        
        // Stylize title
        configureView()
        
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        // Stylize title
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - UICollectionReusableView Data Source Method
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "mRelationshipsHeader", for: indexPath) as! MutualRelationshipsHeader
        
        // Add segmented control tap method
        header.friendsFollowersFollowing.addTarget(self, action: #selector(switchSource), for: .allEvents)
        
        return header
    }
    
    
    
    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        

        // ofSize should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 35.00)
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if sourceType == 0 {
            return mFriends.count
        } else if sourceType == 1 {
            return mFollowers.count
        } else {
            return mFollowing.count
        }
        
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mRelationshipsCell", for: indexPath) as! MutualRelationshipsCell
    
        
        
        // LayoutViews for rpUserProPic
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        
        if sourceType == 0 {
            // Friends
            mFriends[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's proPic
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    
                    // (2) Set fullName
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        
        } else if sourceType == 1 {
            // Followers
            mFollowers[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's proPic
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    
                    // (2) Set fullName
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        
        } else {
            // Following
            mFollowing[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's proPic
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    
                    // (2) Set fullName
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
        
        
    
        return cell
    }

    
    
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Initalize user's object
        var userObject: PFObject?
        // Initalize user's username
        var userName: String?
        
        if sourceType == 0 {
            // Friends
            userObject = mFriends[indexPath.row]
            userName = mFriends[indexPath.row].value(forKey: "username") as? String
            
        } else if sourceType == 1 {
            // Followers
            userObject = mFollowers[indexPath.row]
            userName = mFollowers[indexPath.row].value(forKey: "username") as? String
            
        } else {
            // Following
            userObject = mFollowing[indexPath.row]
            userName = mFollowing[indexPath.row].value(forKey: "username") as? String
            
        }
        
        
        // Append data
        otherObject.append(userObject!)
        otherName.append(userName!)
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.navigationController?.pushViewController(otherVC, animated: true)
        
    }
    
    
    

}
