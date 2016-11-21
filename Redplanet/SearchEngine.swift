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


class SearchEngine: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    // SearchBar
    let searchBar = UISearchBar()
    
    // Array to hold usernames
    var users = [PFObject]()
    
    // Arrays to hold hashtag searches
    var searchHashes = [String]()
    var dataHash = [String]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make first responder
        searchBar.becomeFirstResponder()

        // SearchbarDelegates
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        searchBar.frame.size.width = UIScreen.main.bounds.width - 75
        let searchItem = UIBarButtonItem(customView: searchBar)
        self.navigationItem.rightBarButtonItem = searchItem
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - UISearchBar Delegates
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if searchBar.text!.hasPrefix("#") {
            // Looking for hashtags...
            let hashtags = PFQuery(className: "Hashtags")
            hashtags.whereKey("userHash", matchesRegex: "(?i)" + self.searchBar.text!.lowercased())
            hashtags.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // Clear array
                    self.searchHashes.removeAll(keepingCapacity: false)
                    self.dataHash.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.searchHashes.append(object["userHash"] as! String)
                        self.dataHash.append(object["hashtag"] as! String)
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
            let theUsername = PFQuery(className: "_User")
            theUsername.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
            
            let realName = PFQuery(className: "_User")
            realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
            
            let search = PFQuery.orQuery(withSubqueries: [theUsername, realName])
            search.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // USERNAME: Clear arrays
                    self.users.removeAll(keepingCapacity: false)
                    
                    for object in objects! {
                        self.users.append(object)
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
                
                // Reload data
                self.tableView!.reloadData()
            })
        }
        
        return true
    }
    
    
    // Cancel
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
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
        return 60
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
        }

        return cell
    }



}
