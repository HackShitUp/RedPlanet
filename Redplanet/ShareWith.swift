//
//  ShareWith.swift
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

// Global arrays:
// Holds the shareObject; PFObject to re-share posts
var shareObject = [PFObject]()

// Holds array of objects to share created posts
var createdObject = [PFObject]()

class ShareWith: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    // Array to hold share objects
    var shareWithObjects = [PFObject]()
    
    
    // Array to hold following
    var following = [PFObject]()
    // Array to hold search objects
    var searchObjects = [PFObject]()

    // Variable to determine whether user is searching or not
    var searchActive: Bool = false
    // Search Bar
    var searchBar = UISearchBar()
    // Pipeline method
    var page: Int = 50
    // App Delegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBAction func shareAction(_ sender: Any) {
        // Check if there exists any people to share with...
        if self.shareWithObjects.count != 0 {
            
            // Disable button
            self.shareButton.isEnabled = false

            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Sharing With \(shareWithObjects.count) People...")
            
            if shareObject.count != 0 {
                // Re-share a post
                self.reShare()
            } else {
                if self.shareWithObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    // Save to Newsfeeds
                    createdObject.last!.saveInBackground()
                }
            }
            // Share post with friends
            self.shareWithFriends()

            // MARK: - RPHelpers
            rpHelpers.showSuccess(withTitle: "Successfully Sent")
            
            // Clear arrrays
            let capturedStill = CapturedStill()
            capturedStill.clearArrays()
            
            // Send Notification
            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
            
            // Pop 3 VC's and push to bot || pop 1 VC
            if self.navigationController?.viewControllers.count == 3 {
                let viewControllers = self.navigationController!.viewControllers as [UIViewController]
                _ = self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                // MARK: - SwipeNavigationController
                self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    
    // Function to Re-Share a Post
    func reShare() {
        
        if self.shareWithObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
            // Share to Everyone in News Feeds
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["textPost"] = "Shared a post."
            newsfeeds["pointObject"] = shareObject.last!
            newsfeeds["contentType"] = "sh"
            newsfeeds["saved"] = false
            newsfeeds.saveInBackground()
            
            // Send Notification
            let notifications = PFObject(className: "Notifications")
            notifications["fromUser"] = PFUser.current()!
            notifications["from"] = PFUser.current()!.username!
            notifications["toUser"] = shareObject.last!.value(forKey: "byUser") as! PFUser
            notifications["to"] = (shareObject.last!.value(forKey: "byUser") as! PFUser).value(forKey: "username") as! String
            notifications["type"] = "share " + "\(shareObject.last!.value(forKey: "contentType") as! String)"
            notifications["forObjectId"] = shareObject.last!.objectId!
            notifications.saveEventually()
            
            // MARK: - RPHelpers; Optional Chaining: Handle APNSID
            if let ogUser = shareObject.last!.value(forKey: "byUser") as? PFUser {
                if ogUser.value(forKey: "apnsId") != nil {
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.pushNotification(toUser: ogUser, activityType: "shared your post")
                    
                }
            }
            
        }
    }
    

    func shareWithFriends() {
        for user in self.shareWithObjects {
            if user.objectId! != PFUser.current()!.objectId! {
                
                switch createdObject.last!.value(forKey: "contentType") as! String {
                case "itm":
                // Save Moment to "Chats"
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = user
                    chats["receiverUsername"] = user.value(forKey: "username") as! String
                    chats["mediaType"] = "itm"
                    chats["read"] = false
                    chats["saved"] = false
                    if createdObject.last!.value(forKey: "photoAsset") != nil {
                        chats["photoAsset"] = createdObject.last!.value(forKey: "photoAsset") as! PFFile
                    } else {
                        chats["videoAsset"] = createdObject.last!.value(forKey: "videoAsset") as! PFFile
                    }
                    chats.saveEventually()
                    
                    /*
                     MARK: - RPHelpers
                     Helper to update <ChatsQueue>
                     */
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)
                    
                case "tp":
                // Save Text Post to "Chats"
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = user
                    chats["receiverUsername"] = user.value(forKey: "username") as! String
                    chats["read"] = false
                    chats["saved"] = false
                    chats["Message"] = createdObject.last!.value(forKey: "textPost") as! String
                    chats.saveEventually()
                    
                    /*
                     MARK: - RPHelpers
                     Helper to update <ChatsQueue>
                     */
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)

                case "ph":
                // Save Photo to "Chats"
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = user
                    chats["receiverUsername"] = user.value(forKey: "username") as! String
                    chats["read"] = false
                    chats["saved"] = false
                    chats["mediaType"] = "ph"
                    chats["photoAsset"] = createdObject.last!.value(forKey: "photoAsset") as! PFFile
                    chats.saveEventually()
                    
                    /*
                     MARK: - RPHelpers
                     Helper to update <ChatsQueue>
                     */
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)

                case "vi":
                // Save Video to "Chats"
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = user
                    chats["receiverUsername"] = user.value(forKey: "username") as! String
                    chats["read"] = false
                    chats["saved"] = false
                    chats["mediaType"] = "vi"
                    chats["videoAsset"] = createdObject.last!.value(forKey: "videoAsset") as! PFFile
                    chats.saveEventually()
                    
                    /*
                     MARK: - RPHelpers
                     Helper to update <ChatsQueue>
                     */
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)
                    
                default:
                    break
                }
                
                // MARK: - RPHelpers; send push notification
                if user.value(forKey: "apnsId") != nil {
                    let rpHelpers = RPHelpers()
                    _ = rpHelpers.pushNotification(toUser: user, activityType: "from")
                }
            }
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
        // Query relationships
        _ = appDelegate.queryRelationships()
        
        // FOLLOWING
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.limit = self.page
        following.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "following") as! PFUser).objectId!}) {
                        self.following.append(object.object(forKey: "following") as! PFUser)
                    }
                }

                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "NetworkError")
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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Share With..."
        }
        
        // Hide UITabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - RPHelpers; whiten UINavigationBar and roundAllCorners
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.view.roundAllCorners(sender: self.navigationController?.view)
        
        // MARK: - RPHelpers
        // Hide rpButton
        rpButton.isHidden = true
        
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch Following
        queryFollowing()
        
        // Stylize title
        configureView()
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        self.tableView?.tableHeaderView = self.searchBar
        self.tableView?.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView?.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        self.tableView?.tableHeaderView?.clipsToBounds = true
        self.tableView?.tableFooterView = UIView()
        self.tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)

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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Clear arrays
        self.shareWithObjects.removeAll(keepingCapacity: false)
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

    // MARK: - UITableView DataSource Methods
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
        label.font = UIFont(name: "AvenirNext-Bold", size: 12.00)
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "shareWithCell") as! ShareWithCell
        
        // Set selection tintColor
        cell.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        cell.selectionStyle = .none

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // SEARCHED
        if self.tableView!.numberOfSections == 1 {
            // (1) Set name
            cell.rpFullName.text! = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
            // (2) Set Profile Photo
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // (3) Set selected state to none
            cell.accessoryType = .none
        } else {
        // PUBLIC & FOLLOWING
            if indexPath.section == 0 && indexPath.row == 0 {
            // PUBLIC
                cell.rpUserProPic.image = UIImage(named: "ShareOP")
                cell.rpFullName.text! = "Everyone"
                // Configure selected state
                if self.shareWithObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
            // FOLLOWING
                // Sort Following in ABC-Order
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // (1) Set name
                cell.rpFullName.text! = abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
                // (2) Set proPic
                if let proPic  = abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (3) Configure selected state
                if self.shareWithObjects.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
        }
        
        return cell
    }
    
    // MARK: - UITableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.tableView!.numberOfSections == 1 {
            // Append searched object
            if !self.shareWithObjects.contains(where: {$0.objectId! == self.searchObjects[indexPath.row].objectId!}) {
                self.shareWithObjects.append(self.searchObjects[indexPath.row])
            }
            // Resign first responder
            self.searchBar.resignFirstResponder()
            // Reload data
            self.refresh()
        } else {
        // PUBLIC & FOLLOWING
            if indexPath.section == 0 && indexPath.row == 0 {
                // Append current user's object
                if !self.shareWithObjects.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    self.shareWithObjects.append(PFUser.current()!)
                }
            } else {
                // Sort Following in ABC-Order
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Append following object
                if !self.shareWithObjects.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    self.shareWithObjects.append(abcFollowing[indexPath.row])
                }
            }
        }
        
        // Configure selected state
        self.tableView?.cellForRow(at: indexPath)?.accessoryType = (self.tableView?.cellForRow(at: indexPath)?.isSelected)! ? .checkmark : .none
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // SEARCHED
        if self.tableView?.numberOfSections == 1 {
            // Remove Searched User
            if let index = self.shareWithObjects.index(of: self.searchObjects[indexPath.row]) {
                self.shareWithObjects.remove(at: index)
            }
            // Reload data
            self.refresh()
        } else {
        // PUBLIC & FOLLOWING
            if indexPath.section == 0 && indexPath.row == 0 {
                // Remove: PFUser.current()!
                if let index = self.shareWithObjects.index(of: PFUser.current()!) {
                    self.shareWithObjects.remove(at: index)
                }

            } else {
                // Sort Following
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Remove: Following
                if let index = self.shareWithObjects.index(of: abcFollowing[indexPath.row]) {
                    self.shareWithObjects.remove(at: index)
                }
            }
        }
        
        // Configure selected state
        self.tableView?.cellForRow(at: indexPath)?.accessoryType = (self.tableView?.cellForRow(at: indexPath)?.isSelected)! ? .checkmark : .none
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.following.count {
                // Increase page size to load more posts
                page = page + 50
                // Query friends
                queryFollowing()
            }
        }
    }
}
