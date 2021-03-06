//
//  BlockedUsers.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/10/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import SDWebImage

/*
 UITableViewController class that shows all the users the current user has blocked. This class refers to the "Blocked" class in the
 database, and binds the data in its UITableViewCell. 
 
 Works with "UserCell.swift" and "UserCell.xib" to bind the data in this class.
 */

class BlockedUsers: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var blockedUsers = [PFObject]()
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.fetchBlocked()
        self.tableView!.reloadData()
    }
    
    // Function to fetch blocked users
    func fetchBlocked() {
        let blocked = PFQuery(className: "Blocked")
        blocked.whereKey("byUser", equalTo: PFUser.current()!)
        blocked.includeKey("toUser")
        blocked.order(byDescending: "createdAt")
        blocked.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.blockedUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.blockedUsers.append(object.object(forKey: "toUser") as! PFUser)
                }
                
                // DZNEmptyDataSet
                if self.blockedUsers.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.tableFooterView = UIView()
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Blocked Users"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()

        // Fetch blocked users
        fetchBlocked()
        
        // Configure UITableView
        tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        tableView.tableFooterView = UIView()
        // Register NIB
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        fetchBlocked()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if blockedUsers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Stickers")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You're a peace maker. You haven't blocked anyone yet."
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.blockedUsers.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Set realNameOfUser
        cell.rpFullName.text! = self.blockedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String
        // (2) Set username
        cell.rpUsername.text! = self.blockedUsers[indexPath.row].value(forKey: "username") as! String
        // (3) Get and set userProfilePicture
        if let proPic = self.blockedUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_showActivityIndicatorView()
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        return cell
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Unblock?",
                                                      message: "Would you like to unblock \(self.blockedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String)?")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        // Add Delete button
        dialogController.addAction(AZDialogAction(title: "Unblock", handler: { (dialog) -> (Void) in
            // dismiss
            dialog.dismiss()
            
            // Remove
            let blocked = PFQuery(className: "Blocked")
            blocked.whereKey("byUser", equalTo: PFUser.current()!)
            blocked.whereKey("toUser", equalTo: self.blockedUsers[indexPath.row])
            blocked.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground(block: {
                            (success: Bool, error: Error?) in
                            if error == nil {
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showSuccess(withTitle: "Unblocked!")
                                
                                // Reload data
                                self.refresh(sender: self)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })

            
        }))
        
        dialogController.show(in: self)
    }
}
