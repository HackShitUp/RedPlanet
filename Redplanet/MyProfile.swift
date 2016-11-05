//
//  MyProfile.swift
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



// Define identifier
let myProfileNotification = Notification.Name("myProfile")


class MyProfile: UICollectionViewController {
    
    // Variable to hold my content
    var myContentObjects = [PFObject]()
    
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    // Function to fetch my content
    func fetchMine() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.myContentObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.myContentObjects.append(object)
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        }
    }

    // Function to stylize and set title of navigation bar
    func configureView() {
        let myUsername = PFUser.current()!.username!
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = myUsername.uppercased()
        }
    }
    
    
    // Refresh function
    func refresh() {
        // fetch data
        fetchMine()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.collectionView!.reloadData()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set background color
        self.collectionView!.backgroundColor = UIColor.white
        
        // Stylize and set title
        configureView()
        
        // Fetch current user's content
        fetchMine()
        
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: myProfileNotification, object: nil)
        
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show tabbarcontroller
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
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
        
        
        // ofSize should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 425 + label.frame.size.height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "myHeader", for: indexPath as IndexPath) as! MyHeader
        
        
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
                    header.myProPic.image = UIImage(named: "Gender Neutral User-96")
                }
            })
        }
        
        
        // (2) Set user's bio and information
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)\n\(PFUser.current()!["userBiography"] as! String)"
        } else {
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)"
        }
        
        // (3) Set count for friends, followers, and following
        if myFriends.count == 0 {
            header.numberOfFriends.setTitle("friends", for: .normal)
        } else if myFriends.count == 1 {
            header.numberOfFriends.setTitle("1\nfriend", for: .normal)
        } else {
            header.numberOfFriends.setTitle("\(myFriends.count)\nfriends", for: .normal)
        }
        
        
        if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("followers", for: .normal)
        } else if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("1\nfollower", for: .normal)
        } else {
            header.numberOfFollowers.setTitle("\(myFollowers.count)\nfollowers", for: .normal)
        }
        
        
        if myFollowing.count == 0 {
            header.numberOfFollowing.setTitle("following", for: .normal)
        } else if myFollowing.count == 1 {
            header.numberOfFollowing.setTitle("1\nfollowing", for: .normal)
        } else {
            header.numberOfFollowing.setTitle("\(myFollowing.count)\nfollowing", for: .normal)
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
        return self.myContentObjects.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: self.view.frame.size.width, height: 65)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myContentCell", for: indexPath) as! MyContentCell
    
        
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
        
        
        // Fetch objects
        myContentObjects[indexPath.row].fetchIfNeededInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Set user's profile photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
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
                
                
                // (2) Set username
                cell.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
                
                
                // (2) Determine Content Type
                // (A) Photo
                if object!["contentType"] as! String == "ph" {
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
                
                // (B) Text Post
                if object!["contentType"] as! String == "tp" {
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    // Set mediaPreview's icon
                    cell.mediaPreview.image = UIImage(named: "TextPostIcon")
                }
                
                
                
                
                // (C) SHARED
                if object!["contentType"] as! String == "sh" {
                    // Show mediaPreview
                    cell.mediaPreview.isHidden = false
                    
                    // Set background color for mediaPreview
                    cell.mediaPreview.backgroundColor = UIColor.clear
                    // and set icon for indication
                    cell.mediaPreview.image = UIImage(named: "BlueShared")
                    
                }
                
                
                
                
                
                // (D) Profile Photo
                if object!["contentType"] as! String == "pp" {
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
                // == When user takes a photo and shares it with his/her friends on the spot
                
                
                
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
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
    
        return cell
    }


}
