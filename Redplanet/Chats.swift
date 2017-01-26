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
import SimpleAlert

class Chats: UITableViewController, UISearchBarDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    

    // Boolean to determine what to show in UITableView
    var searchActive: Bool = false
    
    // Chat objects
    var chatObjects = [PFObject]()

    // Page size
    var page: Int = 100
    
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
        chats.limit = self.page
        chats.includeKeys(["receiver", "sender"])
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
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
                if (error?.localizedDescription.hasSuffix("offline."))! {
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
        queryChats()
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
                self.searchNames.removeAll(keepingCapacity: false)
                self.searchObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if self.chatObjects.contains(object) {
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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
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
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if chatObjects.count == 0 {
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
    
    
    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.tableView?.setContentOffset(CGPoint.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set design of navigation bar
        configureView()
        
        // Get chats
        queryChats()
        
        // Add searchbar to header
        self.searchBar.delegate = self
        self.searchBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.searchBar.barTintColor = UIColor.white
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
            return searchObjects.count
            
        } else {
            
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
            cell.time.text = searchNames[indexPath.row]
            
            // Get and set user's profile photo
            searchObjects[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Get Profile Photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
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
                    
                    // Set full name
                    // Handle optional chaining for user's real name
                    if let fullName = object!["realNameOfUser"] as? String {
                        cell.rpUsername.text! = fullName
                    } else {
                        cell.rpUsername.text! = object!["username"] as! String
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
                    if (object?.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (object!.object(forKey: "sender") as! PFUser).objectId! == self.chatObjects[indexPath.row].objectId! {
                        // Handle optional chaining for OtherUser's Object
                        // SENDER
                        if let theSender = object!.object(forKey: "sender") as? PFUser {
                            
                            // Set username
                            cell.rpUsername.text! = theSender["realNameOfUser"] as! String
                            
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
                    if (object!.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (object!.object(forKey: "receiver") as! PFUser).objectId! == self.chatObjects[indexPath.row].objectId! {
                        
                        if let theReceiver = object!.object(forKey: "receiver") as? PFUser {
                            
                            // Set username
                            cell.rpUsername.text! = theReceiver["realNameOfUser"] as! String
                            
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let chatName = self.chatObjects[indexPath.row].value(forKey: "username") as! String
        
        // Swipe to Delete Messages
        let delete = UITableViewRowAction(style: .normal, title: "Delete") {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in

            
            // MARK: - SimpleAlert
            // Present alert
            let alert = AlertController(title: "Delete Conversation Forever?",
                                        message: "Both you and \(chatName.uppercased()) cannot restore this conversation once it's deleted.",
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
                                    style: .destructive,
                                    handler: { (AlertAction) in
                                        
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
                                                
                                                // Query Chats again
                                                self.queryChats()
                                                
                                            } else {
                                                if (error?.localizedDescription.hasSuffix("offline."))! {
                                                    SVProgressHUD.dismiss()
                                                }
                                                
                                                // Query Chats again
                                                self.queryChats()
                                            }
                                        })
            })
            
            let no = AlertAction(title: "no",
                                   style: .cancel,
                                   handler: nil)
            
            
            alert.addAction(no)
            alert.addAction(yes)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)

            
        }
        
        // Set background color
        delete.backgroundColor = UIColor(red:1.00, green:0.19, blue:0.19, alpha:1.0)
        
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
            page = page + 100
            
            // Query friends
            self.queryChats()
        }
    }

}
