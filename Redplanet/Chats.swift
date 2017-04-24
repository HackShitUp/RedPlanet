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
import SVProgressHUD
import SwipeNavigationController

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
    // Boolean to determine what to show in UITableView
    var searchActive: Bool = false
    // Refresher
    var refresher: UIRefreshControl!
    // Page size
    var page: Int = 50
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editAction(_ sender: Any) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Delete all Chats?",
            message: "They can never be restored once they're deleted.")
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

            // MARK: - SVProgressHUD
            SVProgressHUD.show()
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
            SVProgressHUD.setBackgroundColor(UIColor.white)
            
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
                    
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                    
                    for object in objects! {
                        object.remove(forKey: "lastChat")
                        object.saveInBackground()
                    }
                    
                    // Reload data
                    self.fetchQueues()

                } else {
                    if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
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
         // Show new view controller
        let newChatsVC = self.storyboard?.instantiateViewController(withIdentifier: "newChats") as! NewChats
        self.navigationController!.pushViewController(newChatsVC, animated: true)
    }
    
    // Refresh function
    func refresh() {
        // Reload data
        fetchQueues()
        // End refresher
        self.refresher.endRefreshing()
    }
    
    // Query Parse; <ChatsQueue>
    func fetchQueues() {
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
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
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
                // MARK: - DZNEmptyDataSet
                if self.chatObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                }

            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView.reloadData()
        })
    }

    
    func showChatRoom() {
        // Push View controller
        let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
        self.navigationController!.pushViewController(chatRoom, animated: true)
    }
    
    
    // Function to load more
    func loadMore() {
        // If posts on server are > than shown
        if page <= chatObjects.count {
            // Increase page size to load more posts
            page = page + 500000
            // Query friends
            self.fetchQueues()
        }
    }
    
    // Function to delete chats
    func deleteChat(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {
                
                let fullName = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "\(fullName)",
                    message: "Delete Chat?\nIt can't be restored once it's forever deleted.")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // add image
                dialogController.imageHandler = { (imageView) in
                    if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                imageView.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
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
                    // MARK: - SVProgressHUD
                    SVProgressHUD.show()
                    SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
                    SVProgressHUD.setBackgroundColor(UIColor.white)
                    
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
                            
                            // MARK: - SVProgressHUD
                            SVProgressHUD.dismiss()
                            
                            for object in objects! {
                                object.remove(forKey: "lastChat")
                                object.saveInBackground()
                                
                                // Delete chat from tableview
                                self.chatObjects.remove(at: indexPath.row)
                                self.tableView!.deleteRows(at: [indexPath], with: .fade)
                                
                                // Reload data
                                self.fetchQueues()
                                // Reload data in main thread
                                DispatchQueue.main.async {
                                    self.tableView!.reloadData()
                                }
                            }
                        } else {
                            if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                                // MARK: - SVProgressHUD
                                SVProgressHUD.dismiss()
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
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
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

    
    // MARK: DZNEmptyDataSet Framework
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if chatObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙊\nNo Active Chats"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
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
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        self.tableView.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView.tableHeaderView?.layer.borderColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0).cgColor
        self.tableView.tableHeaderView?.clipsToBounds = true
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView.tableFooterView = UIView()
        
        // Add long press method in tableView
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(deleteChat))
        hold.minimumPressDuration = 0.40
        self.tableView.isUserInteractionEnabled = true
        self.tableView.addGestureRecognizer(hold)
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        tableView!.addSubview(refresher)
        
        // Tap to dismiss keyboard
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(scrollViewWillBeginDragging))
        swipe.direction = .down
        self.tableView!.isUserInteractionEnabled = true
        self.tableView!.addGestureRecognizer(swipe)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        // Set boolean
        searchActive = true
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
                    self.tableView!.reloadData()
                    // Set background for tableView
                    self.tableView!.backgroundView = UIImageView()
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

    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchActive == true && searchBar.text != "" {
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
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Show read receipts by default
        cell.status.isHidden = false
        
        /*
         IF SEARCHED FOR CHATS
         */
        if searchActive == true && searchBar.text != "" {
            
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

        // If user is searching...
        if searchActive == true && searchBar.text != "" {
            // Append to <chatUserObject>
            // and <chatUsername>
            // Append user's object
            chatUserObject.append(self.searchObjects[indexPath.row])
            // Append user's username
            chatUsername.append(self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String)
        } else {
            /*
             Append Data
             • chatUserObject: PFObject
             • chatUserName: String
            */
            // RECEIVER
            if (self.chatObjects[indexPath.row].value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                chatUserObject.append(self.chatObjects[indexPath.row].object(forKey: "receiver") as! PFUser)
                chatUsername.append((self.chatObjects[indexPath.row].object(forKey: "receiver") as! PFUser).value(forKey: "username") as! String)
            } else if (self.chatObjects[indexPath.row].value(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // SENDER
                chatUserObject.append(self.chatObjects[indexPath.row].object(forKey: "sender") as! PFUser)
                chatUsername.append((self.chatObjects[indexPath.row].object(forKey: "sender") as! PFUser).value(forKey: "username") as! String)
            }
        }
        // Push VC
        self.showChatRoom()
    }

    // MARK: - UIScrollView Delegate Methods
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder status
        self.searchBar.resignFirstResponder()
        // Clear text
        self.searchBar.text! = ""
        // Set Boolean
        searchActive = false
        // Set tableView
        self.tableView.backgroundView = UIView()
        // Reload data
        fetchQueues()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            refresh()
        }
    }
}
