//
//  ShareTo.swift
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


import OneSignal
import SVProgressHUD
import DZNEmptyDataSet


class ShareTo: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    
    // Array to hold friends
    var friends = [PFObject]()
    
    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    
    // Array to hold search objects
    var searchObjects = [PFObject]()
    var searchNames = [String]()
    
    // Search Bar
    var searchBar = UISearchBar()
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reset Bool
        searchActive = true
        
        // query friends
        queryFriends()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Query Friends
    func queryFriends() {

        let fFriend = PFQuery(className: "FriendMe")
        fFriend.whereKey("endFriend", equalTo: PFUser.current()!)
        fFriend.whereKey("frontFriend", notEqualTo: PFUser.current()!)
        
        let eFriend = PFQuery(className: "FriendMe")
        eFriend.whereKey("frontFriend", equalTo: PFUser.current()!)
        eFriend.whereKey("endFriend", notEqualTo: PFUser.current()!)
        
        
        let friends = PFQuery.orQuery(withSubqueries: [eFriend, fFriend])
        friends.whereKey("isFriends", equalTo: true)
        friends.order(byDescending: "createdAt")
        friends.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    if object["endFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["frontFriend"] as! PFUser)
                    }
                    
                    if object["frontFriend"] as! PFUser == PFUser.current()! {
                        self.friends.append(object["endFriend"] as! PFUser)
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    
    
    
    
    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Reload data
        queryFriends()
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
    
    
    
    
    // Begin searching
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Search by username
        let name = PFQuery(className: "_User")
        name.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
        let realName = PFQuery(className: "_User")
        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
        let user = PFQuery.orQuery(withSubqueries: [name, realName])
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.searchNames.removeAll(keepingCapacity: false)
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.searchNames.append(object["username"] as! String)
                    self.searchObjects.append(object)
                }
                
                // Reload data
                self.tableView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        return true
        
    }
    
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)'s Friends"
        }
    }
    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)

        // Fetch friends
        queryFriends()
        
        // Stylize title
        configureView()
        
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        
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
        if searchActive == true && searchBar.text! != "" {
            return self.searchObjects.count
        } else {
            return self.friends.count
        }
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "shareToCell", for: indexPath) as! ShareToCell
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // Return SEARCH
        if searchActive == true && searchBar.text! != "" {
            // Return searchObjects
            self.searchObjects[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // set user's profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    // (2) Set user's name
                    cell.rpUsername.text! = self.searchNames[indexPath.row]
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            
            // Return FRIENDS
            friends[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // (1) Get user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set user's profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    }
                    
                    // (2) Set user's full name
                    cell.rpUsername.text! = object!["realNameOfUser"] as! String
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        }

        return cell
    }
    
    
    
    
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        // Variabel to hold username and user's object
        var userName: String?
        var shareUserObject: PFObject?
        
        if searchActive == true && searchBar.text! != "" {
            // Append search object
            userName = self.searchNames[indexPath.row]
            shareUserObject = self.searchObjects[indexPath.row]
        } else {
            // Append Friends
            userName = self.friends[indexPath.row].value(forKey: "realNameOfUser") as? String
            shareUserObject = self.friends[indexPath.row]
        }
        
        
        let alert = UIAlertController(title: "Share With \(userName!.uppercased())?",
            message: "Are you sure you'd like to share this with \(userName!.uppercased())?",
            preferredStyle: .alert)
        
        let yes = UIAlertAction(title: "yes",
                                style: .default,
                                handler: {(alertAction: UIAlertAction!) in
                                    
                                    if shareObject.last!.value(forKey: "photoAsset") != nil {
                                        // PHOTO
                                        // Share with user
                                        // Send to Chats
                                        let chats = PFObject(className: "Chats")
                                        chats["sender"] = PFUser.current()!
                                        chats["receiver"] = shareUserObject!
                                        chats["senderUsername"] = PFUser.current()!.username!
                                        chats["receiverUsername"] = shareUserObject!.value(forKey: "username") as! String
                                        chats["read"] = false
                                        chats["photoAsset"] = shareObject.last!.value(forKey: "photoAsset") as! PFFile
                                        chats.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if error == nil {
                                                print("Successfully saved chat: \(chats)")
                                                
                                                let alert = UIAlertController(title: "Shared ✓",
                                                                             message: "Successfully shared photo to \(userName!.uppercased()).",
                                                    preferredStyle: .alert)
                                                
                                                let ok = UIAlertAction(title: "ok",
                                                                       style: .default,
                                                                       handler: {(alertAction: UIAlertAction!) in
                                                                        
                                                                        // MARK: - OneSignal
                                                                        // Send Push Notification
                                                                        OneSignal.postNotification(
                                                                            ["contents":
                                                                                ["en": "\(PFUser.current()!.username!.uppercased()) shared a photo with you"],
                                                                             "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"]
                                                                            ]
                                                                        )
                                                                        
                                                                        
                                                                        // Pop view controller
                                                                        self.navigationController?.popViewController(animated: true)
                                                })
                                                
                                                alert.addAction(ok)
                                                alert.view.tintColor = UIColor.black
                                                self.present(alert, animated: true, completion: nil)
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        
                                        
                                    } else if shareObject.last!.value(forKey: "videoAsset") != nil {
                                        
                                        // VIDEO
                                        // Share with user
                                        // Send to Chats
                                        let chats = PFObject(className: "Chats")
                                        chats["sender"] = PFUser.current()!
                                        chats["senderUsername"] =  PFUser.current()!.username!
                                        chats["receiver"] = shareUserObject!
                                        chats["receiverUsername"] = shareUserObject?.value(forKey: "username") as! String
                                        chats["read"] = false
                                        chats["videoAsset"] = shareObject.last!.value(forKey: "videoAsset") as! PFFile
                                        chats.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully saved chat: \(chats)")
                                                
                                                let alert = UIAlertController(title: "Shared ✓",
                                                                              message: "Successfully shared video to \(userName!.uppercased()).",
                                                    preferredStyle: .alert)
                                                
                                                let ok = UIAlertAction(title: "ok",
                                                                       style: .default,
                                                                       handler: {(alertAction: UIAlertAction!) in
                                                                        
                                                                        // MARK: - OneSignal
                                                                        // Send Push Notification
                                                                        OneSignal.postNotification(
                                                                            ["contents":
                                                                                ["en": "\(PFUser.current()!.username!.uppercased()) shared a video with you"],
                                                                             "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"]
                                                                            ]
                                                                        )
                                                                        
                                                                        // Pop view controller
                                                                        self.navigationController?.popViewController(animated: true)
                                                })
                                                
                                                alert.addAction(ok)
                                                alert.view.tintColor = UIColor.black
                                                self.present(alert, animated: true, completion: nil)
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        
                                        
                                    } else {
                                        // Text Post
                                        // Send to chats
                                        if let user = shareObject.last!.value(forKey: "byUser") as? PFUser {
                                            let chats = PFObject(className: "Chats")
                                            chats["sender"] = PFUser.current()!
                                            chats["receiver"] = shareUserObject!
                                            chats["senderUsername"] = PFUser.current()!.username!
                                            chats["receiverUsername"] = shareUserObject!.value(forKey: "username") as! String
                                            chats["read"] = false
                                            chats["Message"] = "@\(user["username"] as! String) said: \(shareObject.last!.value(forKey: "textPost") as! String)"
                                            chats.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if error == nil {
                                                    print("Successfully saved chat: \(chats)")
                                                    
                                                    let alert = UIAlertController(title: "Shared ✓",
                                                                                  message: "Successfully shared text post to \(userName!).",
                                                        preferredStyle: .alert)
                                                    
                                                    let ok = UIAlertAction(title: "ok",
                                                                           style: .default,
                                                                           handler: {(alertAction: UIAlertAction!) in
                                                                            
                                                                            // MARK: - OneSignal
                                                                            // Send Push Notification
                                                                            OneSignal.postNotification(
                                                                                ["contents":
                                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) shared a text post with you"],
                                                                                 "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"]
                                                                                ]
                                                                            )
                                                                            
                                                                            // Pop view controller
                                                                            self.navigationController?.popViewController(animated: true)
                                                    })
                                                    
                                                    alert.addAction(ok)
                                                    alert.view.tintColor = UIColor.black
                                                    self.present(alert, animated: true, completion: nil)
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                        }
                                    }
                                    
                                    
        })
        
        let no = UIAlertAction(title: "no",
                               style: .destructive,
                               handler: nil)
        
        
        alert.addAction(no)
        alert.addAction(yes)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
        
    }

    

    
    
    


}
