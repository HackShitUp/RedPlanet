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

import SVProgressHUD

class Explore: UICollectionViewController, UISearchBarDelegate {
    
    
    // Variable to hold objects to explore
    var exploreObjects = [PFObject]()
    
    // Set pipeline method
    var page: Int = 50
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Search Bar
    var searchBar = UISearchBar()
    
    
    // Function to refresh
    func refresh() {
        // Query Explore
        queryExplore()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.collectionView!.reloadData()
    }
    
    
    // Fetch Public Users
    func queryExplore() {
        
        let user = PFUser.query()!
        user.whereKey("private", equalTo: false)
        user.limit = self.page
        user.order(byDescending: "createdAt")
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.exploreObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.exploreObjects.append(object)
                }
                
                // Print results
                print("Explore objects: \(self.exploreObjects.count)")
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)

        
        // Query Public accounts
        // $$$ MONETIZE ON THIS
        queryExplore()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        
        // Set collectionView's backgroundColor
        self.collectionView!.backgroundColor = UIColor.white
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        
        
        // SearchbarDelegates
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.frame.size.width = UIScreen.main.bounds.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
        
        
        // Set navigationbar's backgroundColor
        self.navigationController?.navigationBar.backgroundColor = UIColor.lightGray
    }
    

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Clear searchBar text
        self.searchBar.text! = ""
        
        // Resign frist responder
        self.searchBar.resignFirstResponder()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Show tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        // Make navigationBar's color clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: - SearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Push to SearchEngine
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
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
    
    /*
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // Size should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 135.00)
    }

    
    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "exploreHeader", for: indexPath) as! ExploreHeader
     
        
        return header
    }
    */
    

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
        
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
        
        
        // Fetch Explore Objects
        exploreObjects[indexPath.row].fetchIfNeededInBackground(block:  {
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
        
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Append to otherObject
        otherObject.append(self.exploreObjects[indexPath.row])
        // Append to otherName
        otherName.append(self.exploreObjects[indexPath.row].value(forKey: "username") as! String)
        
        // Push to VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.exploreObjects.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryExplore()
        }
    }

}
