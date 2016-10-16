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

class Chats: UITableViewController, UISearchBarDelegate {
    

    // Boolean to determine what to show in UITableView
    var searchActive: Bool = false
    
    // User's friends
    var friendProfiles = [PFObject]()
    
    // Chatting with...
    var chatProfiles = [PFObject]()
    
    
    
    // Search
    var searchNames = [String]()
    var searchObjects = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Search Bar
    var searchBar = UISearchBar()

    @IBAction func newChat(sender: AnyObject) {
        // Show new view controller
//        let newChat = self.storyboard?.instantiateViewControllerWithIdentifier("newChat") as! NewChat
//        self.navigationController!.pushViewController(newChat, animated: true)
    }
    
    // Refresh function
    func refresh() {
        // Reload data
        queryChats()
        self.refresher.endRefreshing()
    }
    
    
    // Query Chats
    func queryChats() {
        // SubQueries
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", notEqualTo: PFUser.current()!)
        
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", notEqualTo: PFUser.current()!)
        
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.order(byDescending: "createdAt")
        //        chats.orderByAscending("createdAt")
        chats.includeKey("receiver")
        chats.includeKey("sender")
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friendProfiles.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    if object["receiver"] as! PFUser == PFUser.current()! {
                        self.friendProfiles.append(object["sender"] as! PFUser)
                    }
                    
                    if object["sender"] as! PFUser == PFUser.current()! {
                        self.friendProfiles.append(object["receiver"] as! PFUser)
                    }
                }
                
                
                
            } else {
                print(error?.localizedDescription)
                
                // Dismiss Progress
//                SVProgressHUD.dismiss()
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
        queryChats()
    }
    
    
    
    
    // MARK: - UISearchBarDelegate methods
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
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
                print(error?.localizedDescription)
            }
        })
        
        return true

    }

    
    
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Chats"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
//        SVProgressHUD.show()
        
        
        // Set design of navigation bar
        configureView()
        
        // Add searchbar to header
        self.searchBar.text! = "Search"
        self.searchBar.delegate = self
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        
        
        // Get chats
        queryChats()
        
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView!.addSubview(refresher)

        
        // Tap to dismiss keyboard
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(scrollViewWillBeginDragging))
        swipe.direction = .down
        self.tableView!.isUserInteractionEnabled = true
        self.tableView!.addGestureRecognizer(swipe)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set design of navigation bar
        configureView()
        
        // Hide tab bar controller
        self.navigationController!.tabBarController!.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set design of navigation bar
        configureView()
        
        // Query CHATS
        queryChats()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - UITableViewDataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchActive == true && searchBar.text != "" {
            // Return searched users
            print("Returning: \(self.searchObjects.count)")
            return searchObjects.count
            
        } else {
            
            // Clear array
            self.chatProfiles.removeAll(keepingCapacity: false)
            
            
            // Remove duplicate values in array
            let talkingProfiles = Array(Set(friendProfiles))
            
            // Run for loop to append new non-duplicated array
            for profiles in talkingProfiles {
                chatProfiles.append(profiles)
            }
            
            print("Returning: \(self.chatProfiles.count)")
            // Return friends
            return chatProfiles.count
        }
    }
    

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatsCell", for: indexPath as IndexPath) as! ChatsCell
        
        // Set layout
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Show read receipts by default
        cell.status.isHidden = false
        
        // If Searched
        if searchActive == true && searchBar.text != "" {
            
            // Hide read receipts
            cell.status.isHidden = true
            
            // Set names of searched users
            cell.rpUsername.text = searchNames[indexPath.row]
            
            // Get and set user's profile photo
            let user = PFUser.query()!
            user.whereKey("username", equalTo: searchNames[indexPath.row])
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    
                    // Dismiss Progress
//                    SVProgressHUD.dismiss()
                    
                    for object in objects! {
                        if let proPic = object["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    cell.rpUserProPic.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription)
                                }
                            })

                        } else {
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral USer-96")
                        }
                        
                        // Handle optional chaining for user's real name
                        if let fullName = object["realNameOfUser"] as? String {
                            cell.time.text! = fullName
                        } else {
                            cell.time.text! = ""
                        }
                        
//                        // Get user's apnsId
//                        if object["apnsId"] != nil {
//                            chatsApnsId.append(object["apnsId"] as! String)
//                        } else {
//                            chatsApnsId.append("_")
//                        }
                    }
                    
                    
                } else {
                    print(error?.localizedDescription)
                    // Dismiss Progress
//                    SVProgressHUD.dismiss()
                }
            })
        } else {
            
            // Show read receipets
            cell.status.isHidden = false
            // Show time
            cell.time.isHidden = false
            
            // Order by most recent
            // Read reciepts
            let sender = PFQuery(className: "Chats")
            sender.whereKey("sender", equalTo: PFUser.current()!)
            sender.whereKey("receiver", equalTo: self.chatProfiles[indexPath.row])
            
            let receiver = PFQuery(className: "Chats")
            receiver.whereKey("receiver", equalTo: PFUser.current()!)
            receiver.whereKey("sender", equalTo: self.chatProfiles[indexPath.row])
            
            
            let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
            chats.includeKey("sender")
            chats.includeKey("receiver")
            chats.order(byDescending: "createdAt")
            chats.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    
                    
                    //                    print("\n===\(object!["Message"] as! String)===\n")
                    
                    
                    // Set time
                    let from = object!.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        cell.time.text = "just now"
                    }
                    
                    if difference.second! > 0 && difference.minute! == 0 {
                        cell.time.text = "\(difference.second!) seconds ago"
                    }
                    
                    if difference.minute! > 0 && difference.hour! == 0 {
                        cell.time.text = "\(difference.minute!) minutes ago"
                    }
                    
                    if difference.hour! > 0 && difference.day! == 0 {
                        cell.time.text = "\(difference.hour!) hours ago"
                    }
                    
                    if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        cell.time.text = "\(difference.day!) days ago"
                    }
                    
                    if difference.weekOfMonth! > 0 {
                        cell.time.text = "\(difference.weekOfMonth!) weeks ago"
                    }
                    
                    
                    // If PFUser.currentUser()! received last message
                    if object!["receiver"] as! PFUser == PFUser.current()! && object!["sender"] as! PFUser == self.chatProfiles[indexPath.row] {
                        // Handle optional chaining for OtherUser's Object
                        // SENDER
                        if let theSender = object!["sender"] as? PFUser {
                            // Set username
                            cell.rpUsername.text! = theSender["username"] as! String
                            
                            // Get and set user's profile photo
                            // Handle optional chaining
                            if let proPic = theSender["userProfilePicture"] as? PFFile {
                                proPic.getDataInBackground(block: {
                                    (data: Data?, error: Error?) in
                                    if error == nil {
                                        cell.rpUserProPic.image = UIImage(data: data!)
                                    } else {
                                        print(error?.localizedDescription)
                                    }
                                })
                            } else {
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        }
                        
                        
                        // Set frame depending on whether the message was read or not
                        // OtherUser
                        // READ (TRUE) ==> Gray Square
                        // NOT READ (FALSE) ==> Red Circle
                        if object!["read"] as! Bool == true {
                            cell.status.image = UIImage(named: "RPSpeechBubble")
                        } else {
                            cell.status.image = UIImage(named: "RPSpeechBubbleFilled")
                        }
                        
                        
                    }
                    
                    
                    // If PFUser.currentUser()! sent last message
                    if object!["sender"] as! PFUser == PFUser.current()! && object!["receiver"] as! PFUser  == self.chatProfiles[indexPath.row] {
                        if let theReceiver = object!["receiver"] as? PFUser {
                            // Set username
                            cell.rpUsername.text! = theReceiver["username"] as! String
                            
                            // Get and set user's profile photo
                            // Handle optional chaining
                            if let proPic = theReceiver["userProfilePicture"] as? PFFile {
                                proPic.getDataInBackground(block: {
                                    (data: Data?, error: Error?) in
                                    if error == nil {
                                        cell.rpUserProPic.image = UIImage(data: data!)
                                    } else {
                                        print(error?.localizedDescription)
                                    }
                                })
                            } else {
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
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
                    print(error?.localizedDescription)
                }
            })
        }
        
        
        return cell
    }
    
 
    /*
    // Mark: UITableviewDelegate methods
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let cell = tableView.dequeueReusableCellWithIdentifier("chatsCell", forIndexPath: indexPath) as! ChatsCell
        
        // Delete action
        let delete = UITableViewRowAction(style: .Normal, title: "   ") { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
            // Present alert
            let alert = UIAlertController(title: "Delete?",
                                          message: "Both you AND \(self.chatProfiles[indexPath.row].valueForKey("username") as! String) cannot restore this conversation once it's forever deleted.",
                preferredStyle: .Alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .Destructive,
                                    handler: { (alertAction: UIAlertAction!) in
                                        
                                        // Show Progress
                                        SVProgressHUD.show()
                                        
                                        // Delete in Parse class: "Chats"
                                        let chats = PFQuery(className: "Chats")
                                        chats.includeKey("receiver")
                                        chats.includeKey("sender")
                                        chats.findObjectsInBackgroundWithBlock({
                                            (objects: [PFObject]?, error: NSError?) in
                                            if error == nil {
                                                
                                                // Dismiss
                                                SVProgressHUD.dismiss()
                                                
                                                for object in objects! {
                                                    
                                                    // If recipient is PFUser.currentUser()! && sender is OtherUser()
                                                    if object["receiver"] as! PFUser == PFUser.currentUser()! && object["sender"] as! PFUser == self.chatProfiles[indexPath.row] {
                                                        object.deleteInBackgroundWithBlock({
                                                            (success: Bool, error: NSError?) in
                                                            if success {
                                                                print("Successfully deleted chats: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                            } else {
                                                                print(error?.localizedDescription)
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                            }
                                                        })
                                                        
                                                    }
                                                    
                                                    // If sender is PFUser.currentUser()! && recipient is OtherUser()
                                                    if object["sender"] as! PFUser == PFUser.currentUser()! && object["receiver"] as! PFUser == self.chatProfiles[indexPath.row] {
                                                        object.deleteInBackgroundWithBlock({
                                                            (success: Bool, error: NSError?) in
                                                            if success {
                                                                print("Successfully deleted chats: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                            } else {
                                                                print(error?.localizedDescription)
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                            }
                                                        })
                                                        
                                                    }
                                                    
                                                } // end for loop
                                                
                                                
                                                
                                                // Reload data
                                                self.queryChats()
                                                
                                                // Reload
                                                self.refresh()
                                                
                                            } else {
                                                print(error?.localizedDescription)
                                                
                                                // Dismiss
                                                SVProgressHUD.dismiss()
                                            }
                                        })
                                        
                                        
                                        
            })
            
            let no = UIAlertAction(title: "no",
                                   style: .Default,
                                   handler: nil)
            
            alert.addAction(yes)
            alert.addAction(no)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        delete.backgroundColor = UIColor(patternImage: UIImage(named: "Delete.png")!)
        
        return [delete]
        
    }
    */
    
    
    /*
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = self.tableView!.dequeueReusableCellWithIdentifier("chatsCell", forIndexPath: indexPath) as! ChatsCell
        
        if searchActive == true && searchBar.text != "" {
            // Append to chatObject
            let user = PFUser.query()!
            user.whereKey("username", equalTo: searchNames[indexPath.row])
            user.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) in
                if error == nil {
                    for object in objects! {
                        // Append user's object
                        chatObject.append(object)
                        // Append user's username
                        chatWith.append(self.searchNames[indexPath.row])
                    }
                    
                    // Push View controller
                    let chatRoom = self.storyboard?.instantiateViewControllerWithIdentifier("slackChat") as! SlackChatRoom
                    self.navigationController!.pushViewController(chatRoom, animated: true)
                    
                } else {
                    print(error?.localizedDescription)
                }
            }
            
        } else {
            
            
            // Load VC
            chatObject.append(self.chatProfiles[indexPath.row])
            // Append username
            chatWith.append(self.chatProfiles[indexPath.row].valueForKey("username") as! String)
            
            // Push View controller
            let chatRoom = self.storyboard?.instantiateViewControllerWithIdentifier("slackChat") as! SlackChatRoom
            self.navigationController!.pushViewController(chatRoom, animated: true)
            
            
            
        }
        
    }
 */


}
