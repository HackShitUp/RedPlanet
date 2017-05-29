//
//  Likes.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage
import DZNEmptyDataSet

class Likes: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Class configurable variable
    var fetchObject: PFObject?
    
    // Array of users who viewed a post
    var likeObjects = [PFObject]()
    // PFQuery; Pipeline method
    var page: Int = 50
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.refresher.endRefreshing()
        self.fetchLikes(completionHandler: { (Int) in})
    }

    // FUNCTION - Fetch Likes
    func fetchLikes(completionHandler: @escaping (_ count: Int) -> ()) {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: self.fetchObject!.objectId!)
        likes.order(byDescending: "createdAt")
        likes.includeKey("fromUser")
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.likeObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if let user = object.object(forKey: "fromUser") as? PFUser {
                        self.likeObjects.append(user)
                    }
                }
                
                // MARK: - DZNEmptyDataSet
                if self.likeObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }

    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.likeObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💔\nNo likes for this comment yet."
        let font = UIFont(name: "AvenirNext-Medium", size: 25)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch likes
        fetchLikes(completionHandler: { (count) in
            // Set DZNEmptyDataSet if posts are 0
            if count == 0 {
                // MARK: - DZNEmptyDataSet
                self.tableView.emptyDataSetSource = self
                self.tableView.emptyDataSetDelegate = self
                self.tableView.reloadEmptyDataSet()
            }
        })
        
        // Configure UITableView
        self.tableView.rowHeight = 50
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        // Register NIB
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")

        
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
        return self.likeObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        // (1) Set realNameOfUser
        if let fullName = self.likeObjects[indexPath.row].value(forKey: "realNameOfUser") as? String {
            cell.rpFullName.text = fullName
        }
        // (2) Set username
        if let username = self.likeObjects[indexPath.row].value(forKey: "username") as? String {
            cell.rpUsername.text = username
        }
        // (3) Get and set userProfilePicture
        if let proPic = self.likeObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: -SDWebImage
            cell.rpUserProPic.sd_addActivityIndicator()
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
            // MARK: - RPExtensions
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        }
        return cell
    }
    
    // MARK: - UITableView Delegate Method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append user's object and username
        otherObject.append(self.likeObjects[indexPath.row])
        otherName.append(self.likeObjects[indexPath.row].value(forKey: "username") as! String)
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.likeObjects.count {
                // Increase page size to load more posts
                page = page + 50
                // Fetch likes
                self.fetchLikes(completionHandler: { (Int) in})
            }
        }
    }
    
}
