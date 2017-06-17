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

import DZNEmptyDataSet
import SDWebImage
import SwipeNavigationController

// Array to hold share object
var shareWithObject = [PFObject]()

/*
 UITableViewController class that allows users to POST or share their Text Post, Photo, Video, or Moment with individuals.
 Holds "ShareWithCell.swift" to present each user, but binds the data in this class. If a user decides to post it, their own
 PFUser/PFObject is appended to an array in this class titled "usersToShareWith". When the "Done" button is tapped, the code checks
 for the current user's object and posts it if it exists.
 
 NOTE: This class returns 1 section for searched users, and 2 sections when not searched.
 In other words, the UITableView will by default have 2 sections; (1) Post, and (2) Show a list of people the current user is following
 IF however, the user has searched for someone, the UITableView will have only 1 section.
*/

class ShareWith: UITableViewController, UINavigationControllerDelegate, UISearchBarDelegate, SwipeNavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Array to hold users to share with
    var usersToShareWith = [PFObject]()
    
    // Initialize UISearchBar
    var searchBar = UISearchBar()
    // PFQuery limit; pipline method initialization
    var page: Int = 50
    
    // Array to hold following
    var abcFollowing = [PFObject]()
    // Array to hold searched
    var searchedUsers = [PFObject]()
    
    @IBAction func backAction(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneAction(_ sender: Any) {
        switch self.usersToShareWith.count {
        case let x where x > 7:
            // Show Alert
            self.showAlert(withStatus: "Exceeded")
        case let x where x > 0:
            // Disable button
            self.doneButton.isEnabled = false
            // Save to <Newsfeeds>
            if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                // Traverse PFObject to get object data...
                let postObject = shareWithObject.last!
                if let geoPoint = PFUser.current()!.value(forKey: "location") as? PFGeoPoint {
                    postObject["location"] = geoPoint   // add geoLocation...
                }
                postObject.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        // Handle nil textPost
                        if postObject.value(forKey: "textPost") != nil {
                            // MARK: - RPHelpers; check for #'s and @'s
                            let rpHelpers = RPHelpers()
                            rpHelpers.checkHash(forObject: postObject,
                                                forText: (postObject.value(forKey: "textPost") as! String))
                            rpHelpers.checkTags(forObject: postObject,
                                                forText: (postObject.value(forKey: "textPost") as! String),
                                                postType: (postObject.value(forKey: "contentType") as! String))
                        }

                        // Send Notification
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error...")
                    }
                })
            }
            
            // Send to individual people
            for user in self.usersToShareWith {
                if user.objectId! != PFUser.current()!.objectId! {
                    // Switch Statement...
                    switch shareWithObject.last!.value(forKey: "contentType") as! String {
                    case "tp":
                    // TEXT POST
                        let textPostChat = PFObject(className: "Chats")
                        textPostChat["sender"] = PFUser.current()!
                        textPostChat["senderUsername"] = PFUser.current()!.username!
                        textPostChat["receiver"] = user
                        textPostChat["receiverUsername"] = user.value(forKey: "username") as! String
                        textPostChat["read"] = false
                        textPostChat["saved"] = false
                        textPostChat["Message"] = shareWithObject.last!.value(forKey: "textPost") as! String
                        // Update "CHATS"
                        self.updateChats(withObject: textPostChat, user: user)
                        
                    case "ph":
                    // PHOTO
                        let photoChat = PFObject(className: "Chats")
                        photoChat["sender"] = PFUser.current()!
                        photoChat["senderUsername"] = PFUser.current()!.username!
                        photoChat["receiver"] = user
                        photoChat["receiverUsername"] = user.value(forKey: "username") as! String
                        photoChat["read"] = false
                        photoChat["saved"] = false
                        photoChat["contentType"] = "ph"
                        photoChat["photoAsset"] = shareWithObject.last!.value(forKey: "photoAsset") as! PFFile
                        // Update "ChatsQueue"
                        self.updateChats(withObject: photoChat, user: user)
                        
                    case "vi":
                    // VIDEO
                        let videoChat = PFObject(className: "Chats")
                        videoChat["sender"] = PFUser.current()!
                        videoChat["senderUsername"] = PFUser.current()!.username!
                        videoChat["receiver"] = user
                        videoChat["receiverUsername"] = user.value(forKey: "username") as! String
                        videoChat["read"] = false
                        videoChat["saved"] = false
                        videoChat["contentType"] = "vi"
                        videoChat["videoAsset"] = shareWithObject.last!.value(forKey: "videoAsset") as! PFFile
                        // Update "ChatsQueue"
                        self.updateChats(withObject: videoChat, user: user)

                    case "itm":
                    // MOMENT
                        let momentChat = PFObject(className: "Chats")
                        momentChat["sender"] = PFUser.current()!
                        momentChat["senderUsername"] = PFUser.current()!.username!
                        momentChat["receiver"] = user
                        momentChat["receiverUsername"] = user.value(forKey: "username") as! String
                        momentChat["contentType"] = "itm"
                        momentChat["read"] = false
                        momentChat["saved"] = false
                        if shareWithObject.last!.value(forKey: "photoAsset") != nil {
                            momentChat["photoAsset"] = shareWithObject.last!.value(forKey: "photoAsset") as! PFFile
                        } else {
                            momentChat["videoAsset"] = shareWithObject.last!.value(forKey: "videoAsset") as! PFFile
                        }
                        // Update "ChatsQueue"
                        self.updateChats(withObject: momentChat, user: user)
                        
                    default:
                        break
                    }
                }
            }
            
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showSuccess(withTitle: "Shared")
            
            // Deallocate CapturedStill.swift
            let capturedStill = CapturedStill()
            capturedStill.clearArrays()
            
            // Clear arrays
            self.usersToShareWith.removeAll(keepingCapacity: false)
        
            // Show center, or pop VC
            if self.navigationController?.restorationIdentifier == "right" || self.navigationController?.restorationIdentifier == "left" {
                // MARK: - SwipeNavigationController; show center VC
                self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
                
            } else if self.navigationController?.restorationIdentifier == "center" {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }

        case let x where x == 0 :
            // Show alert
            self.showAlert(withStatus: "None")
        default:
            break;
        }
    }
    
    
    // FUNCTION - MARK: - RPHelpers; update "chatsQueue" and send push notification
    func updateChats(withObject: PFObject?, user: PFObject?) {
        withObject!.saveInBackground(block: { (success: Bool, error: Error?) in
            if success {
                // MARK: - RPHelpers; update chatsQueue; and send push notification
                let rpHelpers = RPHelpers()
                rpHelpers.updateQueue(chatQueue: withObject!, userObject: user)
                rpHelpers.pushNotification(toUser: user, activityType: "from")
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Error Sharing...")
            }
        })
    }
    
    // FUNCTION - Show status alert
    func showAlert(withStatus: String) {
        // Vibrate device
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        // Resign first responder
        self.searchBar.resignFirstResponder()
        
        // Instantiate message variable to show in alert
        var title: String?
        var message: String?
        if withStatus == "Exceeded" {
            title = "Exceeded Maximum Number of Shares"
            message = "You can only share posts with a maximum of 7 people..."
        } else if withStatus == "None" {
            title = "Post or share with friends..."
            message = "You're not sharing with anyone. Sharing is caring!"
        }
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "💩\n\(title!)", message: "\(message!)")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
            button.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
            button.layer.masksToBounds = true
        }
        // Add OK button
        dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
        }))
        // Show
        dialogController.show(in: self)
    }
    
    
    // FUNCTION - Fetch following
    func fetchFollowing() {
        // MARK: - AppDelegate; queryRelationships
        _ = appDelegate.queryRelationships()
        // Get following
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.order(byDescending: "createdAt")
        following.limit = self.page
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Create array
                var following = [PFObject]()
                // Clear array
                following.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "following") as! PFUser).objectId!}) {
                        following.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.abcFollowing = following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FUNCTION - Stylize UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21) {
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
        
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - SwipeNavigationControllerDelegate Method
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        let vcCount = self.navigationController?.viewControllers.count
        // If position is center
        if position == .center {
            // Pop 2 VC's and push to bot || pop 1 VC
            if self.navigationController?.viewControllers.count == vcCount {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        // EMPTY
    }
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // If there are NO following OR searchBar is typing AND thre are no search results...
        if self.abcFollowing.isEmpty || (self.searchBar.isFirstResponder && self.searchedUsers.isEmpty) {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        if self.searchBar.text == "" && self.abcFollowing.isEmpty {
            // No Active Chats
            str = "🙊\nNo Followings"
        } else if self.searchedUsers.isEmpty {
            // No Results
            str = "💩\nNo Results"
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 30)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
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
        
        // MARK: - SwipeNavigationControllerDelegate
        self.containerSwipeNavigationController?.delegate = self

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
                    if self.abcFollowing.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchedUsers.append(object)
                    }
                }
                // Reload data
                if self.searchedUsers.count != 0 {
                    // De-allocate DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = nil
                    self.tableView.emptyDataSetDelegate = nil
                    // Reload UITableView
                    self.tableView.reloadData()
                    print("SEARCHED: \(self.searchedUsers)")
                } else {
                    // MARK: - DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                    self.tableView.reloadData()
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }


    // MARK: - UITableView DataSource Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchBar.text != "" && self.searchBar.isFirstResponder {
        // SEARCHED
            return 1
        } else {
        // POST & FOLLOWING
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // # of Rows
        var numberOfRows: Int?
        // SEARCHED
        if self.tableView.numberOfSections == 1 && self.searchBar.text != "" {
            numberOfRows = self.searchedUsers.count
        } else if self.tableView.numberOfSections == 2 && section == 0 {
        // POST
            numberOfRows = 1
        } else if self.tableView.numberOfSections == 2 && section == 1 {
        // FOLLOWING
            numberOfRows = self.abcFollowing.count
        }
        return numberOfRows!
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.backgroundColor = UIColor.white
        header.textColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        header.font = UIFont(name: "AvenirNext-Bold", size: 12)
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

        // If post was NOT created (shareWithObject.last!.objectId == nil), hide "Public/Post" option
        if shareWithObject.last!.objectId != nil && section == 0 && self.searchBar.text == "" {
            return 0
        } else if self.searchBar.text != "" && section == 0 {
            return 35
        } else {
            return 35
        }
        
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // If post was NOT created, hide "Public/Post" row
        if shareWithObject.last!.objectId != nil && indexPath.row == 0 && self.searchBar.text == "" {
        // NOT CREATED AND NOT SEARCHED
            return 0
        } else if self.searchBar.text != "" && self.tableView.numberOfSections == 1 {
        // SEARCHED
            return 50
        } else {
        // NOT SEARCHED
            return 50
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "shareWithCell") as! ShareWithCell
        // Configure UITableViewCell's accessory tintColor
        cell.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
    
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        switch self.tableView.numberOfSections {
        case 2:
            if indexPath.section == 0 && indexPath.row == 0 {
            // POST
                
                cell.rpUserProPic.image = UIImage(named: "ShareOP")
                cell.rpFullName.text! = "Post"
                // Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                    cell.accessoryType = .checkmark
                } else {
                    cell.contentView.backgroundColor = UIColor.white
                    cell.accessoryType = .none
                }
                
            } else {
            // FOLLOWING

                // (1) Set name
                cell.rpFullName.text! = self.abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
                // (2) Set Profile Photo
                if let proPic = self.abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (3) Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == self.abcFollowing[indexPath.row].objectId!}) {
                    cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                    cell.accessoryType = .checkmark
                } else {
                    cell.contentView.backgroundColor = UIColor.white
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
            // (3) Configure selected state
            if self.usersToShareWith.contains(where: {$0.objectId! == self.searchedUsers[indexPath.row].objectId!}) {
                cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                cell.accessoryType = .checkmark
            } else {
                cell.contentView.backgroundColor = UIColor.white
                cell.accessoryType = .none
            }
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
        // SEARCHED
            // Append searched object
            if !self.usersToShareWith.contains(where: {$0.objectId! == self.searchedUsers[indexPath.row].objectId!}) {
                self.usersToShareWith.append(self.searchedUsers[indexPath.row])
            }

        case 2:
        // POST: Append current user's object
            if indexPath.section == 0 && indexPath.row == 0 && !self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}){
                self.usersToShareWith.append(PFUser.current()!)
                
            } else {
        // FOLLOWING: Sort Following in ABC-Order
                // Append following object
                if !self.usersToShareWith.contains(where: {$0.objectId! == self.abcFollowing[indexPath.row].objectId!}) {
                    self.usersToShareWith.append(self.abcFollowing[indexPath.row])
                }
            }
        default:
            break;
        }
        // Configure selected state
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.groupTableViewBackground
            cell.accessoryType = .checkmark
        }
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
                // Remove object at index
                if let removalIndex = self.usersToShareWith.index(of: self.abcFollowing[indexPath.row]) {
                    self.usersToShareWith.remove(at: removalIndex)
                }
            }
        default:
            break;
        }
        // Configure selected state
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.white
            cell.accessoryType = .none
        }
        
    }
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.abcFollowing.count {
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
