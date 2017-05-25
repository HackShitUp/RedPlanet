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

class Views: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Class configurable variable
    var fetchObject: PFObject?
    var viewsOrLikes: String?
    
    // Array of users who viewed a post
    var viewers = [PFObject]()
    // Array of users who liked a comment
    var likers = [PFObject]()
    // PFQuery; Pipeline method
    var page: Int = 50
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // FUNCTION - Reload data
    func refresh() {
        if self.viewsOrLikes == "Views" {
            queryViews(completionHandler: { (Int) in})
        } else {
            queryLikes()
        }
    }
    
    // FUNCTION - Query Likes
    func queryLikes() {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: self.fetchObject!.objectId!)
        likes.includeKeys(["byUser", "fromUser"])
        likes.order(byDescending: "createdAt")
        likes.limit = self.page
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likers.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.likers.append(object.object(forKey: "fromUser") as! PFUser)
                }
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - Query Views
    func queryViews(completionHandler: @escaping (_ count: Int) -> ()) {
        // TOOD:: UPDATE QUERY KEYS AFTER DATABASE is re-configured
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: self.fetchObject!.objectId!)
        views.includeKey("byUser")
        views.order(byDescending: "createdAt")
        views.limit = self.page
        views.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.viewers.removeAll(keepingCapacity: false)
                // Append objects
                for object in objects! {
                    if self.viewers.contains(where: {$0.objectId! == (object.object(forKey: "byUser") as! PFUser).objectId!}) || (object.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        // Skip appending
                    } else {
                        self.viewers.append(object.object(forKey: "byUser") as! PFUser)
                    }
                }
                
                // Pass viewers count in completionHandler
                completionHandler(self.viewers.count)
                
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
        if self.viewers.count == 0 || self.likers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙈\nNo \(self.viewsOrLikes!) Yet"
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
        // MARK: - RPExtensions; whitenBar and roundTopCorners
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.view.roundTopCorners(sender: self.navigationController?.view)
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        
        
        if self.viewsOrLikes! == "Views" {
        // Query Views
            queryViews(completionHandler: { (count) in
                if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17) {
                    let navBarAttributesDictionary: [String: AnyObject]? = [
                        NSForegroundColorAttributeName: UIColor.black,
                        NSFontAttributeName: navBarFont
                    ]
                    self.navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
                    self.title = "\(count) Views"
                }
            })
        } else {
        // Query Likes
            queryLikes()
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // MARK: - DZNEmptyDataSet
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
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

    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewsCell", for: indexPath) as! ViewsCell
        // (1) Set username
        cell.rpUsername.text = (self.viewers[indexPath.row].value(forKey: "username") as! String)
        // (2) Get and set userProfilePicture
        if let proPic = self.viewers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - RPExtensions
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
            // MARK: - RPExtensions
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        }
        return cell
    }

    
    // MARK: - UITableView Delegate Method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append user's object and username
        otherObject.append(self.viewers[indexPath.row])
        otherName.append(self.viewers[indexPath.row].value(forKey: "username") as! String)
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.viewers.count {
                // Increase page size to load more posts
                page = page + 50
                if self.viewsOrLikes == "Views" {
                    // Query Views
                    queryViews(completionHandler: { (count) in})
                } else {
                    // Query Likes
                    queryLikes()
                }
            }
        }
    }
    
    
}
