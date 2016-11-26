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

import SVProgressHUD
import DZNEmptyDataSet


class Chats: UITableViewController, UISearchBarDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    

    // Boolean to determine what to show in UITableView
    var searchActive: Bool = false
    
    // People the current user is chatting with
    // other user's objects
    // initial
    var initialChatObjects = [PFObject]()
    // Chatting with...
    // Final list; removed duplicate values
    var finalChatObjects = [PFObject]()
    
    
    // Search
    var searchNames = [String]()
    var searchObjects = [PFObject]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Search Bar
    var searchBar = UISearchBar()


    @IBAction func newChat(_ sender: AnyObject) {
         // Show new view controller
        let newChatsVC = self.storyboard?.instantiateViewController(withIdentifier: "newChats") as! NewChats
        self.navigationController!.pushViewController(newChatsVC, animated: true)
    }
    
    // Refresh function
    func refresh() {
        // Reload data
        queryChats()
        
        // End refresher
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
        chats.includeKey("receiver")
        chats.includeKey("sender")
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.initialChatObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    
                    if object["receiver"] as! PFUser == PFUser.current()! {
                        self.initialChatObjects.append(object["sender"] as! PFUser)
                    }
                    
                    if object["sender"] as! PFUser == PFUser.current()! {
                        self.initialChatObjects.append(object["receiver"] as! PFUser)
                    }
                }// end for loop
                
                
                
                // Clear array
                self.finalChatObjects.removeAll(keepingCapacity: false)
                
                
                // Remove duplicate values in array
                let talkingProfiles = Array(Set(self.initialChatObjects))
                
                // Run for loop to append new non-duplicated array
                for profiles in talkingProfiles {
                    self.finalChatObjects.append(profiles)
                }
                
                
                // Initialize DZNEmptyDataset
                if self.finalChatObjects.count == 0 || self.initialChatObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.tableFooterView = UIView()
                }
                
                
                
            } else {
                print(error?.localizedDescription as Any)

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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Chats"
        }
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if finalChatObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙊\nNo Active Chats"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    // Description for empty data set
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Start conversations with your friends by tapping the ✚ icon on the top right."
        let font = UIFont(name: "AvenirNext-Medium", size: 17.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set design of navigation bar
        configureView()
        
        // Get chats
        queryChats()
        
        // Add searchbar to header
        self.searchBar.text! = "Search"
        self.searchBar.delegate = self
        self.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchBar
        
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
        
        
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
        
        // Query chats
        queryChats()
        
        // Hide tab bar controller
        self.navigationController!.tabBarController!.tabBar.isHidden = false
        
        // Show navigation bar
        self.navigationController!.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set design of navigation bar
        configureView()
        
        // Query CHATS
        queryChats()
        
        // Show navigation bar
        self.navigationController!.setNavigationBarHidden(false, animated: true)
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
            
//            // Clear array
//            self.finalChatObjects.removeAll(keepingCapacity: false)
//            
//            
//            // Remove duplicate values in array
//            let talkingProfiles = Array(Set(initialChatObjects))
//            
//            // Run for loop to append new non-duplicated array
//            for profiles in talkingProfiles {
//                finalChatObjects.append(profiles)
//            }
            
            print("Returning: \(self.finalChatObjects.count)")
            // Return friends
            return finalChatObjects.count
        }
    }
    

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatsCell", for: indexPath as IndexPath) as! ChatsCell
        
        
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
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
            
            // Set names of searched users
            cell.rpUsername.text = searchNames[indexPath.row]
            
            // Get and set user's profile photo
            let user = PFUser.query()!
            user.whereKey("username", equalTo: searchNames[indexPath.row])
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {

                    
                    for object in objects! {
                        if let proPic = object["userProfilePicture"] as? PFFile {
                            proPic.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    cell.rpUserProPic.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })

                        } else {
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
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
                    print(error?.localizedDescription as Any)

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
            sender.whereKey("receiver", equalTo: self.finalChatObjects[indexPath.row])
            
            let receiver = PFQuery(className: "Chats")
            receiver.whereKey("receiver", equalTo: PFUser.current()!)
            receiver.whereKey("sender", equalTo: self.finalChatObjects[indexPath.row])
            
            let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
            chats.includeKey("sender")
            chats.includeKey("receiver")
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
                    }
                    
                    if difference.second! > 0 && difference.minute! == 0 {
                        if difference.second! == 1 {
                            cell.time.text = "1 second ago"
                        } else {
                            cell.time.text = "\(difference.second!) seconds ago"
                        }
                    }
                    
                    if difference.minute! > 0 && difference.hour! == 0 {
                        if difference.minute! == 1 {
                            cell.time.text = "1 minute ago"
                        } else {
                            cell.time.text = "\(difference.minute!) minutes ago"
                        }
                    }
                    
                    if difference.hour! > 0 && difference.day! == 0 {
                        if difference.hour! == 1 {
                            cell.time.text = "1 hour ago"
                        } else {
                            cell.time.text = "\(difference.hour!) hours ago"
                        }
                    }
                    
                    if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        if difference.day! == 1 {
                            cell.time.text = "1 day ago"
                        } else {
                            cell.time.text = "\(difference.day!) days ago"
                        }
                    }
                    
                    
                    if difference.weekOfMonth! > 0 {
                        let createdDate = DateFormatter()
                        createdDate.dateFormat = "MMM d, yyyy"
                        cell.time.text = createdDate.string(from: object!.createdAt!)
                    }
                    
                    
                    // If PFUser.currentUser()! received last message
                    if object!["receiver"] as! PFUser == PFUser.current()! && object!["sender"] as! PFUser == self.finalChatObjects[indexPath.row] {
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
                                        print(error?.localizedDescription as Any)
                                    }
                                })
                            } else {
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
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
                    if object!["sender"] as! PFUser == PFUser.current()! && object!["receiver"] as! PFUser  == self.finalChatObjects[indexPath.row] {
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
                                        print(error?.localizedDescription as Any)
                                    }
                                })
                            } else {
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
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
                    print(error?.localizedDescription as Any)
                    
                }
            })
        }
        
        
        return cell
    }
    
 
    
    // Mark: UITableviewDelegate methods
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // Swipe to Delete Messages
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in

            // Present alert
            let alert = UIAlertController(title: "Delete Conversation Forever?",
                                          message: "You AND \(self.finalChatObjects[indexPath.row].value(forKey: "username") as! String) cannot restore this conversation once it's forever deleted.",
                preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .destructive,
                                    handler: { (alertAction: UIAlertAction!) in
                                        
                                        // Show Progress
                                        SVProgressHUD.show()
                                        
                                        // Delete in Parse class: "Chats"
                                        let chats = PFQuery(className: "Chats")
                                        chats.includeKey("receiver")
                                        chats.includeKey("sender")
                                        chats.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                
                                                // Dismiss
                                                SVProgressHUD.dismiss()
                                                
                                                for object in objects! {
                                                    
                                                    // If recipient is PFUser.currentUser()! && sender is OtherUser()
                                                    if object["receiver"] as! PFUser == PFUser.current()! && object["sender"] as! PFUser == self.finalChatObjects[indexPath.row] {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted chats: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                            }
                                                        })
                                                        
                                                    }
                                                    
                                                    // If sender is PFUser.currentUser()! && recipient is OtherUser()
                                                    if object["sender"] as! PFUser == PFUser.current()! && object["receiver"] as! PFUser == self.finalChatObjects[indexPath.row] {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted chats: \(object)")
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                                
                                                                // Dismiss
                                                                SVProgressHUD.dismiss()
                                                            }
                                                        })
                                                        
                                                    }
                                                    
                                                } // end for loop
                                                
                                                // Reload
                                                self.refresh()
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                
                                                // Dismiss
                                                SVProgressHUD.dismiss()
                                            }
                                        })
                                        
                                        
                                        
            })
            
            let no = UIAlertAction(title: "no",
                                   style: .cancel,
                                   handler: nil)
            
            
            alert.addAction(no)
            alert.addAction(yes)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)

            
        }
        
        // Set background color
        delete.backgroundColor =  UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        
        return [delete]
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If user is searching...
        if searchActive == true && searchBar.text != "" {
            // Append to <chatUserObject>
            // and <chatUsername>
            let user = PFUser.query()!
            user.whereKey("username", equalTo: searchNames[indexPath.row])
            user.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append user's object
                        chatUserObject.append(object)
                        // Append user's username
                        chatUsername.append(self.searchNames[indexPath.row])
                    }
                    
                    // Push View controller
                    let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
                    self.navigationController!.pushViewController(chatRoom, animated: true)
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            

            // Append...
            // (1) User's Object
            chatUserObject.append(self.finalChatObjects[indexPath.row])
            // (2) Username
            chatUsername.append(self.finalChatObjects[indexPath.row].value(forKey: "username") as! String)
            
            // Push View controller
            let chatRoom = self.storyboard?.instantiateViewController(withIdentifier: "chatRoom") as! RPChatRoom
            self.navigationController!.pushViewController(chatRoom, animated: true)
            
            
        }
    }
 


}
