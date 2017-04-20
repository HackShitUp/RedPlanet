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

import DZNEmptyDataSet
import SDWebImage
import SVProgressHUD
import OneSignal

// Array to hold comments
var commentsObject = [PFObject]()

// Define identifier
let commentNotification = Notification.Name("comment")

class Comments: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // AppDelegate
    let appDelegate = AppDelegate()
    
    // Array to hold comment objects
    var comments = [PFObject]()
    // Array to hold likers
    var likers = [PFObject]()
    // Keyboard frame
    var keyboard = CGRect()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Set limit
    var page: Int = 50
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newComment: UITextView!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Reload view depending on content type
        if commentsObject.last!.value(forKey: "contentType") as! String == "tp" {
            // Send Notification to Text Post
            NotificationCenter.default.post(name: textPostNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "ph" {
            // Send Notification to Photo
            NotificationCenter.default.post(name: photoNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "pp" {
            // Send Notification to Profile Photo
            NotificationCenter.default.post(name: profileNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "sh" {
            // Send Notification to Shared Post
            NotificationCenter.default.post(name: sharedPostNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "sp" {
            // Send Notification to Space Post
            NotificationCenter.default.post(name: spaceNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "itm" {
            // Send Notification to ITM
            NotificationCenter.default.post(name: itmNotification, object: nil)
            
        } else if commentsObject.last!.value(forKey: "contentType") as! String == "vi" {
            // Send Notification to Text Post
            NotificationCenter.default.post(name: videoNotification, object: nil)
        }
        
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Query comments
        queryComments()
        
        // End refresher
        refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to reload data
    func reloadData() {
        // Reload news feed
        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "followingNewsfeed"), object: nil)
        NotificationCenter.default.post(name: otherNotification, object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
    }
    
    // Query comments
    func queryComments() {
        
        // Blocked users
        _ = appDelegate.queryRelationships()
        
        // Fetch comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: commentsObject.last!.objectId!)
        comments.includeKey("byUser")
        comments.order(byAscending: "createdAt")
        comments.limit = self.page
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.comments.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "byUser") as! PFUser).objectId!}) {
                        self.comments.append(object)
                    }
                }
                
                // Set DZNEmptyDataSet
                if self.comments.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // MARK: - SVProgressHUD
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
            // Clear text to prevent sending again and set constant before sending for better UX
            let commentText = self.newComment.text!
            // Clear chat
            self.newComment.text!.removeAll()
            
            // Save comment
            let comments = PFObject(className: "Comments")
            comments["byUser"] = PFUser.current()!
            comments["byUsername"] = PFUser.current()!.username!
            comments["commentOfContent"] = commentText
            comments["forObjectId"] = commentsObject.last!.objectId!
            comments["toUser"] = commentsObject.last!.value(forKey: "byUser") as! PFUser
            comments["to"] = commentsObject.last!.value(forKey: "username") as! String
            comments.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    
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
                            
                            // Loop through words to check for # and @ prefixes
                            for var word in commentText.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                                
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
                                                notifications["forObjectId"] = commentsObject.last!.objectId!
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
                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a comment"],
                                                                 "include_player_ids": ["\(object.value(forKey: "apnsId") as! String)"],
                                                                 "ios_badgeType": "Increase",
                                                                 "ios_badgeCount": 1
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
                            
                            
                            // Handle optional chaining for user object
                            if let user = commentsObject.last!.value(forKey: "byUser") as? PFUser {
                                // Handle optional chaining for user's apnsId
                                if user.value(forKey: "apnsId") != nil {
                                    // MARK: - OneSignal
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) commented on your post"],
                                         "include_player_ids": ["\(user["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                    
                                }
                            }

                            
                        } else {
                            print(error?.localizedDescription as Any)

                        }
                    })
                    
                    // Reload data
                    self.reloadData()
                    
                    // Query Comments
                    self.queryComments()
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Query Comments
                    self.queryComments()
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
            self.title = "Comments"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // MARK: - MainUITab
        // Hide button
        rpButton.isHidden = true
    }
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {

        // Define keyboard frame size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            // If table view's origin is 0
            if self.tableView!.frame.origin.y == 0 {
                
                // Move tableView up
                self.tableView!.frame.origin.y -= self.keyboard.height
                
                // Move chatbox up
                self.frontView.frame.origin.y -= self.keyboard.height
                
                // Scroll to the bottom
                if self.comments.count > 0 {
                    let bot = CGPoint(x: 0, y: self.tableView!.contentSize.height - self.tableView!.bounds.size.height)
                    self.tableView.setContentOffset(bot, animated: false)
                }
                
            }
            
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        if self.tableView!.frame.origin.y != 0 {
            // Move table view up
            self.tableView!.frame.origin.y += self.keyboard.height
            // Move chatbox up
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
        let str = "💩\nNo Comments Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]

        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Set placeholder
        self.newComment.text = "Share your comment!"
        self.newComment.textColor = UIColor.lightGray

        // Query Comments
        queryComments()
        
        // Stylize navigation bar
        configureView()
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: commentNotification, object: nil)
        
        // tapRecognizer, placed in viewDidLoad
        let optionsHold = UILongPressGestureRecognizer(target: self, action: #selector(options))
        optionsHold.minimumPressDuration = 0.30
        self.tableView.isUserInteractionEnabled = true
        self.tableView.addGestureRecognizer(optionsHold)
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 70
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Make tableview free-lined
        self.tableView!.tableFooterView = UIView()
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
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
        // Stylize navigation bar
        configureView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // MARK: - MainUITab
        // Show button
        rpButton.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // Dismiss keyboard when uitable view is scrolled
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder
        self.newComment.resignFirstResponder()
    }
    
    // MARK: - UITextViewDelegate Method
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // Send comment
            self.sendComment()
            
            return false
        } else {
            return true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Change color
        self.newComment.textColor = UIColor.black
        // Change newComment text
        if self.newComment.text! != "Share your comment!" {
            self.newComment.text! = self.newComment.text
        } else {
            self.newComment.text! = ""
        }
    }
    
    // Function to show more options
    func options(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {

                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Comment", message: "Options")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.layer.masksToBounds = true
                }
                // Add Cancel button
                dialogController.cancelButtonStyle = { (button,height) in
                    button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.setTitle("CANCEL", for: [])
                    return true
                }
                
                // (1) DELETE
                let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    
                    // Delete Comment
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
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        
                                    } else {
                                        print(error?.localizedDescription as Any)
                                    }
                                })
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    // (1B) Delete comment from table view
                    self.comments.remove(at: indexPath.row)
                    self.tableView!.deleteRows(at: [indexPath], with: .fade)
                })
                
                // (2) REPLY
                let reply = AZDialogAction(title: "Reply", handler: { (dialog) -> Void in
                    // Dismiss
                    dialog.dismiss()
                    // Clear comment box
                    if self.newComment.text == "Share your comment!" {
                        self.newComment.textColor = UIColor.black
                        self.newComment.text! = ""
                    }
                    // Set username in newComment
                    self.newComment.text = "\(self.newComment.text!)" + "@" + "\(self.comments[indexPath.row].value(forKey: "byUsername") as! String)" + " "
                })
                
                // (3)
                let report = AZDialogAction(title: "Report", handler: { (dialog) -> Void in
                    // Show Report
                    let alert = UIAlertController(title: "Report?",
                                                  message: "Are you sure you'd like to report this comment and the user?",
                                                  preferredStyle: .alert)
                    
                    let yes = UIAlertAction(title: "yes",
                                            style: .destructive,
                                            handler: { (alertAction: UIAlertAction!) -> Void in
                                                // REPORT
                                                let report = PFObject(className: "Reported")
                                                report["byUser"] = PFUser.current()!
                                                report["byUsername"] = PFUser.current()!.username!
                                                report["toUser"] = self.comments[indexPath.row].value(forKey: "byUser") as! PFUser
                                                report["toUsername"] = self.comments[indexPath.row].value(forKey: "byUsername") as! String
                                                report["forObjectId"] = self.comments[indexPath.row].objectId!
                                                report["reason"] = "Inappropriate comment."
                                                report.saveInBackground()
                                                
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                                                SVProgressHUD.showSuccess(withStatus: "Reported")
                                                // Dismiss
                                                dialog.dismiss()
                    })
                    
                    let no = UIAlertAction(title: "no",
                                           style: .cancel,
                                           handler: { (alertAction: UIAlertAction!) in
                                            // Dismiss
                                            dialog.dismiss()
                    })
                    
                    alert.addAction(no)
                    alert.addAction(yes)
                    alert.view.tintColor = UIColor.black
                    dialog.present(alert, animated: true, completion: nil)
                })
                
                
                // Determine which options to show dependent on user's objectId
                if (self.comments[indexPath.row].object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    dialogController.addAction(delete)
                } else if (commentsObject.last!.value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    dialogController.addAction(delete)
                    dialogController.addAction(reply)
                    dialogController.addAction(report)
                } else {
                    dialogController.addAction(reply)
                    dialogController.addAction(report)
                }
                
                // Show
                dialogController.show(in: self)
            }
            
        }
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
                        // MARK: - SDWebImage
                        cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
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
                // MARK: - RPHelpers
                cell.time.text = difference.getShortTime(difference: difference, date: from)
                
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
                            self.likers.append(object.object(forKey: "fromUser") as! PFUser)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                    
                    // Set number of likes
                    cell.numberOfLikes.text! = "\(self.likers.count)"
                    
                    
                    // Check whether user has liked it or not
                    if self.likers.contains(where: {$0.objectId == PFUser.current()!.objectId!}) {
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
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.comments.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query friends
            queryComments()
        }
    }
}
