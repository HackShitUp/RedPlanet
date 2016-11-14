//
//  Comments.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/25/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet
import OneSignal


// Array to hold comments
var commentsObject = [PFObject]()


// Define identifier
let commentNotification = Notification.Name("comment")


class Comments: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold comment objects
    var comments = [PFObject]()
    
    // Array to hold likers
    var likers = [PFObject]()
    
    
    // Keyboard frame
    var keyboard = CGRect()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newComment: UITextView!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Reload view depending on content type
        if commentsObject.last!.value(forKey: "photoAsset") != nil {
            // Send Notification to Photo
            NotificationCenter.default.post(name: photoNotification, object: nil)
        } else {
            // Send Notification to Text Post
            NotificationCenter.default.post(name: textPostNotification, object: nil)
        }
        
        
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Query comments
        queryComments()
        
        // End refresher
        refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Query comments
    func queryComments() {
        
        // Fetch comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: commentsObject.last!.objectId!)
        comments.includeKey("byUser")
        comments.order(byDescending: "createdAt")
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.comments.removeAll(keepingCapacity: false)
                
                
                for object in objects! {
                    self.comments.append(object)
                }
                
                // Set DZNEmptyDataSet
                if self.comments.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    
    
    // Send comment
    func sendComment() {
        if self.newComment.text!.isEmpty {
            // Resign first responder
            self.newComment.resignFirstResponder()
        } else {
            let comments = PFObject(className: "Comments")
            comments["byUser"] = PFUser.current()!
            comments["byUsername"] = PFUser.current()!.username!
            comments["commentOfContent"] = self.newComment.text!
            comments["forObjectId"] = commentsObject.last!.objectId!
            comments["toUser"] = commentsObject.last!.value(forKey: "byUser") as! PFUser
            comments["to"] = commentsObject.last!.value(forKey: "username") as! String
            comments.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved comment: \(comments)")
                    
                    
                    // Send notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = commentsObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["to"] = commentsObject.last!.value(forKey: "username") as! String
                    notifications["forObjectId"] = commentsObject.last!.objectId!
                    notifications["type"] = "comment"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved notificaiton: \(notifications)")
                            
                            
                            
                            // Hashtags only exist for shared content, not comments :/
                            // Check for user mentions...
                            let words: [String] = self.newComment.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                            // Loop through words to check for # and @ prefixes
                            for var word in words {
                                
                                // Define @username
                                if word.hasPrefix("@") {
                                    // Get username
                                    word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                    word = word.trimmingCharacters(in: CharacterSet.symbols)
                                    
                                    // Look for user
                                    let user = PFUser.query()!
                                    user.whereKey("username", equalTo: word.lowercased())
                                    user.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                
                                                // Send mention to Parse server, class "Notifications"
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["fromUser"] = PFUser.current()!
                                                notifications["type"] = "tag co"
                                                notifications["forObjectId"] = comments.objectId!
                                                notifications["to"] = word
                                                notifications["toUser"] = object
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved tag in notifications: \(notifications)")
                                                        
                                                        
                                                        // Handle optional chaining
                                                        if object.value(forKey: "apnsId") != nil {
                                                            // Send push notification
                                                            OneSignal.postNotification(
                                                                ["contents":
                                                                    ["en": "\(PFUser.current()!.username!) tagged you in a comment"],
                                                                 "include_player_ids": ["\(object.value(forKey: "apnsId") as! String)"]
                                                                ]
                                                            )
                                                        }
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                    }
                                                })
                                                
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                    
                                }
                            }
                            
                            
                            // Query Comments
                            self.queryComments()
                            
                            // Handle optional chaining for user object
                            if let user = commentsObject.last!.value(forKey: "byUser") as? PFUser {
                                // Handle optional chaining for user's apnsId
                                if user["apnsId"] != nil {
                                    // MARK: - OneSignal
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) commented on your content"],
                                         "include_player_ids": ["\(user["apnsId"] as! String)"]
                                        ]
                                    )
                                    
                                }
                            }
                            
                            // Clear text
                            self.newComment.text! = ""
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }

        }
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Comments"
        }
    }
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        keyboard = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
        
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // Raise Text View
            //            self.frontView.frame.origin.y = self.tableView.frame.size.height - self.keyboard.height
            self.frontView.frame.origin.y -= self.keyboard.height
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // Lower Text View
            //            self.frontView.frame.origin.y = self.tableView.frame.size.height
            self.frontView.frame.origin.y += self.keyboard.height
        }
    }
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.comments.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🤔\nNo Comments"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Show Progress
        SVProgressHUD.show()

        // Query Comments
        queryComments()
        
        // Stylize navigation bar
        configureView()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: commentNotification, object: nil)
        
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 70
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Make tableview free-lined
        self.tableView!.tableFooterView = UIView()
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView!.addSubview(refresher)
        
        
        // Catch notification if the keyboard is shown or hidden
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Stylize navigation bar
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Stylize navigation bar
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    // Dismiss keyboard when uitable view is scrolled
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder
        self.newComment.resignFirstResponder()
    }
    
    
    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear placeholder
        self.newComment.text! = ""
    }
    
    

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // Send comment
            sendComment()
            
            return false
        }
        
        
        return true
    }
    
    
    
    
    // MARK: - UITableViewDataSource  Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsCell
        
        
        // LayoutViews for rpUserProPic
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // Set default like icon
        cell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
        
        // Set parent vc
        cell.delegate = self
        
        
        // Fetch comments objects
        comments[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Fetch user
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set username
                    cell.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
                    
                    // (B) Get and set profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                            }
                        })
                    } else {
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                    }
                }
                
                
                // (2) Set comment
                cell.comment.text! = object!["commentOfContent"] as! String

                
                // (3) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    cell.time.text = "\(difference.second!)s ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.time.text = "\(difference.minute!)m ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.time.text = "\(difference.hour!)h ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.time.text = "\(difference.day!)d ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    cell.time.text = "\(difference.weekOfMonth!)w ago"
                }
                
                
                // (4) Set count title for likes
                let likes = PFQuery(className: "Likes")
                likes.includeKey("fromUser")
                likes.whereKey("forObjectId", equalTo: self.comments[indexPath.row].objectId!)
                likes.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear arrays
                        self.likers.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            self.likers.append(object["fromUser"] as! PFUser)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                    
                    // Set number of likes
                    cell.numberOfLikes.text! = "\(self.likers.count)"
                    
                    
                    // Check whether user has liked it or not
                    if self.likers.contains(PFUser.current()!) {
                        // unlike
                        cell.likeButton.setTitle("liked", for: .normal)
                        cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        // like
                        cell.likeButton.setTitle("notliked", for: .normal)
                        cell.likeButton.setTitle("Like-100", for: .normal)
                    }
                    
                    
                })
                
                
                // (5) Set comment object
                cell.commentObject = self.comments[indexPath.row]
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        return cell
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsCell
        
        
        // (1) Delete comment
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            let comment = PFQuery(className: "Comments")
                                            comment.whereKey("byUser", equalTo: self.comments[indexPath.row].value(forKey: "byUser") as! PFUser)
                                            comment.whereKey("forObjectId", equalTo: commentsObject.last!.objectId!)
                                            comment.whereKey("commentOfContent", equalTo: self.comments[indexPath.row].value(forKey: "commentOfContent") as! String)
                                            comment.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if success {
                                                                print("Successfully deleted comment: \(object)")
                                                                
                                                                // Delete from Parse: "Notifications"
                                                                let notifications = PFQuery(className: "Notifications")
                                                                notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                                                                notifications.whereKey("type", equalTo: "comment")
                                                                notifications.whereKey("forObjectId", equalTo: commentsObject.last!.objectId!)
                                                                notifications.findObjectsInBackground(block: {
                                                                    (objects: [PFObject]?, error: Error?) in
                                                                    if error == nil {
                                                                        for object in objects! {
                                                                            object.deleteInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("Successfully deleted from notifications: \(object)")
                                                                                } else {
                                                                                    print(error?.localizedDescription as Any)
                                                                                }
                                                                            })
                                                                        }
                                                                    } else {
                                                                        print("ERROR1")
                                                                        print(error?.localizedDescription as Any)
                                                                    }
                                                                })
                                                                
                                                            } else {
                                                                print("ERROR2")
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print("ERROR3")
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                            
                                            // (1B) Delete comment from table view
                                            // use array
                                            self.comments.remove(at: indexPath.row)
                                            self.tableView!.deleteRows(at: [indexPath], with: .fade)
        }
        
        // (2) Quick Replhy
        let reply = UITableViewRowAction(style: .normal,
                                         title: "Reply") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            
                                            // Set username in newComment
                                            self.newComment.text = "\(self.newComment.text!)" + "@" + "\(self.comments[indexPath.row].value(forKey: "byUsername") as! String)" + " "
                                            
                                            // Close cell
                                            self.tableView!.setEditing(false, animated: true)
        
        
        }
        
        
        
        // (3) Block user
        let report = UITableViewRowAction(style: .normal,
                                          title: "Block") { (UITableViewRowAction, indexPath) in
            
            let alert = UIAlertController(title: "Report this comment?",
                                          message: "Are you sure you'd like to report this comment and the user?",
                                          preferredStyle: .alert)
            
            let yes = UIAlertAction(title: "yes",
                                    style: .destructive,
                                    handler: { (alertAction: UIAlertAction!) -> Void in
                                        // I have to manually delete all "blocked objects..." -__-
                                        let block = PFObject(className: "Block_Reported")
                                        block["from"] = PFUser.current()!.username!
                                        block["fromUser"] = PFUser.current()!
                                        block["to"] = cell.rpUsername.titleLabel!.text!
                                        block["forObjectId"] = self.comments[indexPath.row].objectId!
                                        block.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully reported \(block)")
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        // Close cell
                                        tableView.setEditing(false, animated: true)
            })
            
            let no = UIAlertAction(title: "no",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(yes)
            alert.addAction(no)
            
            self.present(alert, animated: true, completion: nil)
            
        }
        
        
        
        
        
        // Set background images
        delete.backgroundColor = UIColor.red
        reply.backgroundColor = UIColor.blue
        report.backgroundColor = UIColor.yellow
        
        
        if self.comments[indexPath.row].value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete]
        } else if commentsObject.last!.value(forKey: "byUser") as! PFUser == PFUser.current()! {
            return [delete, reply, report]
        } else {
            return [reply, report]
        }
    


    } // end edit action
        
        

}
