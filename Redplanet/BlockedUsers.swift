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
import SimpleAlert
import SVProgressHUD

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
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
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
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
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
        
        // Mark: - SVProgressHUD
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.clear)

        // Fetch blocked users
        fetchBlocked()
        
        // Design table view
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
        
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
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if blockedUsers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "☮\nYou're a peace maker. You haven't blocked anyone yet."
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
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Get users' usernames and user's profile photos
        cell.rpUsername.text! = self.blockedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String
        if let proPic = self.blockedUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
        
        return cell
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: - SimpleAlert
        let alert = AlertController(title: "Unblock?",
                                    message: "Would you like to unblock \(self.blockedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String)?",
            style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
                let textRange = NSMakeRange(0, view.titleLabel.text!.characters.count)
                let attributedText = NSMutableAttributedString(string: view.titleLabel.text!)
                attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: textRange)
                view.titleLabel.attributedText = attributedText
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15.00)
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        let unblock = AlertAction(title: "Unblock",
                                  style: .default,
                                  handler: {(AlertAction) in
                                    // MARK: - SVProgressHUD
                                    SVProgressHUD.show(withStatus: "Unblocking")
                                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
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
                                                        // MARK: - SVProgressHUD
                                                        SVProgressHUD.showSuccess(withStatus: "Unblocked")
                                                        SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
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
        })
        
        let cancel = AlertAction(title: "Cancel",
                                 style: .cancel,
                                 handler: nil)
        
        alert.addAction(cancel)
        alert.addAction(unblock)
        unblock.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        unblock.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
        cancel.button.setTitleColor(UIColor.black, for: .normal)
        self.present(alert, animated: true, completion: nil)
    }
}
