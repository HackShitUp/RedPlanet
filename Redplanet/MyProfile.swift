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


class MyProfile: UICollectionViewController {
    
    // Variable to hold my content
    var myContentObjects = [PFObject]()
    
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
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
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        }
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
            self.navigationController?.navigationBar.topItem?.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set background color
        self.collectionView!.backgroundColor = UIColor.white
        
        // Stylize and set title
        configureView()
        
        
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
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        
//        let label:UILabel = UILabel(frame: CGRect(8, 304, self.collectionView!.frame.size.width - 16, CGFloat.max))
//        label.numberOfLines = 0
//        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
//        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
//        label.text = PFUser.current()!.value(forKey: "userBiography") as! String
//        label.sizeToFit()
//
//        
//        // ofSize should be the same size of the headerView's label size:
//        return CGSize(width: self.view.frame.size.width, height: 425 + label.frame.size.height)
//    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "myHeader", for: indexPath as IndexPath) as! MyHeader
        
//        header.setNeedsUpdateConstraints()
//        header.updateConstraintsIfNeeded()
//        
//        header.setNeedsLayout()
//        header.layoutIfNeeded()
//        
//        header.userBio.setNeedsLayout()
//        header.userBio.layoutIfNeeded()
//        header.userBio.setNeedsUpdateConstraints()
//        header.userBio.updateConstraintsIfNeeded()
        
        
        print("HeaderHeight: \(header.frame.size.height)")
        // 374
        
        
        // Query relationships
        appDelegate.queryRelationships()
        
        
        // Layout subviews
        header.myProPic.layoutSubviews()
        header.myProPic.layoutIfNeeded()
        header.myProPic.setNeedsLayout()
        
        // Make profile photo circular
        header.myProPic.layer.cornerRadius = 125.00
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
                    print(error?.localizedDescription)
                    
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
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myContentCell", for: indexPath) as! MyContentCell
    
        // Configure the cell
    
        return cell
    }


}
