//
//  Explore.swift
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


class Explore: UICollectionViewController, UISearchBarDelegate {
    
    
    // Variable to hold objects to explore
    var exploreObjects = [PFObject]()
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Search Bar
    var searchBar = UISearchBar()
    
    
    // Fetch Public Users
    func queryExplore() {
        let user = PFUser.query()!
        user.whereKey("private", equalTo: false)
        user.order(byDescending: "createdAt")
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.exploreObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.exploreObjects.append(object)
                }
                
                // Print results
                print("Explore objects: \(self.exploreObjects.count)")
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Query Public accounts
        // $$$ MONETIZE ON THIS
        queryExplore()
        
        
        // Set collectionView's backgroundColor
        self.collectionView!.backgroundColor = UIColor.white
        
        
        // SearchbarDelegates
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        searchBar.frame.size.width = UIScreen.main.bounds.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
        
        
        // Set navigationbar's backgroundColor
        self.navigationController?.navigationBar.backgroundColor = UIColor.lightGray

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: - SearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Resign first responder
        self.searchBar.resignFirstResponder()
    }
    
    
    

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("Returning count: \(exploreObjects.count)")
        return exploreObjects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
        
        
//        // (1) Set username
//        cell.rpUsername.text! = exploreObjects[indexPath.row].value(forKey: "username") as! String
//        
//        // (2) Get user's Profile Photo 
//        // Handle optional chaining
//        if let proPic = exploreObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
//            proPic.getDataInBackground(block: {
//                (data: Data?, error: Error?) in
//                if error == nil {
//                    // Set user's profile photo
//                    cell.rpUserProPic.image = UIImage(data: data!)
//                    
//                } else {
//                    print(error?.localizedDescription)
//                    
//                    // If not found, set default profile photo
//                    cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
//                }
//            })
//        }

        
        // Fetch Explore Objects
        exploreObjects[indexPath.row].fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get username
                cell.rpUsername.text! = object!["username"] as! String
                
                // (2) Get profile photo
                // Handle optional chaining
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription)
                            
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription)
            }
        }
        
        
    
    
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
