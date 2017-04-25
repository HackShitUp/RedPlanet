//
//  Views.swift
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

import SDWebImage
import SVProgressHUD
import DZNEmptyDataSet


// Array to hold views
var viewsObject = [PFObject]()

class Views: UITableViewController, UIGestureRecognizerDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var delegate: RCMantleViewDelegate!
    
    // Array to hold objects
    var viewers = [PFObject]()
    
    // Set pipeline method
    var page: Int = 50
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last array
        viewsObject.removeLast()
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Query views
        queryViews()
        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to load more
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.viewers.count {
            // Increase page size to load more posts
            page = page + 50
            // Query friends
            queryViews()
        }
    }
    
    // Query views
    func queryViews() {
        // MARK: - MainUITab
        // Hide button
        rpButton.isHidden = true
        
        // Configure nav bar && show tab bar (last line)        
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Query Views
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: viewsObject.last!.objectId!)
        views.includeKey("byUser")
        views.order(byDescending: "createdAt")
        views.limit = self.page
        views.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
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
                
                // Set DZNEmptyDataSet
                if self.viewers.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                
                // Change the font and size of nav bar text
                if self.viewers.count != 0 && self.navigationController != nil {
                    if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.00) {
                        let navBarAttributesDictionary: [String: AnyObject]? = [
                            NSForegroundColorAttributeName: UIColor.black,
                            NSFontAttributeName: navBarFont
                        ]
                        self.navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
                        if self.viewers.count == 0 {
                            self.title = "Views"
                        } else if self.viewers.count == 1 {
                            self.title = "1 View"
                        } else {
                            self.title = "\(self.viewers.count) Views"
                        }
                    }
                    
                } else {
                    if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.00) {
                        let navBarAttributesDictionary: [String: AnyObject]? = [
                            NSForegroundColorAttributeName: UIColor.black,
                            NSFontAttributeName: navBarFont
                        ]
                        self.navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
                        self.title = "Views"
                    }
                }

            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.viewers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙈\nNo Views Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show NavigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidAppear(_  animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show NavigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - UIGestureRecognizer Delegate Methods
    func tapDismiss(sender: UITapGestureRecognizer){
//        delegate.dismissView(true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == self.view {
            return false
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapDismiss))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        
        // MARK: - HEAP
        // Track who viewed views
        Heap.track("ViewedViews", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Query views & configure title
        queryViews()
        
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Extend layouts
        self.extendedLayoutIncludesOpaqueBars = true
        
        // Set tablefooter view
        self.tableView.backgroundColor = UIColor.white
        self.tableView!.tableFooterView = UIView()
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Show NavigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - MainUITab
        // Show button
        rpButton.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.viewers.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Fetch user's realNameOfUser and user's profile photos
        cell.rpUsername.text! = self.viewers[indexPath.row].value(forKey: "realNameOfUser") as! String
        if let proPic = self.viewers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }

        return cell
    }

    // MARK: - UITableview delegate method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append user's object
        otherObject.append(self.viewers[indexPath.row])
        // Append user's username
        otherName.append(self.viewers[indexPath.row].value(forKey: "username") as! String)
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.navigationController?.pushViewController(otherVC, animated: true)
    }

    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
}
