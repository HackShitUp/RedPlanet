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
import SDWebImage
import SVProgressHUD
import DZNEmptyDataSet
import SimpleAlert


class ShareTo: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    
    // Array to hold following
    var following = [PFObject]()
    
    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    
    // Array to hold search objects
    var searchObjects = [PFObject]()
    var searchNames = [String]()
    
    // Search Bar
    var searchBar = UISearchBar()
    
    // AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reset Bool
        searchActive = false
        
        // Query Following
        queryFollowing()
    }
    
    
    // Query Following
    func queryFollowing() {
        
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.following.append(object.object(forKey: "following") as! PFUser)
                }
                
                // Reload data
                self.tableView!.reloadData()

                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }

        })
    }
    
    
    
    
    
    
    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Set tableView backgroundView
        self.tableView.backgroundView = UIView()
        // Reload data
        queryFollowing()
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
        let name = PFUser.query()!
        name.whereKey("username", matchesRegex: "(?i)" + self.searchBar.text!)
        let realName = PFUser.query()!
        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + self.searchBar.text!)
        let user = PFQuery.orQuery(withSubqueries: [name, realName])
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.searchNames.removeAll(keepingCapacity: false)
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.following.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchNames.append(object["username"] as! String)
                        self.searchObjects.append(object)
                    }
                }
                
                // Reload data
                self.tableView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        return true
        
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
                self.searchNames.removeAll(keepingCapacity: false)
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.following.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchNames.append(object["username"] as! String)
                        self.searchObjects.append(object)
                    }
                }
                
                
                // Reload data
                if self.searchObjects.count != 0 {
                    // Reload data
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
    
    
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)'s Following"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)

        // Fetch Following
        queryFollowing()
        
        // Stylize title
        configureView()
        
        // Query relationships
        _ = appDelegate.queryRelationships()
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        print("MEMORY WARNING")
        print(super.didReceiveMemoryWarning())
        URLCache.shared.removeAllCachedResponses()
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
            return self.following.count
        }
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
        
        // Return SEARCH
        if searchActive == true && searchBar.text! != "" {
            // Return searchObjects
            // Fetch user's realNameOfUser and user's profile photos
            cell.rpUsername.text! = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
        } else {
            
            // Sort Following in ABC order
            let abcFollowing = self.following.sorted { ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String) }
            
            // Return Follwoing
            // Fetch user's realNameOfUser and user's profile photos
            cell.rpUsername.text! = abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
            if let proPic = abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
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
            // Append Following
            userName = self.following[indexPath.row].value(forKey: "realNameOfUser") as? String
            shareUserObject = self.following[indexPath.row]
        }
        
        
        let alert = AlertController(title: "Share With \(userName!.uppercased())?",
            message: "Are you sure you'd like to share this with \(userName!.uppercased())?",
            style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                view.titleLabel.textColor = UIColor.black
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                view.messageLabel.textColor = UIColor.black
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
                
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        let yes = AlertAction(title: "yes",
                              style: .default,
                              handler: { (AlertAction) in
                                    
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
                                                                             "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"],
                                                                             "ios_badgeType": "Increase",
                                                                             "ios_badgeCount": 1
                                                                            ]
                                                                        )
                                                                        
                                                                        
                                                                        // Pop view controller
                                                                        _ = self.navigationController?.popViewController(animated: true)
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
                                                                             "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"],
                                                                             "ios_badgeType": "Increase",
                                                                             "ios_badgeCount": 1
                                                                            ]
                                                                        )
                                                                        
                                                                        // Pop view controller
                                                                        _ = self.navigationController?.popViewController(animated: true)
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
                                                                                 "include_player_ids": ["\(shareUserObject!.value(forKey: "apnsId") as! String)"],
                                                                                 "ios_badgeType": "Increase",
                                                                                 "ios_badgeCount": 1
                                                                                ]
                                                                            )
                                                                            
                                                                            // Pop view controller
                                                                            _ = self.navigationController?.popViewController(animated: true)
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
        
        let no = AlertAction(title: "no",
                             style: .destructive,
                             handler: nil)
        
        
        alert.addAction(no)
        alert.addAction(yes)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
        
    }

    

    
    
    


}
