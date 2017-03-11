//
//  SearchEngine.swift
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

import SDWebImage

class SearchEngine: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    // SearchBar
    let searchBar = UISearchBar()
    
    // App Delegate
    let appDelegate = AppDelegate()
    
    // Array to hold usernames
    var users = [PFObject]()
    
    // Arrays to hold hashtag searches
    var searchHashes = [String]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch relationships
        _ = appDelegate.queryRelationships()
        
        // Make first responder
        searchBar.becomeFirstResponder()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Set background for the image
        self.tableView!.backgroundView = UIImageView(image: UIImage(named: "SearchBackground"))
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()

        // SearchbarDelegates
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.frame.size.width = UIScreen.main.bounds.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch relationships
        _ = appDelegate.queryRelationships()
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - UISearchBar Delegate Method
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Track Who Searched the App
        Heap.track("Searched", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)",
                "SearchedFor": "\(self.searchBar.text!)"
            ])
        
        // Change tableView background
        self.tableView!.backgroundView = UIView()
        
        if searchBar.text!.hasPrefix("#") {
            // Looking for hashtags...
            let hashtags = PFQuery(className: "Hashtags")
            hashtags.whereKey("userHash", matchesRegex: "(?i)" + self.searchBar.text!.lowercased())
            hashtags.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.searchHashes.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        // Hashtag
                        if self.searchHashes.contains(object["userHash"] as! String) {
                            // Skip appending object
                        } else {
                            self.searchHashes.append(object["userHash"] as! String)
                        }
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
                
                // Reload data
                self.tableView!.reloadData()
            })
        } else {
            // Looking for humans...
            // Search for user
            let theUsername = PFUser.query()!
            theUsername.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
            let realName = PFUser.query()!
            realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
            let search = PFQuery.orQuery(withSubqueries: [theUsername, realName])
            search.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // USERNAME: Clear arrays
                    self.users.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        if !blockedUsers.contains(where: {$0.objectId! == object.objectId!}) {
                            self.users.append(object)
                        }
                    }
                    
                    // Reload data
                    if self.users.count != 0 {
                        // Reload data
                        self.tableView!.reloadData()
                    } else {
                        // Set background for tableView
                        self.tableView!.backgroundView = UIImageView(image: UIImage(named: "NoResults"))
                        // Reload data
                        self.tableView!.reloadData()
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }
    }
    
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text!.hasPrefix("#") {
            return searchHashes.count
        } else {
            return users.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
        
        // Set cell's parent vc
        cell.delegate = self

        if searchBar.text!.hasPrefix("#") {
            
            cell.userObject = nil
            
            // Hide IBObjects
            cell.rpUserProPic.isHidden = true
            cell.rpFullName.isHidden = true
            cell.rpUsername.isHidden = false
            
            // Set hashtag word
            cell.rpUsername.text! = self.searchHashes[indexPath.row]
            
        } else {
            
            cell.userObject = users[indexPath.row]
            
            // Show IBObjects
            cell.rpUserProPic.isHidden = false
            cell.rpFullName.isHidden = false
            cell.rpUsername.isHidden = false
            
            // Layout views
            cell.rpUserProPic.layoutSubviews()
            cell.rpUserProPic.layoutIfNeeded()
            cell.rpUserProPic.setNeedsLayout()
            
            
            // Make profile photo circular
            cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
            cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            cell.rpUserProPic.layer.borderWidth = 0.5
            cell.rpUserProPic.clipsToBounds = true
            
            
            // Get user's object
            users[indexPath.row].fetchInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's full name
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                    
                    // (2) Get username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    // (3) Fetch user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }

        return cell
    }



}
