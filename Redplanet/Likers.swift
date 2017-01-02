//
//  Likers.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/24/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import SVProgressHUD
import DZNEmptyDataSet


// Array to hold like object
var likeObject = [PFObject]()

class Likers: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UISearchBarDelegate {
    
    
    
    // Array to hold likers
    var likers = [PFObject]()
    
    // Array to hold search
    var searchNames = [String]()
    var searchObjects = [PFObject]()
    
    // Searchbar
    var searchBar = UISearchBar()
    
    // Bool to determine if search is active
    var searchActive: Bool = false
    
    // Set pipeline method
    var page: Int = 50
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Fetch likes
        queryLikes()
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Query Likes
    func queryLikes() {
        
        // Disable searchBar until complete
        self.searchBar.isUserInteractionEnabled = false
        
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: likeObject.last!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.limit = self.page
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likers.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects! {
                    self.likers.append(object["fromUser"] as! PFUser)
                }
                
                
                // DZNEMptyDataSet
                if self.likers.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                // Enable searchBar
                self.searchBar.isUserInteractionEnabled = true
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Enable searchBar
                self.searchBar.isUserInteractionEnabled = true
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }

    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Likers"
        }
    }
    
    
    
    // MARK: DZNEmptyDataSet Framework
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.likers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🦄\nNo Likes Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Set tableView background
        self.tableView.backgroundView = UIView()
        // Reload data
        queryLikes()
    }
    
    
    // MARK: - UISearchBarDelegate methods
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Set boolean
        searchActive = true
    }
    
    // Search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Search by username
        let name = PFUser.query()!
        name.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
        let realName = PFUser.query()!
        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
        let user = PFQuery.orQuery(withSubqueries: [name, realName])
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.searchNames.removeAll(keepingCapacity: false)
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.likers.contains(object) {
                        self.searchNames.append(object["username"] as! String)
                        self.searchObjects.append(object)
                    }
                }

                
                // Reload data
                if self.searchObjects.count != 0 {
                    // Set background for tableView
                    self.tableView!.backgroundView = UIView()
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch likers
        queryLikes()
        
        // Stylize title
        configureView()
        
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        
        
        // Set blank
        self.tableView!.tableFooterView = UIView()
        
        // Show NavigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title again
        configureView()
        
        // Show NavigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchActive == true && searchBar.text != "" {
            
            // Return searched users
            return searchObjects.count
            
        } else {
            
            // Return friends
            return likers.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "likersCell", for: indexPath) as! LikersCell

        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        
        // If Searched
        if searchActive == true && searchBar.text != "" {

            // Fetch users
            searchObjects[indexPath.row].fetchIfNeededInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get and set user's profile photo
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
                    
                    
                    // (2) Set real name
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    
                    // Set result
                    cell.rpUsername.text! = "Couldn't find anyone by that name..."
                }
            }
            
            
        } else {
            // Fetch users
            likers[indexPath.row].fetchIfNeededInBackground {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get and set user's profile photo
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
                    
                    
                    // (2) Set real name
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }

        }
        
        
        return cell
    }
    

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        if searchActive == true && self.searchBar.text! != "" {
            // Append to otherObject
            otherObject.append(self.searchObjects[indexPath.row])
            // Append otherName
            otherName.append(self.searchObjects[indexPath.row].value(forKey: "username") as! String)
            
        } else {
            // Append to otherObject
            otherObject.append(likers[indexPath.row])
            // Append otherName
            otherName.append(likers[indexPath.row].value(forKey: "username") as! String)
            
        }
        
        
        // Push VC
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
        if page <= self.likers.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryLikes()
        }
    }
    
    

}
