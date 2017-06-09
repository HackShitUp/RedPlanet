//
//  Views.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/24/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage
import DZNEmptyDataSet

/*
 UITableViewController class that shows all the people who've viewed a post.
 Works with "ViewsCell.swift" and its respective UITableViewCell in Storyboard.
 */

class Views: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Class configurable variable
    var fetchObject: PFObject?
    
    // Array of users who viewed a post
    var viewObjects = [PFObject]()
    // Array of searched users
    var searchedObjects = [PFObject]()
    
    // PFQuery; Pipeline method
    var page: Int = 50
    // Refresher
    var refresher: UIRefreshControl!
    // Create UISearchBar
    let searchBar = UISearchBar()
    
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // FUNCTION - Reload data
    func refresh() {
        // End UIRefreshControl
        self.refresher.endRefreshing()
        // Query Views
        queryViews(completionHandler: { (Int) in})
    }
    
    // FUNCTION - Query Views
    func queryViews(completionHandler: @escaping (_ count: Int) -> ()) {
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: self.fetchObject!.objectId!)
        views.includeKey("byUser")
        views.order(byDescending: "createdAt")
        views.limit = self.page
        views.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.viewObjects.removeAll(keepingCapacity: false)
                // Append objects
                for object in objects! {
                    self.viewObjects.append(object)
                }
                
                // Pass viewers count in completionHandler
                completionHandler(self.viewObjects.count)
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }

    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.viewObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙈\nNo Views Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPExtensions; whitenBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Track who checked Views
        Heap.track("CheckedViews", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])

        // Query Views
        queryViews(completionHandler: { (count) in
            if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
                let navBarAttributesDictionary: [String: AnyObject]? = [
                    NSForegroundColorAttributeName: UIColor.black,
                    NSFontAttributeName: navBarFont
                ]
                self.navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
                if count == 0 {
                    self.title = "Views"
                } else if count == 1 {
                    self.title = "1 View"
                } else {
                    self.title = "\(count) Views"
                }
            }
            
            // Set DZNEmptyDataSet if posts are 0
            if count == 0 {
                // MARK: - DZNEmptyDataSet
                self.tableView.emptyDataSetSource = self
                self.tableView.emptyDataSetDelegate = self
                self.tableView.reloadEmptyDataSet()
            }
        })
        
        // Configure UISearchBar
        searchBar.delegate = self
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        searchBar.placeholder = "Search"
        tableView.tableHeaderView = self.searchBar
        tableView.tableHeaderView?.layer.borderWidth = 0.5
        tableView.tableHeaderView?.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        tableView.tableHeaderView?.clipsToBounds = true
        
        // Configure UITableView
        self.tableView.rowHeight = 50
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refresher)
        
        // Implement back swipe method
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
                    let users = self.viewObjects.map{$0.object(forKey: "byUser") as! PFUser}
                    if users.contains(where: {$0.objectId! == object.objectId!}) {
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
            return self.viewObjects.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewsCell", for: indexPath) as! ViewsCell
        
        // MARK: - RPExtensions
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // SEARCHED
        if self.searchBar.text! != "" {
            // (1) Get and set user's data
            if let user = self.viewObjects[indexPath.row].object(forKey: "byUser") as? PFUser {
                // Set username
                cell.rpUsername.text = user.username!
                // Get and set userProfilePicture
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - RPExtensions
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
            }
            // (2) Hide screenShotted
            cell.screenShotted.isHidden = true
            
        } else {
        // VIEWED
            // (1) Get and set user's data
            if let user = self.viewObjects[indexPath.row].object(forKey: "byUser") as? PFUser {
                // Set username
                cell.rpUsername.text = user.username!
                // Get and set userProfilePicture
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - RPExtensions
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
            }
            
            // (2) Set didScreenshot icon indicator if screenshotted
            if self.viewObjects[indexPath.row].value(forKey: "didScreenshot") as! Bool == true {
                cell.screenShotted.isHidden = false
            } else {
                cell.screenShotted.isHidden = true
            }
        }
        
        return cell
    }

    
    // MARK: - UITableView Delegate Method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append data
        if let user = self.viewObjects[indexPath.row].object(forKey: "byUser") as? PFUser {
            otherObject.append(user)
            otherName.append(user.username!)
        }
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.viewObjects.count {
                // Increase page size to load more posts
                page = page + 50
                // Query Views
                queryViews(completionHandler: { (count) in})
            }
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Clear searchBar
        self.searchBar.text! = ""
        // Set tableView backgroundView
        self.tableView.backgroundView = UIView()
        // Query Views
        queryViews(completionHandler: { (count) in})
    }
    
}
