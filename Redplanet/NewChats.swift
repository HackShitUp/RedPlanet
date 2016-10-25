//
//  NewChats.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD


class NewChats: UITableViewController, UISearchBarDelegate, UINavigationControllerDelegate {
    
    // Boolean variable to check whether search bar is active
    var searchActive: Bool = false
    // Search Bar
    var searchBar = UISearchBar()
    
    // Array to hold friends
    var friends = [PFObject]()
    // Array to hold searched users
    var searchObjects = [PFObject]()
    
    
    // Limit query
    var page: Int = 50
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // If search is not active, and searchBar's text is empty
        if searchActive == false && searchBar.text!.isEmpty {
            // Reload data
            queryFriends()
        }
    }
    
    
    // Query friends
    func queryFriends() {
        // Fetch friends
        let fFriends = PFQuery(className: "FriendMe")
        fFriends.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriends.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriends = PFQuery(className: "FriendMe")
        eFriends.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriends.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriends, fFriends])
        friends.whereKey("isFriends", equalTo: true)
        friends.limit = self.page
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if object["frontFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["endFriend"] as! PFUser)
                    }
                    
                    if object["endFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["frontFriend"] as! PFUser)
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.tableView!.reloadData()
        })

    }
    
    
    // Style title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
//                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Chat With..."
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Query friends
        queryFriends()

        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        
        // Set title
        configureView()
        
        // Tap to dismiss keyboard
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(scrollViewWillBeginDragging))
        swipe.direction = .down
        self.tableView!.isUserInteractionEnabled = true
        self.tableView!.addGestureRecognizer(swipe)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - UISearchBarDelegate Methods
    // Begin searching
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Set bool
        searchActive = true
    }
    
    
    // Look for users
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Search by username
        let name = PFQuery(className: "_User")
        name.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
        let realName = PFQuery(className: "_User")
        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
        let user = PFQuery.orQuery(withSubqueries: [name, realName])
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.searchObjects.append(object)
                }
                
                // Reload data
                self.tableView!.reloadData()
                
            } else {
                print(error?.localizedDescription)
            }
        })
        
        return true
    }
    
    
    
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchActive == true && searchBar.text! != "" {
            return searchObjects.count
        } else {
            return friends.count
        }
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newChatsCell", for: indexPath) as! NewChatsCell
        
        // Declare parent VC
        cell.delegate = self
        
        // layout profile photos
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        cell.rpUserProPic.layoutIfNeeded()
        
        // Layout
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        

        if searchActive == true && searchBar.text! != "" {
            
            // Set user's object
            cell.userObject = searchObjects[indexPath.row]
            
            // Get searchObjects
            searchObjects[indexPath.row].fetchInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    } else {
                        print(error?.localizedDescription)
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                    
                    // (2) Set username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    
                    // (3) Set fullname
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    
                }
            })
            
        } else {
            
            // Set user's object
            cell.userObject = friends[indexPath.row]
            
            // Get user's object
            friends[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    } else {
                        print(error?.localizedDescription)
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                    
                    
                    // (2) Set username
                    cell.rpUsername.text! = object!["username"] as! String
                    
                    // (3) Set fullname
                    cell.rpFullName.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription)
                }
            })
        }

        return cell
    }
    


    // MARK: - UIScrollViewDelegate Method
    
    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Reload data
        queryFriends()
    }
    
    
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= friends.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryFriends()
        }
    }
    
    

}
