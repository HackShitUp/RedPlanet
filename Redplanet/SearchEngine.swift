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

import DZNEmptyDataSet
import SDWebImage

class SearchEngine: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate, DZNEmptyDataSetSource {
    
    // SearchBar
    let searchBar = UISearchBar()
    
    // App Delegate
    let appDelegate = AppDelegate()
    
    // Array to hold usernames
    var searchObjects = [PFObject]()
    
    // Arrays to hold hashtag searches
    var searchHashes = [String]()
    
    @IBAction func backButton(_ sender: AnyObject) {
        self.searchHashes.removeAll(keepingCapacity: false)
        self.searchObjects.removeAll(keepingCapacity: false)
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: DZNEmptyDataSet Framework
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.searchObjects.isEmpty || self.searchHashes.isEmpty || self.searchBar.text == "" {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        if self.searchBar.text == "" {
            str = "Search for people to follow or prefix '#' to search for Hashtags..."
        } else if self.searchObjects.isEmpty || self.searchHashes.isEmpty {
            str = "💩\nNo Results"
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 21)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch relationships
        _ = appDelegate.queryRelationships()
        
        // Make first responder
        searchBar.becomeFirstResponder()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // MARK: - DZNEmptyDataSet
        self.tableView!.emptyDataSetSource = self
        
        // Configure UITableView
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
        
        // Configure UISearchBar
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch relationships
        _ = appDelegate.queryRelationships()
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchHashes.removeAll(keepingCapacity: false)
        self.searchObjects.removeAll(keepingCapacity: false)
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
                    
                    // Reload data
                    self.tableView!.reloadData()
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
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
                    self.searchObjects.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        if !blockedUsers.contains(where: {$0.objectId! == object.objectId!}) {
                            self.searchObjects.append(object)
                        }
                    }
                    
                    // Reload data
                    self.tableView!.reloadData()
                    
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
            return searchObjects.count
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
            // Set user's object
            cell.userObject = searchObjects[indexPath.row]
            
            // Show IBObjects
            cell.rpUserProPic.isHidden = false
            cell.rpFullName.isHidden = false
            cell.rpUsername.isHidden = false

            // MARK: - RPHelpers extension
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
            // (1) Set user's full name
            cell.rpFullName.text! = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // (2) Set username
            cell.rpUsername.text! = self.searchObjects[indexPath.row].value(forKey: "username") as! String
            
            // (3) Get and set user's profile photo
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        }

        return cell
    }
}
