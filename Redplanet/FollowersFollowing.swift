//
//  FollowersFollowing.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Parse
import ParseUI
import Bolts
import SDWebImage
import DZNEmptyDataSet

// Array to get followers|following for user
var relationForUser = [PFObject]()

class FollowersFollowing: UITableViewController, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // MARK: - Class Variable; Determine whether to fetch followers or following
    var followersFollowing: String?
    
    // Array to hold users
    var userObjects = [PFObject]()
    // Array to hold searched-users
    var searchedObjects = [PFObject]()
    
    // UISearchBar
    var searchBar = UISearchBar()
    // AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // Pipeline Method
    var page: Int = 50
    // UIRefreshControl
    var refresher: UIRefreshControl!
    
    @IBAction func back(_ sender: Any) {
        // Deallocate array and variable
        relationForUser.removeAll(keepingCapacity: false)
        followersFollowing = ""
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.refresher.endRefreshing()
        // Handle fetch
        handleFetch()
    }
    
    // Fetch Followers
    func fetchFollowers() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        // Fetch Followers
        let followers = PFQuery(className: "FollowMe")
        followers.whereKey("isFollowing", equalTo: true)
        followers.whereKey("following", equalTo: relationForUser.last!)
        followers.includeKeys(["following", "follower"])
        followers.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.userObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "follower") as! PFUser).objectId!}) {
                        self.userObjects.append(object.object(forKey: "follower") as! PFUser)
                    }
                }
                
                // MARK: - DZNEmptyDataSet
                if self.userObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload Data
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // Fetch Following
    func fetchFollowing() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        // Fetch Following
        let following = PFQuery(className: "FollowMe")
        following.whereKey("isFollowing", equalTo: true)
        following.whereKey("follower", equalTo: relationForUser.last!)
        following.includeKeys(["following", "follower"])
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.userObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "follower") as! PFUser).objectId!}) {
                        self.userObjects.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
                // MARK: - DZNEmptyDataSet
                if self.userObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload Data
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // Function to handle which relation to fetch
    func handleFetch() {
        // Fetch Followers or Following depending on variable, followersFollowing
        if self.followersFollowing == "Followers" {
            fetchFollowers()
        } else if self.followersFollowing == "Following" {
            fetchFollowing()
        }
    }
    

    // Configure UINavigationBar
    func configureView(title: String?) {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(relationForUser.last!.value(forKey: "realNameOfUser") as! String)'s \(title!)"
        }
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.view.roundAllCorners(sender: self.navigationController?.view)
    }
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if userObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nNo \(self.followersFollowing!)"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let str = "Find People To Follow"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        let search = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController!.pushViewController(search, animated: true)
    }
    

    
    // MARK: - UIViewController Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch Followers or Following depending on variable, followersFollowing
        handleFetch()
        // Configure view
        configureView(title: self.followersFollowing)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UITableView
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView.tableFooterView = UIView()
        
        // Configure UISearchBar
        searchBar.delegate = self
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        searchBar.placeholder = "Search"
        tableView.tableHeaderView = self.searchBar
        tableView.tableHeaderView?.layer.borderWidth = 0.5
        tableView.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        tableView.tableHeaderView?.clipsToBounds = true
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refresher)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UISearchBar Delegate Methods
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Configure UISearchBar
        if searchBar.text == "Search" {
            searchBar.text! = ""
        } else {
            searchBar.text! = searchBar.text!
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Search by fullName and username
        let name = PFUser.query()!
        name.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
        let realName = PFUser.query()!
        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
        let user = PFQuery.orQuery(withSubqueries: [name, realName])
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.searchedObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if self.userObjects.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchedObjects.append(object)
                    }
                }
                
                // Reload data
                if self.searchedObjects.count != 0 {
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


    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchBar.text! != "" {
            return self.searchedObjects.count
        } else {
            return self.userObjects.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell

        // MARK: - RPExtensions
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // SEARCHED
        if self.searchBar.text! != "" {
            // Get users' usernames
            cell.rpUsername.text! = self.searchedObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            // Set and get user's profile photo
            if let proPic = self.searchedObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        } else {
        // FOLLOWERS || FOLLOWING
            // Sort followers or following in ABC order
            let abcUsers = self.userObjects.sorted {($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
            // Set users' usernames
            cell.rpUsername.text! = abcUsers[indexPath.row].value(forKey: "realNameOfUser") as! String
            // Get user's profile photo
            if let proPic = abcUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        }

        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.searchBar.text! != "" {
            // Append to otherObject
            otherObject.append(self.searchedObjects[indexPath.row])
            // Append otherName
            otherName.append(self.searchedObjects[indexPath.row].value(forKey: "username") as! String)
        } else {
            // FOLLOWERS
            // Sort Followers in ABC order
            let abcUsers = self.userObjects.sorted{($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
            // Append to otherObject
            otherObject.append(abcUsers[indexPath.row])
            // Append otherName
            otherName.append(abcUsers[indexPath.row].value(forKey: "username") as! String)
        }
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Clear searchBar
        self.searchBar.text! = ""
        // Set tableView backgroundView
        self.tableView.backgroundView = UIView()
        // Reload data
        handleFetch()
    }
    
    override func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            func loadMore() {
                // If posts on server are > than shown
                if page <= self.userObjects.count {
                    // Increase page size to load more posts
                    page = page + 50
                    // Query friends
                    handleFetch()
                }
            }
        }
    }
    
    
    
}
