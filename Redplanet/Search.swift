//
//  Search.swift
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

/*
 UITableViewController class that allows users to search for others, and navigate to their profile afterwards.
 */

class Search: UITableViewController, UINavigationControllerDelegate, UITextFieldDelegate, DZNEmptyDataSetSource {

    // App Delegate
    let appDelegate = AppDelegate()
    
    // Array to hold usernames
    var searchObjects = [PFObject]()
    
    // Arrays to hold hashtag searches
    var searchHashes = [String]()
    
    @IBOutlet weak var searchBar: UITextField!
    @IBAction func backButton(_ sender: AnyObject) {
        self.searchHashes.removeAll(keepingCapacity: false)
        self.searchObjects.removeAll(keepingCapacity: false)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - DZNEmptyDataSet
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
    
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        // Make first responder
        searchBar.becomeFirstResponder()
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.normalizeBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch relationships
        _ = appDelegate.queryRelationships()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UITableView
        tableView.separatorColor = UIColor.groupTableViewBackground
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        // MARK: - DZNEmptyDataSet
        tableView.emptyDataSetSource = self
        
        // Configure UISearchBar
        searchBar.delegate = self
        searchBar.frame = CGRect(x: 58, y: 7, width: self.view.frame.size.width - 100, height: 30)
        searchBar.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        searchBar.backgroundColor = UIColor.groupTableViewBackground
        searchBar.font = UIFont(name: "AvenirNext-Medium", size: 17)
        searchBar.textColor = UIColor.black
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchHashes.removeAll(keepingCapacity: false)
        self.searchObjects.removeAll(keepingCapacity: false)
        // Resign first responder
        self.searchBar.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - UITextField
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            
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
                hashtags.whereKey("hashtag", matchesRegex: "(?i)" + self.searchBar.text!.lowercased())
                hashtags.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.searchHashes.removeAll(keepingCapacity: false)
                        for object in objects! {
                            if !self.searchHashes.contains(object["hashtag"] as! String) {
                                self.searchHashes.append(object["hashtag"] as! String)
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
        
        return true
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
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
        
        // Set cell's parent vc
        cell.delegate = self

        
        if searchBar.text!.hasPrefix("#") {
            // De-allocate UITableViewCell's PFObject
            cell.userObject = nil
            // Hide IBObjects
            cell.rpUserProPic.isHidden = true
            cell.rpUsername.isHidden = true
            cell.rpFullName.isHidden = false
            // Set hashtag word
            cell.rpFullName.text! = self.searchHashes[indexPath.row]
            
        } else {
            // Set user's object
            cell.userObject = searchObjects[indexPath.row]
            // Configure UI
            cell.rpUserProPic.isHidden = false
            cell.rpFullName.isHidden = false
            cell.rpUsername.isHidden = false
            cell.rpFullName.font = UIFont(name: "AvenirNext-Medium", size: 17)
            
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
