//
//  Chats.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import SDWebImage
import SwipeNavigationController


/*
 This UITableViewController displays the current chats sent to, and or received by, the current user. This class manages 2 crucial
 database classes in the server:
 
 (1) ChatsQueue
 (2) Chats
 
 It first fetches <ChatsQueue> to search for any current conversations sent to, or received by the current user. The query to the
 database class checks for a value in <lastChat> in <ChatsQueue> which is a pointer that points to <Chats>. Then, another query fires 
 and checks for the most recent chats in the <Chats> class of the database, fetches that object, and unloads them in the UITableView.
 The data is binded in this class, instead of its UITableViewCell class, "ChatsCell.swift"
 
 This class also executes in "MasterUI.swift" where it executes fetchChatsQueue(_ ) and configures the tab-bar badge icon in its
 completion handler to show unread chats.
 
 This class executes the above, everytime the view appears, to refresh any unread chats.
 */

class Chats: UITableViewController, UISearchBarDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // <ChatsQueue>
    var chatQueues = [String]()
    // <Chats>
    var chatObjects = [PFObject]()
    // Filtered: chatObjects --> User's Objects
    var userObjects = [PFObject]()
    // Searched Objects
    var searchObjects = [PFObject]()
    
    // Search Bar
    var searchBar = UISearchBar()
    // Refresher
    var refresher: UIRefreshControl!
    // Page size
    var page: Int = 50
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editAction(_ sender: Any) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Delete all Chats?",
            message: "Are you sure you'd like to delete all your current conversation queues?")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.layer.masksToBounds = true
            button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        // Add Delete button
        dialogController.addAction(AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // dismiss
            dialog.dismiss()
            
            // Delete <ChatsQueue>
            let frontChat = PFQuery(className: "ChatsQueue")
            frontChat.whereKey("frontUser", equalTo: PFUser.current()!)
            frontChat.whereKey("endUser", notEqualTo: PFUser.current()!)
            let endChat = PFQuery(className: "ChatsQueue")
            endChat.whereKey("endUser", equalTo: PFUser.current()!)
            endChat.whereKey("frontUser", notEqualTo: PFUser.current()!)
            let chats = PFQuery.orQuery(withSubqueries: [frontChat, endChat])
            chats.whereKeyExists("lastChat")
            chats.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    for object in objects! {
                        object.remove(forKey: "lastChat")
                        object.saveInBackground()
                    }
                    
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showSuccess(withTitle: "Deleted All Chats")
                    
                    // Reload data
                    self.fetchQueues()

                } else {
                    if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error")
                    }
                    
                    // Reload data
                    self.fetchQueues()
                    
                }
            })
        }))
        // Show
        dialogController.show(in: self)
    }
    
    @IBAction func newChat(_ sender: AnyObject) {
        // Track when New Chat button was tapped
        Heap.track("TappedNewChat", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        // Show NewChats.swift view controller
        let newChatsVC = self.storyboard?.instantiateViewController(withIdentifier: "newChats") as! NewChats
        self.navigationController!.pushViewController(newChatsVC, animated: true)
    }
    
    // Refresh function
    func refresh() {
        // Reload data
        fetchQueues()
    }
    
    // Query Parse; <ChatsQueue>
    func fetchQueues() {
        
        // Show UIRefreshControl
        self.refresher?.beginRefreshing()

        let frontChat = PFQuery(className: "ChatsQueue")
        frontChat.whereKey("frontUser", equalTo: PFUser.current()!)
        let endChat = PFQuery(className: "ChatsQueue")
        endChat.whereKey("endUser", equalTo: PFUser.current()!)
        let chats = PFQuery.orQuery(withSubqueries: [frontChat, endChat])
        chats.whereKeyExists("lastChat")
        chats.includeKeys(["lastChat", "frontUser", "endUser"])
        chats.order(byDescending: "updatedAt")
        chats.limit = self.page
        chats.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                
                // Clear array
                self.chatQueues.removeAll(keepingCapacity: false)
                for object in objects! {
                    if let lastChat = object.object(forKey: "lastChat") as? PFObject {
                        self.chatQueues.append(lastChat.objectId!)
                    }
                }
                // Fetch chats
                self.fetchChats()
            } else {
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            }
        }
    }
    
    // Query Parse; <Chats>
    func fetchChats() {
        // Query Chats and include pointers
        let chats = PFQuery(className: "Chats")
        chats.whereKey("objectId", containedIn: self.chatQueues)
        chats.whereKeyExists("receiver")
        chats.whereKeyExists("sender")
        chats.includeKeys(["receiver", "sender"])
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.chatObjects.removeAll(keepingCapacity: false)
                self.userObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if (object.value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        self.userObjects.append(object.value(forKey: "receiver") as! PFUser)
                    } else if (object.value(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
                        self.userObjects.append(object.value(forKey: "sender") as! PFUser)
                    }
                    self.chatObjects.append(object)
                }
                
                if self.chatObjects.count == 0 {
                    // MARK: - DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                } else {
                    // Reload data in main thread
                    DispatchQueue.main.async {
                        self.tableView?.reloadData()
                    }
                }

            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    // FUNCTION - Delete single chats in <ChatsQueue>
    func deleteChat(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {
                
                let fullName = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "\(fullName)",
                    message: "Delete Chat?\nAre you sure you'd like to delete this conversation queue?")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // add image
                dialogController.imageHandler = { (imageView) in
                    if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                        imageView.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                    } else {
                        imageView.image = UIImage(named: "GenderNeutralUser")
                    }
                    imageView.contentMode = .scaleAspectFill
                    return true //must return true, otherwise image won't show.
                }
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                    button.layer.masksToBounds = true
                    button.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                }
                // Add Cancel button
                dialogController.cancelButtonStyle = { (button,height) in
                    button.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                    button.setTitle("CANCEL", for: [])
                    return true
                }
                // Add Delete button
                dialogController.addAction(AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
                    
                    // Delete <ChatsQueue> 
                    let frontChat = PFQuery(className: "ChatsQueue")
                    frontChat.whereKey("frontUser", equalTo: PFUser.current()!)
                    frontChat.whereKey("endUser", equalTo: self.userObjects[indexPath.row])
                    let endChat = PFQuery(className: "ChatsQueue")
                    endChat.whereKey("endUser", equalTo: PFUser.current()!)
                    endChat.whereKey("frontUser", equalTo: self.userObjects[indexPath.row])
                    let chats = PFQuery.orQuery(withSubqueries: [frontChat, endChat])
                    chats.whereKeyExists("lastChat")
                    chats.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            
                            for object in objects! {
                                object.remove(forKey: "lastChat")
                                object.saveInBackground()
                                
                                // Delete chat from tableview
                                self.chatObjects.remove(at: indexPath.row)
                                self.tableView!.deleteRows(at: [indexPath], with: .fade)
                                
                                // Reload data
                                self.fetchQueues()
                                
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showSuccess(withTitle: "Deleted Chat")
                                
                                // Reload data in main thread
                                DispatchQueue.main.async {
                                    self.tableView!.reloadData()
                                }
                            }
                        } else {
                            if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showError(withTitle: "Network Error")
                            }
                            // Reload data
                            self.fetchQueues()
                        }
                    })
                    
                    dialog.dismiss()
                }))
                // Show
                dialogController.show(in: self)
            }
        }
    }
    
    // FUNCTION - Stylize UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Chats"
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.delegate = self
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // If there are NO chats OR searchBar is typing AND thre are no search results...
        if self.chatObjects.isEmpty || (self.searchBar.isFirstResponder && self.searchObjects.isEmpty) {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        if self.searchBar.text == "" && self.chatObjects.isEmpty {
        // No Active Chats
            str = "🙊\nNo Active Chats"
        } else if self.searchObjects.isEmpty {
        // No Results
            str = "💩\nNo Results"
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Start a conversation by tapping\nthe icon on the top right!"
        let font = UIFont(name: "AvenirNext-Medium", size: 17.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    // MARK: - UIView Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set design of navigation bar
        configureView()
        // Query chats
        fetchQueues()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        
        // Configure UISearchBar
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        
        // Configure UITableView
        self.tableView.tableHeaderView = self.searchBar
        self.tableView.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView.tableHeaderView?.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.tableView.tableHeaderView?.clipsToBounds = true
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        self.tableView.tableFooterView = UIView()
        
        // Add long press method in tableView
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(deleteChat))
        hold.minimumPressDuration = 0.40
        self.tableView.isUserInteractionEnabled = true
        self.tableView.addGestureRecognizer(hold)
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .allEvents)
        tableView!.addSubview(refresher)
        
        // Tap to dismiss keyboard
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(scrollViewWillBeginDragging))
        swipe.direction = .down
        self.tableView!.isUserInteractionEnabled = true
        self.tableView!.addGestureRecognizer(swipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // MARK: - MasterUI; Reset UITabBar Counts
        let masterUI = MasterUI()
        // Fetch Unread Chats
        masterUI.fetchChatsQueue { (count) in
            if count != 0 {
                if #available(iOS 10.0, *) {
                    self.navigationController?.tabBarController?.tabBar.items?[3].badgeColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                }
                self.navigationController?.tabBarController?.tabBar.items?[3].badgeValue = "\(count)"
            } else {
                self.navigationController?.tabBarController?.tabBar.items?[3].badgeValue = nil
            }
        }
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
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Clear text
        self.searchBar.text = ""
        // Reload data
        fetchQueues()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Search by <username> and <realNameOfUser>
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
                    if self.userObjects.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchObjects.append(object)
                    }
                }
                
                // Reload data
                if self.searchObjects.count != 0 {
                    // Reload data
                    self.tableView.reloadData()
                    self.tableView.emptyDataSetSource = nil
                    self.tableView.emptyDataSetDelegate = nil
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

    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchBar.text != "" {
            // Return searched users
            return searchObjects.count
            
        } else {
            
            if self.chatObjects.count > 0 {
                self.editButton.isEnabled = true
            } else {
                self.editButton.isEnabled = false
            }
            
            // Return friends
            return chatObjects.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatsCell", for: indexPath as IndexPath) as! ChatsCell
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        // Set delegate
        cell.delegate = self
        
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Show read receipts by default
        cell.status.isHidden = false
        
        /*
         IF SEARCHED FOR CHATS
         */
        if searchBar.text != "" {
            
            // Hide read receipts
            cell.status.isHidden = true
            
            // Set usernames of searched users
            if let names = self.searchObjects[indexPath.row].value(forKey: "username") as? String {
                cell.time.text! = names
            }
            
            // (1) Get Profile Photo
            if let proPic = self.searchObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // Set full name
            // Handle optional chaining for user's real name
            if let fullName = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as? String {
                cell.rpUsername.text! = fullName
            } else {
                cell.rpUsername.text! = self.searchObjects[indexPath.row].value(forKey: "username") as! String
            }
            
        } else {
        /*
        ALL CHATS
        */
            // Show read receipets
            cell.status.isHidden = false
            // Show time
            cell.time.isHidden = false
            // Set default font
            cell.rpUsername.font = UIFont(name: "AvenirNext-Medium", size: 17)
            
            // Set time
            let from = self.chatObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPHelpers
            cell.time.text = difference.getFullTime(difference: difference, date: from)

            // If PFUser.currentUser()! received last message
            if (self.chatObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Handle optional chaining for OtherUser's Object and fetch user's data
                // SENDER
                if let sender = self.chatObjects[indexPath.row].object(forKey: "sender") as? PFUser {
                    // Set username
                    cell.rpUsername.text! = sender.value(forKey: "realNameOfUser") as! String
                    
                    // Get and set user's profile photo
                    // Handle optional chaining
                    if let proPic = sender.value(forKey: "userProfilePicture") as? PFFile {
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    }
                    
                    // Set user's object
                    cell.userObject = sender
                }
                
                
                // Set frame depending on whether the message was read or not
                // OtherUser
                // READ (TRUE) ==> Gray Square
                // NOT READ (FALSE) ==> Red Circle
                if self.chatObjects[indexPath.row].value(forKey: "read") as! Bool == true {
                    cell.status.image = UIImage(named: "BubbleOpen")
                } else {
                    cell.status.image = UIImage(named: "BubbleFilled")
                    cell.rpUsername.font = UIFont(name: "AvenirNext-Demibold", size: 17)
                }
            }
            
            
            // If PFUser.currentUser()! sent last message
            if (self.chatObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Fetch user's data
                if let receiver = self.chatObjects[indexPath.row].object(forKey: "receiver") as? PFUser {
                    // Set username
                    cell.rpUsername.text! = receiver.value(forKey: "realNameOfUser") as! String
                    
                    // Get and set user's profile photo
                    // Handle optional chaining
                    if let proPic = receiver.value(forKey: "userProfilePicture") as? PFFile {
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    }
                    
                    // Set user's object
                    cell.userObject = receiver
                }
                
                // Set frame depending on whether the message was read or not
                // OtherUser
                // READ (TRUE) ==> Gray Square
                // NOT READ (FALSE) ==> Red Circle
                if self.chatObjects[indexPath.row].value(forUndefinedKey: "read") as! Bool == true {
                    cell.status.image  = UIImage(named: "SentOpen")
                } else {
                    cell.status.image = UIImage(named: "SentFilled")
                }
            }
            
            
            
            
            
            
            
            
        }
        
        return cell
    }

    // MARK: - UITableView Delegate Method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // SEARCHED
        if searchBar.text != "" {
            // Append to <chatUserObject>
            // and <chatUsername>
            // Append user's object
            chatUserObject.append(self.searchObjects[indexPath.row])
            // Append user's username
            chatUsername.append(self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String)
        } else {
        // CURRENT CHATS
            // RECEIVER
            if (self.chatObjects[indexPath.row].value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                chatUserObject.append(self.chatObjects[indexPath.row].object(forKey: "receiver") as! PFUser)
                chatUsername.append((self.chatObjects[indexPath.row].object(forKey: "receiver") as! PFUser).username!)
            } else if (self.chatObjects[indexPath.row].value(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // SENDER
                chatUserObject.append(self.chatObjects[indexPath.row].object(forKey: "sender") as! PFUser)
                chatUsername.append((self.chatObjects[indexPath.row].object(forKey: "sender") as! PFUser).username!)
            }
        }

        // Push to View controller
        let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
        self.navigationController!.pushViewController(chatRoom, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.95, alpha: 1)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        self.tableView.cellForRow(at: indexPath)?.contentView.backgroundColor = UIColor.white
    }

    // MARK: - UIScrollView Delegate Methods
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Clear text
        self.searchBar.text = ""
        // Clear searchObjects and reload UITableViewData
        self.searchObjects.removeAll(keepingCapacity: false)
        self.tableView.reloadData()
    }
}
