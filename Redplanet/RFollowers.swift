//
//  RFollowers.swift
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

import SDWebImage
import SVProgressHUD
import DZNEmptyDataSet


// Array to hold who's followers to fetch
var forFollowers = [PFObject]()

class RFollowers: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UISearchBarDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    
    // Variable to hold followers
    var followers = [PFObject]()
    // Array to hold search objects
    var searchObjects = [PFObject]()
    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    // Search Bar
    var searchBar = UISearchBar()
    
    // Set limit
    var page: Int = 50
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Remove last value in the array
        forFollowers.removeLast()
        
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Reload data
        queryFollowers()
    }
    
    // Query Followers
    func queryFollowers() {
        // Fetch blocked
        _ = appDelegate.queryRelationships()
        
        let followers = PFQuery(className: "FollowMe")
        followers.whereKey("isFollowing", equalTo: true)
        followers.whereKey("following", equalTo: forFollowers.last!)
        followers.includeKey("follower")
        followers.limit = self.page
        followers.order(byDescending: "createdAt")
        followers.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.followers.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "follower") as! PFUser).objectId!}) {
                        self.followers.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
                
                // DZNEmptyDataSet
                if self.followers.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.tableFooterView = UIView()
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            
            // Reload data
            self.tableView!.reloadData()
        })
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
            self.title = "\(forFollowers.last!.value(forKey: "realNameOfUser") as! String)'s Followers"
        }
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if followers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nNo Followers"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    // Button title
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Find People To Follow"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Show search
        let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController!.pushViewController(search, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()

        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Query followers
        queryFollowers()

        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        // Design tableView
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
        self.tableView?.tableHeaderView = self.searchBar
        self.tableView?.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView?.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        self.tableView?.tableHeaderView?.clipsToBounds = true
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Stylize title
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Clear searchBar
        self.searchBar.text! = ""
        // Set tableView backgroundView
        self.tableView.backgroundView = UIView()
        // Reload data
        queryFollowers()
    }
    
    // MARK: - UISearchBarDelegate methods
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Set boolean
        searchActive = true
        
        if searchBar.text == "Search" {
            searchBar.text! = ""
        } else {
            searchBar.text! = searchBar.text!
        }
    }
    
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
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.followers.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchObjects.append(object)
                    }
                }
                
                // Reload data
                if self.searchObjects.count != 0 {
                    // Reload data
                    self.tableView!.backgroundView = UIView()
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


    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive == true && searchBar.text! != "" {
            return self.searchObjects.count
        } else {
            return self.followers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // SEARCHED
        if self.searchActive == true && self.searchBar.text! != "" {
            // Get users' usernames and user's profile photos
            cell.rpUsername.text! = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
        } else {
        // FOLLOWERS
            // Sort Followers in ABC order
            let abcFollowers = self.followers.sorted{($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
            
            // Get users' usernames and user's profile photos
            cell.rpUsername.text! = abcFollowers[indexPath.row].value(forKey: "realNameOfUser") as! String
            if let proPic = abcFollowers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
        }
        
        return cell
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.searchActive == true && self.searchBar.text! != "" {
            // Append to otherObject
            otherObject.append(self.searchObjects[indexPath.row])
            // Append otherName
            otherName.append(self.searchObjects[indexPath.row].value(forKey: "username") as! String)
        } else {
        // FOLLOWERS
            // Sort Followers in ABC order
            let abcFollowers = self.followers.sorted{($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
            // Append to otherObject
            otherObject.append(abcFollowers[indexPath.row])
            // Append otherName
            otherName.append(abcFollowers[indexPath.row].value(forKey: "username") as! String)
        }
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
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
        if page <= self.followers.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryFollowers()
        }
    }

}
