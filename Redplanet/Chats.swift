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
    
    // Chat objects
    var chatObjects = [PFObject]()
    var chatters = [PFObject]()
    // Refresher
    var refresher: UIRefreshControl!

    // Page size
    var page: Int = 500000
    
    // Search
    var searchObjects = [PFObject]()

    // Search Bar
    var searchBar = UISearchBar()
    // Boolean to determine what to show in UITableView
    var searchActive: Bool = false
    
    // Bool to show chatscore
    var showScore: Bool = false

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
            
            // Show Progress
            SVProgressHUD.show()
            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
            SVProgressHUD.setBackgroundColor(UIColor.white)
            
            // Delete chats
            let sender = PFQuery(className: "Chats")
            sender.whereKey("sender", equalTo: PFUser.current()!)
            sender.whereKey("receiver", notEqualTo: PFUser.current()!)
            let receiver = PFQuery(className: "Chats")
            receiver.whereKey("receiver", equalTo: PFUser.current()!)
            receiver.whereKey("sender", notEqualTo: PFUser.current()!)
            let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
            chats.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // Dismiss progress
                    SVProgressHUD.dismiss()
                    
                    // Delete all objects
                    PFObject.deleteAll(inBackground: objects, block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Deleted all objects: \(objects)")
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    // Reload data
                    self.fetchChats()
                    
                } else {
                    if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                    
                    // Reload data
                    self.fetchChats()
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
        fetchChats()
        // End refresher
        self.refresher.endRefreshing()
    }
    
    // Query Chats
    func fetchChats() {
        // SubQueries
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", notEqualTo: PFUser.current()!)
        
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", notEqualTo: PFUser.current()!)

        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKeys(["receiver", "sender"])
        chats.limit = self.page
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.chatObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append Sender
                    if (object.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && !self.chatObjects.contains(where: {$0.objectId! == (object.object(forKey: "sender") as! PFUser).objectId!}) {
                        self.chatObjects.append(object["sender"] as! PFUser)
                    }
                    // Append Receiver
                    if (object.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && !self.chatObjects.contains(where: {$0.objectId! == (object.object(forKey: "receiver") as! PFUser).objectId!}) {
                        self.chatObjects.append(object["receiver"] as! PFUser)
                    }
                }// end for loop
                
                // Initialize DZNEmptyDataset
                if self.chatObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.tableFooterView = UIView()
                }
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
                    SVProgressHUD.dismiss()
                }
            }
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    
    // Dismiss keyboard when UITableView is scrolled
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
        fetchChats()
    }
    
    
    
    
    // MARK: - UISearchBarDelegate methods
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Set boolean
        searchActive = true
        
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
                    if self.chatObjects.contains(where: {$0.objectId! == object.objectId!}) {
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
    
    
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Chats"
        }
        
        // Show tab bar controller and show navigation bar
        self.navigationController!.tabBarController!.tabBar.isHidden = false
        self.navigationController!.setNavigationBarHidden(false, animated: true)
        self.navigationController?.tabBarController?.delegate = self
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
    
    // Function to delete chats
    func deleteChat(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {

                let fullName = self.chatObjects[indexPath.row].value(forKey: "realNameOfUser") as! String

                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "\(fullName)",
                    message: "Delete Chat?\nIt can't be restored once it's forever deleted.")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // add image
                dialogController.imageHandler = { (imageView) in
                    if let proPic = self.chatObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                imageView.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    } else {
                        imageView.image = UIImage(named: "Gender Neutral User-100")
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
                    
                    // DELETE CHAT
                    
                    // Show Progress
                    SVProgressHUD.show()
                    SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                    SVProgressHUD.setBackgroundColor(UIColor.white)
                    
                    // Delete chats
                    let sender = PFQuery(className: "Chats")
                    sender.whereKey("sender", equalTo: PFUser.current()!)
                    sender.whereKey("receiver", equalTo: self.chatObjects[indexPath.row])
                    let receiver = PFQuery(className: "Chats")
                    receiver.whereKey("receiver", equalTo: PFUser.current()!)
                    receiver.whereKey("sender", equalTo: self.chatObjects[indexPath.row])
                    let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
                    chats.includeKeys(["receiver", "sender"])
                    chats.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            
                            // Dismiss progress
                            SVProgressHUD.dismiss()
                            
                            // Delete all objects
                            PFObject.deleteAll(inBackground: objects, block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    print("Deleted all objects: \(objects)")
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                            // Delete chat from tableview
                            self.chatObjects.remove(at: indexPath.row)
                            self.tableView!.deleteRows(at: [indexPath], with: .fade)
                            
                            // Reload data
                            self.fetchChats()
                            // Reload data in main thread
                            DispatchQueue.main.async {
                                self.tableView!.reloadData()
                            }
                            
                        } else {
                            if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                                // MARK: - SVProgressHUD
                                SVProgressHUD.dismiss()
                            }
                            // Reload data
                            self.fetchChats()
                        }
                    })
                    
                    dialog.dismiss()
                }))
                // Show
                dialogController.show(in: self)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set design of navigation bar
        configureView()
        // Query chats
        fetchChats()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set design of navigation bar
        configureView()
        
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
        
        cell.delegate = self
        
        // Set layout
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Circular profile photos
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Show read receipts by default
        cell.status.isHidden = false
        
        // If Searched
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
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
            }
            
            // Set full name
            // Handle optional chaining for user's real name
            if let fullName = self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as? String {
                cell.rpUsername.text! = fullName
            } else {
                cell.rpUsername.text! = self.searchObjects[indexPath.row].value(forKey: "username") as! String
            }
            
        } else {
            
            // Show read receipets
            cell.status.isHidden = false
            // Show time
            cell.time.isHidden = false
            // Set default font
            cell.rpUsername.font = UIFont(name: "AvenirNext-Medium", size: 17)
            
            // Order by most recent
            // Read reciepts
            let sender = PFQuery(className: "Chats")
            sender.whereKey("sender", equalTo: PFUser.current()!)
            sender.whereKey("receiver", equalTo: self.chatObjects[indexPath.row])
            
            let receiver = PFQuery(className: "Chats")
            receiver.whereKey("receiver", equalTo: PFUser.current()!)
            receiver.whereKey("sender", equalTo: self.chatObjects[indexPath.row])
            
            let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
            chats.includeKeys(["sender", "receiver"])
            chats.order(byDescending: "createdAt")
            chats.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // Set time
                    let from = object!.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        cell.time.text = "right now"
                    } else if difference.second! > 0 && difference.minute! == 0 {
                        if difference.second! == 1 {
                            cell.time.text = "1 second ago"
                        } else {
                            cell.time.text = "\(difference.second!) seconds ago"
                        }
                    } else if difference.minute! > 0 && difference.hour! == 0 {
                        if difference.minute! == 1 {
                            cell.time.text = "1 minute ago"
                        } else {
                            cell.time.text = "\(difference.minute!) minutes ago"
                        }
                    } else if difference.hour! > 0 && difference.day! == 0 {
                        if difference.hour! == 1 {
                            cell.time.text = "1 hour ago"
                        } else {
                            cell.time.text = "\(difference.hour!) hours ago"
                        }
                    } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        if difference.day! == 1 {
                            cell.time.text = "1 day ago"
                        } else {
                            cell.time.text = "\(difference.day!) days ago"
                        }
                    } else if difference.weekOfMonth! > 0 {
                        let createdDate = DateFormatter()
                        createdDate.dateFormat = "MMM d, yyyy"
                        cell.time.text = createdDate.string(from: object!.createdAt!)
                    }
                    
                    // If PFUser.currentUser()! received last message
                    if (object?.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (object!.object(forKey: "sender") as! PFUser).objectId! == self.chatObjects[indexPath.row].objectId! {
                        // Handle optional chaining for OtherUser's Object
                        // SENDER
                        if let theSender = object!.object(forKey: "sender") as? PFUser {
                            
                            // Set username
                            cell.rpUsername.text! = theSender["realNameOfUser"] as! String
                            
                            // Get and set user's profile photo
                            // Handle optional chaining
                            if let proPic = theSender["userProfilePicture"] as? PFFile {
                                // MARK: - SDWebImage
                                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                            }
                            
                            // Set user's object
                            cell.userObject = theSender
                        }
                        
                        // Set frame depending on whether the message was read or not
                        // OtherUser
                        // READ (TRUE) ==> Gray Square
                        // NOT READ (FALSE) ==> Red Circle
                        if object!["read"] as! Bool == true {
                            cell.status.image = UIImage(named: "RPSpeechBubble")
                        } else {
                            cell.status.image = UIImage(named: "RPSpeechBubbleFilled")
                            cell.rpUsername.font = UIFont(name: "AvenirNext-Demibold", size: 17)
                        }
                    }
                    
                    
                    // If PFUser.currentUser()! sent last message
                    if (object!.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (object!.object(forKey: "receiver") as! PFUser).objectId! == self.chatObjects[indexPath.row].objectId! {
                        
                        if let theReceiver = object!.object(forKey: "receiver") as? PFUser {
                            // Set username
                            cell.rpUsername.text! = theReceiver["realNameOfUser"] as! String
                            
                            // Get and set user's profile photo
                            // Handle optional chaining
                            if let proPic = theReceiver["userProfilePicture"] as? PFFile {
                                // MARK: - SDWebImage
                                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                            }
                            
                            // Set user's object
                            cell.userObject = theReceiver
                        }
                        
                        // Set frame depending on whether the message was read or not
                        // OtherUser
                        // READ (TRUE) ==> Gray Square
                        // NOT READ (FALSE) ==> Red Circle
                        if object!["read"] as! Bool == true {
                            cell.status.image  = UIImage(named: "Sent-100")
                        } else {
                            cell.status.image = UIImage(named: "Sent Filled-100")
                        }
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                }
            })
        }
        
        
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // If user is searching...
        if searchActive == true && searchBar.text != "" {
            // Append to <chatUserObject>
            // and <chatUsername>
            // Append user's object
            chatUserObject.append(self.searchObjects[indexPath.row])
            // Append user's username
            chatUsername.append(self.searchObjects[indexPath.row].value(forKey: "realNameOfUser") as! String)
            // Push View controller
            let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
            self.navigationController!.pushViewController(chatRoom, animated: true)
        } else {
            // Append...
            // (1) User's Object
            chatUserObject.append(self.chatObjects[indexPath.row])
            // (2) Username
            chatUsername.append(self.chatObjects[indexPath.row].value(forKey: "username") as! String)
            // Push View controller
            let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
            self.navigationController!.pushViewController(chatRoom, animated: true)
        }
    } // end didSelectRowAt method
 

    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= chatObjects.count {
            // Increase page size to load more posts
            page = page + 500000
            // Query friends
            self.fetchChats()
        }
    }
    
    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -140.00 {
            refresher.endRefreshing()
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        } else {
            refresh()
        }
    }
}
