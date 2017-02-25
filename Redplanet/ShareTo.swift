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

class ShareTo: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // Array to hold share objects
    var shareObjects = [PFObject]()
    
    // Array to hold following
    var following = [PFObject]()
    // Array to hold search objects
    var searchObjects = [PFObject]()

    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    // Search Bar
    var searchBar = UISearchBar()
    
    // App Delegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBAction func shareAction(_ sender: Any) {
    // MARK: - SimpleAlert
        if self.shareObjects.count != 0 {
            // Disable button
            self.shareButton.isEnabled = false
            // MARK: - SVProgressHUD
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.setForegroundColor(UIColor.black)
            SVProgressHUD.show(withStatus: "Sharing")
            
            if self.shareObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                // Share to Everyone in News Feeds
                let newsfeeds = PFObject(className: "Newsfeeds")
                newsfeeds["byUser"] = PFUser.current()!
                newsfeeds["username"] = PFUser.current()!.username!
                newsfeeds["textPost"] = "Shared a post."
                newsfeeds["pointObject"] = shareObject.last!
                newsfeeds["contentType"] = "sh"
                newsfeeds["saved"] = false
                newsfeeds.saveEventually()
                
                // Send Notification
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = shareObject.last!.value(forKey: "byUser") as! PFUser
                notifications["to"] = (shareObject.last!.value(forKey: "byUser") as! PFUser).value(forKey: "username") as! String
                notifications["type"] = "share " + "\(shareObject.last!.value(forKey: "contentType") as! String)"
                notifications["forObjectId"] = shareObject.last!.objectId!
                notifications.saveEventually()
                
                // Optional Chaining: Handle APNSID
                if let ogUser = shareObject.last!.value(forKey: "byUser") as? PFUser {
                    if ogUser.value(forKey: "apnsId") != nil {
                        // MARK: - OneSignal
                        OneSignal.postNotification(
                            ["contents":
                                ["en": "\(PFUser.current()!.username!.uppercased()) shared your post"],
                             "include_player_ids": ["\(ogUser.value(forKey: "apnsId") as! String)"],
                             "ios_badgeType": "Increase",
                             "ios_badgeCount": 1
                            ]
                        )
                    }
                }
            }
            
            if shareObject.last!.value(forKey: "photoAsset") != nil {
                // PHOTO
                // Share with user
                // Send to Chats
                for user in self.shareObjects {
                    if user.objectId! != PFUser.current()!.objectId! {
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["receiver"] = user
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["read"] = false
                        chats["photoAsset"] = shareObject.last!.value(forKey: "photoAsset") as! PFFile
                        chats.saveEventually()
                        // MARK: - OneSignal
                        // Send Push Notification
                        OneSignal.postNotification(
                            ["contents":
                                ["en": "\(PFUser.current()!.username!.uppercased()) shared a Photo with you"],
                             "include_player_ids": ["\(user.value(forKey: "apnsId") as! String)"],
                             "ios_badgeType": "Increase",
                             "ios_badgeCount": 1
                            ]
                        )
                    }
                }
            } else if shareObject.last!.value(forKey: "videoAsset") != nil {
                // VIDEO
                // Share with user
                // Send to Chats
                for user in self.shareObjects {
                    if user.objectId! != PFUser.current()!.objectId! {
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] =  PFUser.current()!.username!
                        chats["receiver"] = user
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["read"] = false
                        chats["videoAsset"] = shareObject.last!.value(forKey: "videoAsset") as! PFFile
                        chats.saveEventually()
                        // MARK: - OneSignal
                        // Send Push Notification
                        OneSignal.postNotification(
                            ["contents":
                                ["en": "\(PFUser.current()!.username!.uppercased()) shared a Video with you"],
                             "include_player_ids": ["\(user.value(forKey: "apnsId") as! String)"],
                             "ios_badgeType": "Increase",
                             "ios_badgeCount": 1
                            ]
                        )
                    }
                }
            } else {
                // TEXT POST
                if let userObject = shareObject.last!.value(forKey: "byUser") as? PFUser {
                    for user in self.shareObjects {
                        if user.objectId! != PFUser.current()!.objectId! {
                            let chats = PFObject(className: "Chats")
                            chats["sender"] = PFUser.current()!
                            chats["receiver"] = user
                            chats["senderUsername"] = PFUser.current()!.username!
                            chats["receiverUsername"] = user.value(forKey: "username") as! String
                            chats["read"] = false
                            chats["Message"] = "@\(userObject["username"] as! String) said: \(shareObject.last!.value(forKey: "textPost") as! String)"
                            chats.saveEventually()
                            // MARK: - OneSignal
                            // Send Push Notification
                            OneSignal.postNotification(
                                ["contents":
                                    ["en": "\(PFUser.current()!.username!.uppercased()) shared a Text Post with you"],
                                 "include_player_ids": ["\(user.value(forKey: "apnsId") as! String)"],
                                 "ios_badgeType": "Increase",
                                 "ios_badgeCount": 1
                                ]
                            )
                        }
                    }
                }
            }

            // MARK: - SVProgressHUD
            SVProgressHUD.showSuccess(withStatus: "Shared")
            // Pop VC
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // Function to refresh
    func refresh() {
        // Reset Bool
        searchActive = false
        // Clear searchBar text
        self.searchBar.text! = ""
        // Query Following
        queryFollowing()
    }
    
    // Query Following
    func queryFollowing() {
        // FOLLOWING
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.following.append(object.object(forKey: "following") as! PFUser)
                }
                
                // Set DZN if count is 0
                if self.following.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
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

    
    // MARK: DZNEmptyDataSet Framework
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.following.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🦄\nNo one to share with..."
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    
    
    // Dismiss keyboard when UITableView is scrolled
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Set Boolean
        searchActive = false
        // Clear searchBar
        self.searchBar.text! = ""
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
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.following.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchObjects.append(object)
                    }
                }
                
                // Reload data
                if self.searchObjects.count != 0 {
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
    
    
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Share With"
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
//        self.tableView?.tableHeaderView = self.searchBar
        self.tableView?.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView?.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        self.tableView?.tableHeaderView?.clipsToBounds = true
        self.tableView?.tableFooterView = UIView()
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView?.allowsMultipleSelection = true

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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.shareObjects.removeAll(keepingCapacity: false)
        shareObject.removeAll(keepingCapacity: false)
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
        if searchActive == true && searchBar.text! != "" {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive == true && searchBar.text! != "" {
            return self.searchObjects.count
        } else {
            if section == 0 {
               return 1
            } else {
                return self.following.count
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "AvenirNext-Demibold", size: 12.00)
        label.textColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        
        if self.tableView?.numberOfSections == 1 {
            return label
        } else {
            if section == 0 {
                label.text = "   PUBLIC"
                return label
            } else {
                label.text = "   FOLLOWING"
                return label
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "shareToCell") as! ShareToCell
        
        // Set selection tintColor
        cell.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        cell.selectionStyle = .none

        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.clipsToBounds = true
        
        // SEARCHED
        if self.tableView?.numberOfSections == 1 {
            // Set name 
            cell.rpFullName.text! = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            // Set profile photo
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            if self.shareObjects.contains(where: {$0.objectId! == searchObjects[indexPath.row].objectId!}) {
                self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
            } else {
                self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
            }
        }
        
        if self.tableView?.numberOfSections == 2 {
        // NOT SEARCHED
            if indexPath.section == 0 {
                // SET TO PUBLIC
                cell.rpUserProPic.image = UIImage(named: "ShareOP")
                cell.rpFullName.text! = "Post"
                if self.shareObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
                } else {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
                }
            } else {
                // Sort Following
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Set name
                cell.rpFullName.text! = abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
                // Set profile photo
                if let proPic = abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
                if self.shareObjects.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
                } else {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
                }
            }
        }
        
        return cell
    }
    
    
    
    
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.tableView?.numberOfSections == 1 {
            // Append search object
            self.shareObjects.append(self.searchObjects[indexPath.row])
            if self.shareObjects.contains(where: {$0.objectId! == searchObjects[indexPath.row].objectId!}) {
                self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
            } else {
                 self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
            }
        }
        
        if self.tableView?.numberOfSections == 2 {
        // NOT SEARCHED
            if indexPath.section == 0 {
                // Append PFUser.current()!
                self.shareObjects.append(PFUser.current()!)
                if self.shareObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
                } else {
                     self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
                }
            } else {
                // Sort Following
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Append object
                self.shareObjects.append(abcFollowing[indexPath.row])
                if self.shareObjects.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark
                } else {
                     self.tableView?.cellForRow(at: indexPath)?.accessoryType = .none
                }
            }
        }
        
         self.tableView?.cellForRow(at: indexPath)?.accessoryType = .checkmark

    }

    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.tableView?.numberOfSections == 1 {
            // Remove Searched User
            if let index = self.shareObjects.index(of: self.searchObjects[indexPath.row]) {
                self.shareObjects.remove(at: index)
            }
        }
        
        if self.tableView?.numberOfSections == 2 {
        // NOT SEARCHED
            // Append current user if first
            if indexPath.section == 0 && indexPath.row == 0 {
                if let index = self.shareObjects.index(of: PFUser.current()!) {
                    self.shareObjects.remove(at: index)
                }
            } else {
                // Sort Following
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                if let index = self.shareObjects.index(of: abcFollowing[indexPath.row]) {
                    self.shareObjects.remove(at: index)
                }
            }
        }
        
        // Set state to none
        self.tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
