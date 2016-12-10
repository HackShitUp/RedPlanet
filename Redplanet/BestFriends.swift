//
//  BestFriends.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/10/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet
import OneSignal


// Global array to hold best friends
var forBFObject = [PFObject]()

class BestFriends: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // ALGORITHMIC BEST FRIENDS
    // (1) Fetch all the user's messages
    // (2) Count how many the user sent 
    // (3) Find users who received otherUser's messages
    // (4) Fetch receiver's messages
    // (5) Count how many the receiver sent to current
    // (7) If specific numbers are set, then display best friends
    
    // Array to hold the 3 best friends
    var threeBFObjects = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func addBestFriend(_ sender: Any) {
        // Show options
        showOptions()
    }
    
    // Function to Refresh
    func refresh() {
        // Fetch best friends
        fetchBestFriends()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reoad data
        self.tableView!.reloadData()
    }
    
    // HUMAN BEST FRIENDS
    func fetchBestFriends() {
        let bestFriends = PFQuery(className: "BestFriends")
        bestFriends.whereKey("theFriend", equalTo: forBFObject.last!)
        bestFriends.includeKey("firstBF")
        bestFriends.includeKey("secondBF")
        bestFriends.includeKey("thirdBF")
        bestFriends.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.threeBFObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Best Friend One
                    if let bfOne = object["firstBF"] as? PFUser {
                        self.threeBFObjects.append(bfOne)
                    }
                    
                    // Best Friend Two
                    if let bfTwo = object["secondBF"] as? PFUser {
                        self.threeBFObjects.append(bfTwo)
                    }
                    
                    // Best Friend Three
                    if let bfThree = object["thirdBF"] as? PFUser {
                        self.threeBFObjects.append(bfThree)
                    }
                }

                
                // DZNEmptyDataSet
                if self.threeBFObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.tableFooterView = UIView()
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(forBFObject.last!.value(forKey: "username") as! String)'s Best Friends"
        }
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if threeBFObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "☹️\nNo Best Friends Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Looks like \(forBFObject.last!.value(forKey: "realNameOfUser") as! String) doesn't have any best friends yet."
        let font = UIFont(name: "AvenirNext-Medium", size: 17.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Button title
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Add \(forBFObject.last!.value(forKey: "realNameOfUser") as! String) to my Best Friends list."
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Delegate method
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        showOptions()
    }
    
    
    
    // Function to show alert
    func showOptions() {
        // Show alert
        let alert = UIAlertController(title: "Best Friend",
                                      message: "Add \(forBFObject.last!.value(forKey: "realNameOfUser") as! String) as my...",
            preferredStyle: .actionSheet)
        
        let firstBF = UIAlertAction(title: "1st Best Friend 🏆",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        // Check if Current user has best friends
                                        let bf = PFQuery(className: "BestFriends")
                                        bf.whereKey("theFriend", equalTo: PFUser.current()!)
                                        bf.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                
                                                for object in objects! {
                                                    if object["firstBF"] != nil {
                                                        // Show that you already have a best friend
                                                        let alert = UIAlertController(title: "1st Best Friend",
                                                                                      message: "Looks like you already have someone as your 1st Best Friend.",
                                                                                      preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                    } else {
                                                        // Save
                                                        let bf = PFObject(className: "BestFriends")
                                                        bf["theFriend"] = PFUser.current()!
                                                        bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                        bf["firstBF"] = forBFObject.last! as! PFUser
                                                        bf.saveInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                // Refresh
                                                                self.refresh()
                                                                
                                                                let alert = UIAlertController(title: "1st Best Friend",
                                                                                              message: "You've successfully listed \(otherName.last!.uppercased()) as your 1st Best Friend.",
                                                                    preferredStyle: .alert)
                                                                
                                                                let myBF = UIAlertAction(title: "View My List",
                                                                                         style: .default,
                                                                                         handler: {(alertAction: UIAlertAction!) in
                                                                                            // Append
                                                                                            forBFObject.append(PFUser.current()!)
                                                                                            
                                                                                            // Push VC
                                                                                            let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                            self.navigationController?.pushViewController(bfVC, animated: true)
                                                                })
                                                                
                                                                let ok = UIAlertAction(title: "ok",
                                                                                       style: .cancel,
                                                                                       handler: nil)
                                                                
                                                                alert.addAction(myBF)
                                                                alert.addAction(ok)
                                                                alert.view.tintColor = UIColor.black
                                                                self.present(alert, animated: true, completion: nil)
                                                                
                                                            } else{
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                }
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                
                                                print("NOT FOUND")
                                                // Save
                                                let bf = PFObject(className: "BestFriends")
                                                bf["theFriend"] = PFUser.current()!
                                                bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                bf["firstBF"] = forBFObject.last! as! PFUser
                                                bf.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        // Refresh
                                                        self.refresh()
                                                        
                                                        let alert = UIAlertController(title: "1st Best Friend",
                                                                                      message: "You've successfully listed \(otherName.last!.uppercased()) as your 1st Best Friend.",
                                                            preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                        
                                                    } else{
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })

                                            }
                                        })
        })
        
        let secondBF = UIAlertAction(title: "2nd Best Friend 🏅",
                                     style: .default,
                                     handler: {(alertAction: UIAlertAction!) in
                                        // Check if Current user has best friends
                                        let bf = PFQuery(className: "BestFriends")
                                        bf.whereKey("theFriend", equalTo: PFUser.current()!)
                                        bf.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    if object["secondBF"] != nil {
                                                        // Show that you already have a best friend
                                                        let alert = UIAlertController(title: "2nd Best Friend",
                                                                                      message: "Looks like you already have someone as your 2nd Best Friend.",
                                                                                      preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                    } else {
                                                        // Save
                                                        let bf = PFObject(className: "BestFriends")
                                                        bf["theFriend"] = PFUser.current()!
                                                        bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                        bf["secondBF"] = forBFObject.last! as! PFUser
                                                        bf.saveInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                // Refresh
                                                                self.refresh()
                                                                
                                                                let alert = UIAlertController(title: "2nd Best Friend",
                                                                                              message: "You've successfully listed \(otherName.last!.uppercased()) as your 2nd Best Friend.",
                                                                    preferredStyle: .alert)
                                                                
                                                                let myBF = UIAlertAction(title: "View My List",
                                                                                         style: .default,
                                                                                         handler: {(alertAction: UIAlertAction!) in
                                                                                            // Append
                                                                                            forBFObject.append(PFUser.current()!)
                                                                                            
                                                                                            // Push VC
                                                                                            let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                            self.navigationController?.pushViewController(bfVC, animated: true)
                                                                })
                                                                
                                                                let ok = UIAlertAction(title: "ok",
                                                                                       style: .cancel,
                                                                                       handler: nil)
                                                                
                                                                alert.addAction(myBF)
                                                                alert.addAction(ok)
                                                                alert.view.tintColor = UIColor.black
                                                                self.present(alert, animated: true, completion: nil)
                                                                
                                                            } else{
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                }
                                               
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                
                                                // Save
                                                let bf = PFObject(className: "BestFriends")
                                                bf["theFriend"] = PFUser.current()!
                                                bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                bf["secondBF"] = forBFObject.last! as! PFUser
                                                bf.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        // Refresh
                                                        self.refresh()
                                                        
                                                        let alert = UIAlertController(title: "2nd Best Friend",
                                                                                      message: "You've successfully listed \(otherName.last!.uppercased()) as your 2nd Best Friend.",
                                                            preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                        
                                                    } else{
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                            }
                                        })

        })
        
        let thirdBF = UIAlertAction(title: "3rd Best Friend 🔥",
                                    style: .default,
                                    handler: {(alertAction: UIAlertAction!) in
                                        // Check if Current user has best friends
                                        let bf = PFQuery(className: "BestFriends")
                                        bf.whereKey("theFriend", equalTo: PFUser.current()!)
                                        bf.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    if object["thirdBF"] != nil {
                                                        // Show that you already have a best friend
                                                        let alert = UIAlertController(title: "3rd Best Friend",
                                                                                      message: "Looks like you already have someone as your 3rd Best Friend.",
                                                                                      preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                    } else {
                                                        // Save
                                                        let bf = PFObject(className: "BestFriends")
                                                        bf["theFriend"] = PFUser.current()!
                                                        bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                        bf["thirdBF"] = forBFObject.last! as! PFUser
                                                        bf.saveInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                // Refresh
                                                                self.refresh()
                                                                
                                                                let alert = UIAlertController(title: "3rd Best Friend",
                                                                                              message: "You've successfully listed \(otherName.last!.uppercased()) as your 3rd Best Friend.",
                                                                    preferredStyle: .alert)
                                                                
                                                                let myBF = UIAlertAction(title: "View My List",
                                                                                         style: .default,
                                                                                         handler: {(alertAction: UIAlertAction!) in
                                                                                            // Append
                                                                                            forBFObject.append(PFUser.current()!)
                                                                                            
                                                                                            // Push VC
                                                                                            let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                            self.navigationController?.pushViewController(bfVC, animated: true)
                                                                })
                                                                
                                                                let ok = UIAlertAction(title: "ok",
                                                                                       style: .cancel,
                                                                                       handler: nil)
                                                                
                                                                alert.addAction(myBF)
                                                                alert.addAction(ok)
                                                                alert.view.tintColor = UIColor.black
                                                                self.present(alert, animated: true, completion: nil)
                                                                
                                                            } else{
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                }

                                            } else {
                                                print(error?.localizedDescription as Any)
                                                
                                                print("NOT FOUND")
                                                // Save
                                                let bf = PFObject(className: "BestFriends")
                                                bf["theFriend"] = PFUser.current()!
                                                bf["theFriendName"] = PFUser.current()!.username!.uppercased()
                                                bf["thirdBF"] = forBFObject.last! as! PFUser
                                                bf.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        // Refresh
                                                        self.refresh()
                                                        
                                                        let alert = UIAlertController(title: "3rd Best Friend",
                                                                                      message: "You've successfully listed \(otherName.last!.uppercased()) as your 3rd Best Friend.",
                                                            preferredStyle: .alert)
                                                        
                                                        let myBF = UIAlertAction(title: "View My Best Friends",
                                                                                 style: .default,
                                                                                 handler: {(alertAction: UIAlertAction!) in
                                                                                    // Append
                                                                                    forBFObject.append(PFUser.current()!)
                                                                                    
                                                                                    // Push VC
                                                                                    let bfVC = self.storyboard?.instantiateViewController(withIdentifier: "bfVC") as! BestFriends
                                                                                    self.navigationController?.pushViewController(bfVC, animated: true)
                                                        })
                                                        
                                                        let ok = UIAlertAction(title: "ok",
                                                                               style: .cancel,
                                                                               handler: nil)
                                                        
                                                        alert.addAction(myBF)
                                                        alert.addAction(ok)
                                                        alert.view.tintColor = UIColor.black
                                                        self.present(alert, animated: true, completion: nil)
                                                        
                                                        
                                                    } else{
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                            }
                                        })
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addAction(firstBF)
        alert.addAction(secondBF)
        alert.addAction(thirdBF)
        alert.addAction(cancel)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 60
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Pull to refresh
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)

        // Fetch best friends
        fetchBestFriends()
        
        // Stylize navigationbar title
        configureView()
        
        // Clean tableView if there's no data
        self.tableView.tableFooterView = UIView()
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
        return self.threeBFObjects.count
    }
    
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bfCell", for: indexPath) as! BestFriendsCell

        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // Set parent VC
        cell.delegate = self
        
        
        
        if indexPath.row == 0 {
            // Get user's objects
            if let bfOne = threeBFObjects[0] as? PFUser {
                // (A) Set username
                cell.rpName.text! = "1st 🏆: \(bfOne["username"] as! String)"
                
                // (B) Get profile photo
                if let proPic = bfOne["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // (B1) Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // (B2) Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                // (C) Set bio
                if let bio = bfOne["userBiography"] as? String {
                    cell.rpBio.text! = "\(bfOne["realNameOfUser"] as! String)\n\(bio)"
                } else {
                    cell.rpBio.text! = "\(bfOne["realNameOfUser"] as! String)"
                }
                
                // (D) Set user's object
                cell.userObject = bfOne
            }
        }

        
        
        if indexPath.row == 1 {
            if let bfTwo = threeBFObjects[1] as? PFUser {
                // (A) Set username
                cell.rpName.text! = "2nd 🏅: \(bfTwo["username"] as! String)"
                
                
                // (B) Get profile photo
                if let proPic = bfTwo["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // (B1) Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // (B2) Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                // (C) Set bio
                if let bio = bfTwo["userBiography"] as? String {
                    cell.rpBio.text! = "\(bfTwo["realNameOfUser"] as! String)\n\(bio)"
                } else {
                    cell.rpBio.text! = "\(bfTwo["realNameOfUser"] as! String)"
                }
                
                // (D) Set user's object
                cell.userObject = bfTwo
            }
        }
        
        
        
        if indexPath.row == 2 {
            if let bfThree = threeBFObjects[2] as? PFUser {
                // (A) Set username
                cell.rpName.text! = "3rd 🔥: \(bfThree["username"] as! String)"
                
                
                // (B) Get profile photo
                if let proPic = bfThree["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // (B1) Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // (B2) Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                // (C) Set bio
                if let bio = bfThree["userBiography"] as? String {
                    cell.rpBio.text! = "\(bfThree["realNameOfUser"] as! String)\n\(bio)"
                } else {
                    cell.rpBio.text! = "\(bfThree["realNameOfUser"] as! String)"
                }
                
                // (D) Set user's object
                cell.userObject = bfThree
            }

        }
        
        return cell
    } // end cellForRowAt
    
    
    
    
    // MARK: - UITableViewDelegate Method
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // (1) Delete Text Post
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Remove") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            
                                            
                                            // Remove user
                                            let bf = PFQuery(className: "BestFriends")

                                            if indexPath.row == 0 {
                                                bf.whereKey("firstBF", equalTo: PFUser.current()!)
                                            }
                                            
                                            if indexPath.row == 1 {
                                                bf.whereKey("secondBF", equalTo: PFUser.current()!)
                                            }
                                            
                                            if indexPath.row == 2 {
                                                bf.whereKey("thirdBF", equalTo: PFUser.current()!)
                                            }
                                            
                                            bf.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        // Delete object
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted object: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                                // Delete
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                    
                                                    // Dismiss
                                                    SVProgressHUD.dismiss()
                                                }
                                            })
                                            
        }

        
        
        // Set background colors
        
        // Light Red
        delete.backgroundColor = UIColor(red:1.00, green:0.29, blue:0.29, alpha:1.0)
        
        if threeBFObjects[indexPath.row] as! PFUser == PFUser.current()! || forBFObject.last! as! PFUser == PFUser.current()! {
            return [delete]
        } else {
            return nil
        }

    } // End edit action

    

}
