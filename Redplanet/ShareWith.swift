//
//  ShareWith.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/12/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

import Parse
import ParseUI
import Bolts

import SDWebImage
import SwipeNavigationController

// Array to hold share object
var shareWithObject = [PFObject]()

class ShareWith: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    // MARK: - Class Variables
    open var createdPost: Bool? = false
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Array to hold users to share with
    var usersToShareWith = [PFObject]()
    // Array to hold following
    var following = [PFObject]()
    
    // Array to hold searched
    var searchedUsers = [PFObject]()
    // Initialize UISearchBar
    var searchBar = UISearchBar()
    
    // PFQuery limit; pipline method initialization
    var page: Int = 50
    
    @IBAction func backAction(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneAction(_ sender: Any) {
        if self.usersToShareWith.count != 0 {
            // Disable button
            self.doneButton.isEnabled = false
            
            // Save to <Newsfeeds>
            if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                // Save in background
                shareWithObject.last!.saveInBackground()
                // Send Notification
                NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
            }
            
            // Send to individual people
            for user in self.usersToShareWith {
                if user.objectId! != PFUser.current()!.objectId! {
                    // Switch Statement...
                    switch shareWithObject.last!.value(forKey: "contentType") as! String {
                    case "tp":
                    // TEXT POST
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = user
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["read"] = false
                        chats["saved"] = false
                        chats["Message"] = shareWithObject.last!.value(forKey: "textPost") as! String
                        chats.saveInBackground()
                        
                        // MARK: - RPHelpers; update chatsQueue
                        let rpHelpers = RPHelpers()
                        _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)
                        
                    case "ph":
                    // PHOTO
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = user
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["read"] = false
                        chats["saved"] = false
                        chats["mediaType"] = "ph"
                        chats["photoAsset"] = shareWithObject.last!.value(forKey: "photoAsset") as! PFFile
                        chats.saveInBackground()
                        
                        // MARK: - RPHelpers; update chatsQueue
                        let rpHelpers = RPHelpers()
                        _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)
                        
                    case "vi":
                    // VIDEO
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = user
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["read"] = false
                        chats["saved"] = false
                        chats["mediaType"] = "vi"
                        chats["videoAsset"] = shareWithObject.last!.value(forKey: "videoAsset") as! PFFile
                        chats.saveInBackground()
                        
                        // MARK: - RPHelpers; update chatsQueue
                        let rpHelpers = RPHelpers()
                        _ = rpHelpers.updateQueue(chatQueue: chats, userObject: user)
                        
                    // TODO::
                    // SPACE POST?
                        
                    case "itm":
                    // MOMENT
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = user
                        chats["receiverUsername"] = user.value(forKey: "username") as! String
                        chats["mediaType"] = "itm"
                        chats["read"] = false
                        chats["saved"] = false
                        if shareWithObject.last!.value(forKey: "photoAsset") != nil {
                            chats["photoAsset"] = shareWithObject.last!.value(forKey: "photoAsset") as! PFFile
                        } else {
                            chats["videoAsset"] = shareWithObject.last!.value(forKey: "videoAsset") as! PFFile
                        }
                        chats.saveInBackground()
                        
                        // MARK: - RPHelpers; update chatsQueue
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

            
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showSuccess(withTitle: "Successfully Sent")
            
            // Deallocate CapturedStill.swift
            let capturedStill = CapturedStill()
            capturedStill.clearArrays()
            
            // Clear arrays
            self.usersToShareWith.removeAll(keepingCapacity: false)
        }
        
        
        // Pop 3 VC's and push to bot || pop 1 VC
        if self.navigationController?.viewControllers.count == 3 {
            let viewControllers = self.navigationController!.viewControllers as [UIViewController]
            _ = self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: false)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    // Function to fetch following
    func fetchFollowing() {
        // MARK: - AppDelegate; queryRelationships
        _ = appDelegate.queryRelationships()
        // Get following
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.order(byAscending: "createdAt")
        following.limit = self.page
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.following.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "following") as! PFUser).objectId!}) {
                        self.following.append(object.object(forKey: "following") as! PFUser)
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // Show current group w/NotificationBanner
    func showPeople(withIndex: IndexPath) {
        // Configure selected state
        tableView?.cellForRow(at: withIndex)?.accessoryType = (self.tableView?.cellForRow(at: withIndex)?.isSelected)! ? .checkmark : .none
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        rpHelpers.showProgress(withTitle: "Sharing with \(self.usersToShareWith.count) people...")
    }
    
    // Stylize UINavigationBar
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
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch Following
        fetchFollowing()
        // Stylize title
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure UISearchBar
        searchBar.delegate = self
        searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        tableView?.tableHeaderView = self.searchBar
        tableView?.tableHeaderView?.layer.borderWidth = 0.5
        tableView?.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        tableView?.tableHeaderView?.clipsToBounds = true
        tableView?.tableFooterView = UIView()
        tableView?.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Implement back swipe method
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backAction))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - MasterUI; show rpButton
        rpButton.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Clear arrays
        shareWithObject.removeAll(keepingCapacity: false)
        self.usersToShareWith.removeAll(keepingCapacity: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UISearchBarDelegate methods
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
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
                self.searchedUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    if self.following.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchedUsers.append(object)
                    }
                }
                // Reload data
                if self.searchedUsers.count != 0 {
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


    // MARK: - UITableView DataSource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchBar.text! != "" {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text! != "" {
            return self.searchedUsers.count
        } else {
            if section == 0 {
                return 1
            } else {
                return self.following.count
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.backgroundColor = UIColor.white
        header.textColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        header.font = UIFont(name: "AvenirNext-Bold", size: 12.00)
        header.textAlignment = .left
        
        if self.tableView.numberOfSections == 1 {
            header.text = "   Searched..."
        } else {
            if section == 0 {
                header.text = "   Public"
            } else {
                header.text = "   Following"
            }
        }
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // If post was NOT created, hide "Everyone" option
        if createdPost == false && section == 0 {
            return 0
        } else {
            return 35
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // If post was NOT created, hide "Everyone" option
        if createdPost == false && indexPath.row == 0 {
            return 0
        } else {
            return 50
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "shareWithCell") as! ShareWithCell
        
        // Set selection tintColor
        cell.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        cell.selectionStyle = .none
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        
        switch self.tableView.numberOfSections {
        case 2:
        // FOLLOWING
            if indexPath.section == 0 && indexPath.row == 0 {
            // Everyone -- Post
                cell.rpUserProPic.image = UIImage(named: "ShareOP")
                cell.rpFullName.text! = "Post"
                // Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
                
            } else {
                
            // One - Many Person(s)
                // Sort following in abcOrder
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                
                // (1) Set name
                cell.rpFullName.text! = abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
                // (2) Set Profile Photo
                if let proPic = abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                
                // (3) Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
            
        case 1:
        // SEARCHED
            
            // (1) Set name
            cell.rpFullName.text! = self.searchedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String
            // (2) Set Profile Photo
            if let proPic = self.searchedUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // (3) Set selected state to none
            cell.accessoryType = .none
            
        default:
            break
        }


        return cell
    }

    // MARK: - UITableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append object to array
        switch self.tableView.numberOfSections {
        case 1:
            // Append searched object
            if !self.searchedUsers.contains(where: {$0.objectId! == self.searchedUsers[indexPath.row].objectId!}) {
                self.searchedUsers.append(self.searchedUsers[indexPath.row])
            }
            // Resign first responder
            self.searchBar.resignFirstResponder()
            // Clear searchBar text
            self.searchBar.text! = ""
            // Query Following
            fetchFollowing()

        case 2:
            if indexPath.section == 0 && indexPath.row == 0 && !self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}){
                // Append current user's object
                self.usersToShareWith.append(PFUser.current()!)
                
            } else {
                // Sort Following in ABC-Order
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Append following object
                if !self.usersToShareWith.contains(where: {$0.objectId! == abcFollowing[indexPath.row].objectId!}) {
                    self.usersToShareWith.append(abcFollowing[indexPath.row])
                }
            }
        default:
            break;
        }
        // Show current group
        self.showPeople(withIndex: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch self.tableView.numberOfSections {
        case 1:
        // SEARCHED
            // Remove Searched User
            self.searchedUsers.remove(at: self.searchedUsers.index(of: self.searchedUsers[indexPath.row])!)
            // Clear searchBar text
            self.searchBar.text! = ""
            // Query Following
            fetchFollowing()
        case 2:
        // NOT SEARCHED
            if indexPath.section == 0 && indexPath.row == 0 {
                // Remove: PFUser.current()!
                self.usersToShareWith.remove(at: self.usersToShareWith.index(of: PFUser.current()!)!)
            } else {
                // Sort Following
                let abcFollowing = self.following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                // Remove: Following
                self.usersToShareWith.remove(at: self.usersToShareWith.index(of: abcFollowing[indexPath.row])!)
            }
        default:
            break;
        }
        // Show current group
        self.showPeople(withIndex: indexPath)
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.following.count {
                // Increase page size to load more posts
                page = page + 50
                // Query friends
                fetchFollowing()
            }
        }
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder
        searchBar.resignFirstResponder()
        // Clear searchBar
        self.searchBar.text! = ""
        // Reload data
        fetchFollowing()
    }
    
}
