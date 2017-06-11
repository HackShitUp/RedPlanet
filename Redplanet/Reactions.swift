//
//  Reactions.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Parse
import ParseUI
import Bolts
import DZNEmptyDataSet
import SDWebImage

// Global array to fetch objects
var reactionObject = [PFObject]()

// Define NotificationIdentifier
let reactNotification = Notification.Name("Reactions")


/*
 UIViewController class that allows users to view likes and comments, AND like or unlike a given post.
 The class refers to the LAST value in the array titled "reactionObject" (above) to handle saving and fetching data.
 - Works with "UserCell.swift" and "UserCell.xib" to show people who've liked a given post.
 - Works with "CommentsCell.swift" and the respective UITableViewCell in Storyboard to show all comments for a given post.
 - Works with "ReactionsHeader.swift" and "ReactiosnHeader.xib" for optimal design and UX when liking posts and 
   viewing the number of likes or comments for a given post.
 */

class Reactions: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TwicketSegmentedControlDelegate {

    // Array to hold reactionObjects
    var reactionObjects = [PFObject]()
    
    // AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // Keyboard Frame
    var keyboard = CGRect()
    // Pipeline method
    var page: Int = 50
    // UIRefreshControl
    var refresher: UIRefreshControl!
    
    
    // MARK: - Initialize TwicketSegmentedControl
    let segmentedControl = TwicketSegmentedControl()
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func back(_ sender: Any) {
        // Deallocate class array and variable
        reactionObject.removeAll(keepingCapacity: false)
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reload data
        handleCase()
        // Scroll to top
        self.tableView?.setContentOffset(.zero, animated: true)
    }
    
    // FUNCTION - Query objects based on Switch Case...
    func handleCase() {
        // Handle switched TwicketSegmentedControl
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchComments()
        case 1:
            fetchLikes()
        default:
            break;
        }
    }
    
    // FUNCTION - Fetch likes
    func fetchLikes() {
        // Resign UITextView
        self.textView.resignFirstResponder()
        
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        // Fetch Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
        likes.includeKey("fromUser")
        likes.order(byDescending: "createdAt")
        likes.limit = self.page
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                
                // Clear array
                self.reactionObjects.removeAll(keepingCapacity: false)
                // Append object
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId!}) {
                        self.reactionObjects.append(object)
                    }
                }
                
                // MARK: - DZNEmptyDataSet
                if self.reactionObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                } else {
                    // Reload data in main thread
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FUNCTION - Fetch comments
    func fetchComments() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        // Fetch Comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
        comments.includeKey("byUser")
        comments.order(byDescending: "createdAt")
        comments.limit = self.page
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                
                // Clear array
                self.reactionObjects.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "byUser") as! PFUser).objectId!}) {
                        self.reactionObjects.append(object)
                    }
                }
                // MARK: - DZNEmptyDataSet
                if self.reactionObjects.count == 0 {
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                }
                
                // Main Thread
                DispatchQueue.main.async {
                    self.tableView.layoutIfNeeded()
                    // Reload data
                    self.tableView.reloadData()
                    // Scroll to bottom
                    if self.reactionObjects.count > 0 {
                        self.tableView!.scrollToRow(at: IndexPath(row: self.reactionObjects.count - 1, section: 0), at: .bottom, animated: true)
                        
                    }
                    // Add long press method in tableView
                    let hold = UILongPressGestureRecognizer(target: self, action: #selector(self.handleComment))
                    hold.minimumPressDuration = 0.40
                    self.tableView.isUserInteractionEnabled = true
                    self.tableView.addGestureRecognizer(hold)
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    // FUNCTION - Save comment to server
    @IBAction func sendComment(_ sender: Any) {
        
        // MARK: - TwicketSegmentedControl
        self.segmentedControl.move(to: 0)
        
        if self.textView.text.isEmpty {
            textView.resignFirstResponder()
        } else {
            // Get comment and clear UITextView
            let commentText = self.textView.text!
            self.textView.text!.removeAll()
            
            // Save to Comments
            let comments = PFObject(className: "Comments")
            comments["byUser"] = PFUser.current()!
            comments["byUsername"] = PFUser.current()!.username!
            comments["commentOfContent"] = commentText
            comments["forObjectId"] = reactionObject.last!.objectId!
            comments["toUser"] = reactionObject.last!.object(forKey: "byUser") as! PFUser
            comments["to"] = (reactionObject.last!.object(forKey: "byUser") as! PFUser).username!
            comments.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    
                    // MARK: - RPHelpers; check for Tags
                    let rpHelpers = RPHelpers()
                    rpHelpers.checkTags(forObject: comments, forText: commentText, postType: "co")
                    
                    // Send notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = reactionObject.last!.object(forKey: "byUser") as! PFUser
                    notifications["to"] = (reactionObject.last!.object(forKey: "byUser") as! PFUser).username!
                    notifications["forObjectId"] = reactionObject.last!.objectId!
                    notifications["type"] = "comment"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // Handle optional chaining for user object
                            if let user = reactionObject.last!.object(forKey: "byUser") as? PFUser {
                                // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                let rpHelpers = RPHelpers()
                                rpHelpers.pushNotification(toUser: user, activityType: "commented on your post")
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            
                        }
                    })
                    
                    // Reload data
                    DispatchQueue.main.async {
                        // Get difference to reset UI
                        let difference = self.textView.frame.size.height - self.textView.contentSize.height
                        
                        // Redefine frame of UITextView; textView
                        self.textView.frame.origin.y = self.textView.frame.origin.y + difference
                        self.textView.frame.size.height = self.textView.contentSize.height
                        
                        // Append new comment and reload UITableView data
                        self.reactionObjects.append(comments)
                        self.tableView.layoutIfNeeded()
                        self.tableView.reloadData()
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                    // Reload data
                    DispatchQueue.main.async {
                        self.handleCase()
                    }
                }
            }
        }
    }
    
    // FUNCTION - Handles comment options including Delete, Reply, and Report
    func handleComment(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Comment", message: nil)
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
                    comment.whereKey("byUser", equalTo: self.reactionObjects[indexPath.row].object(forKey: "byUser") as! PFUser)
                    comment.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
                    comment.whereKey("commentOfContent", equalTo: self.reactionObjects[indexPath.row].value(forKey: "commentOfContent") as! String)
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
                                        notifications.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
                                        notifications.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    object.deleteInBackground()
                                                }
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - RPHelpers
                                                let rpHelpers = RPHelpers()
                                                rpHelpers.showError(withTitle: "Network Error")
                                            }
                                        })
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - RPHelpers
                                        let rpHelpers = RPHelpers()
                                        rpHelpers.showError(withTitle: "Network Error")
                                    }
                                })
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showError(withTitle: "Network Error")
                        }
                    })
                    
                    // Delete comment from table view
                    self.reactionObjects.remove(at: indexPath.row)
                    self.tableView!.deleteRows(at: [indexPath], with: .fade)
                })
                
                // (2) REPLY
                let reply = AZDialogAction(title: "Reply", handler: { (dialog) -> Void in
                    // Dismiss
                    dialog.dismiss()
                    // Clear comment box
                    if self.textView.text == "Tap to share your comment..." {
                        self.textView.textColor = UIColor.black
                        self.textView.text! = ""
                    }
                    // Set username in newComment
                    self.textView.text = "\(self.textView.text!)" + "@" + "\(self.reactionObjects[indexPath.row].value(forKey: "byUsername") as! String)" + " "
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
                                                report["toUser"] = self.reactionObjects[indexPath.row].object(forKey: "byUser") as! PFUser
                                                report["toUsername"] = self.reactionObjects[indexPath.row].value(forKey: "byUsername") as! String
                                                report["forObjectId"] = self.reactionObjects[indexPath.row].objectId!
                                                report["reason"] = "Inappropriate comment."
                                                report.saveInBackground()
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
                if (self.reactionObjects[indexPath.row].object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    dialogController.addAction(delete)
                } else if (reactionObject.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
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
    
    // FUNCTION - Like Post
    func likeAction(sender: UIButton) {
        if self.reactionObjects.map({ $0.object(forKey: "fromUser") as! PFUser}).contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
        // UNLIKE POST
            self.unlikePost(forObject: reactionObject.last!, andButton: sender)
            // Reload data
            DispatchQueue.main.async(execute: {
                self.handleCase()
            })
            
        } else {
        // LIKE POST
            self.likePost(forObject: reactionObject.last!, andButton: sender)
            // Reload data
            DispatchQueue.main.async(execute: {
                self.handleCase()
            })
        }
    }

    // MARK: - TwicketSegmentedControl
    func didSelect(_ segmentIndex: Int) {
        // Handle case
        handleCase()
    }
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.reactionObjects.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        if self.segmentedControl.selectedSegmentIndex == 0 {
            str = "💩\nNo Comments Yet."
        } else {
            str = "💩\nNo Likes Yet."
        }
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }


    // MARK: - UIViewController Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // MARK: - RPHelpers; Configure UINavigationBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure sendButton UIButton
        let sendImage = UIImage(cgImage: UIImage(named: "SentFilled")!.cgImage!, scale: 1, orientation: .rightMirrored)
        self.sendButton.setImage(sendImage, for: .normal)
        
        // Set UITextView Delegate
        self.textView.delegate = self
        // Configure UITextView
        // MARK: - RPHelpers
        self.textView.roundAllCorners(sender: self.textView)
        self.textView.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.textView.layer.borderWidth = 1
        self.textView.clipsToBounds = true
        self.textView.text = "Share your comment..."
        self.textView.textColor = UIColor.lightGray

        // MARK: - TwicketSegmentedControl
        let frame = CGRect(x: 0, y: view.frame.height/2 - 20, width: view.frame.width, height: 40)
        segmentedControl.frame = frame
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["Comments", "Likes"])
        segmentedControl.defaultTextColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Bold", size: 12)!
        self.navigationItem.titleView = segmentedControl
        // MARK: - TwicketSegmentedControl; Set delegate
        segmentedControl.delegate = self
        
        // Configure UITableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        tableView.tableFooterView = UIView()
        tableView.allowsSelection = true
        // Register NIBs
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        tableView.register(UINib(nibName: "ReactionsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "ReactionsHeader")
        // Layout UITableView to prevent from snapping downwards...
        self.tableView.layoutIfNeeded()

        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        refresher.addTarget(self, action: #selector(handleCase), for: .valueChanged)
        tableView.addSubview(refresher)
        
        // Implement back swipe method
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        
        // NotificationCenter: Add Observers - (1) Keyboard, (2) Keyboard, (3) Reloading data...
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCase), name: reactNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handle Switch Case
        handleCase()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Remove reactionNotification observer
        NotificationCenter.default.removeObserver(self, name: reactNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: reactNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        // Layout views
        view.setNeedsLayout()
        view.layoutIfNeeded()
        view.layoutSubviews()
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // If table view's origin is 0 AND commenting...
            if self.tableView!.frame.origin.y == 0 {
                // Move UITableView up
                self.tableView!.frame.origin.y -= self.keyboard.height
                self.commentContainer!.frame.origin.y -= self.keyboard.height
            }
            
        }
        
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        if self.tableView!.frame.origin.y != 0 {
            // Move UITableView (tableView), UITextView (textView), and UIView (innerView) down
            self.tableView.frame.origin.y = 0
            self.commentContainer.frame.origin.y += self.keyboard.height
        }
    }
    
    // MARK: - UITextViewDelegate Methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView.textColor == UIColor.lightGray {
            self.textView.text = ""
            self.textView.textColor = UIColor.black
        }
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        // INCREASE UITextView Height
        if textView.contentSize.height > textView.frame.size.height && textView.frame.height < 102 {
            
            // Get difference of frame height
            let difference = textView.contentSize.height - textView.frame.size.height
            
            // Redefine frame of UITextView; textView
            // Subtract 1 for UITextView's height because of the 1 point top margin constraint in Storyboard
            textView.frame.origin.y = textView.frame.origin.y - difference
            textView.frame.size.height = textView.contentSize.height
            
            // Move UITableView up
            self.tableView.frame.origin.y -= difference
            
        } else if textView.contentSize.height < textView.frame.size.height {
            // DECREASE UITextView Height
            
            // Get difference to deduct
            let difference = textView.frame.size.height - textView.contentSize.height
            
            // Redefine frame of UITextView; textView
            textView.frame.origin.y = textView.frame.origin.y + difference
            textView.frame.size.height = textView.contentSize.height
            
            // Move UITableView down
            self.tableView!.frame.origin.y += difference
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()
        }
        return true
    }
    
    
    // MARK: - UITableView Data Source Methods
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ReactionsHeader") as! ReactionsHeader
        header.contentView.backgroundColor = UIColor.white
        header.reactionType.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        header.reactionType.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)

        // Set UITableViewHeaderFooter title
        if self.segmentedControl.selectedSegmentIndex == 0 {
        // n# Comments
            header.likeButton.isHidden = true
            header.reactionType.text = "\(self.reactionObjects.count) Comments"
        } else {
        // n# Likes
            header.likeButton.isHidden = false
            // Configure likeButton
            header.likeButton.addTarget(self, action: #selector(likeAction(sender:)), for: .touchUpInside)
            if reactionObjects.map({ $0.object(forKey: "fromUser") as! PFUser}).contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                header.likeButton.setImage(UIImage(named: "HeartFilled"), for: .normal)
            } else {
                header.likeButton.setImage(UIImage(named: "LikeBlack"), for: .normal)
            }
            header.reactionType.text = "\(self.reactionObjects.count) Likes"
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.reactionObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if self.segmentedControl.selectedSegmentIndex == 0 {
        // COMMENTS
            
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsCell
            cell.delegate = self                                                // Set parent UIViewController
            cell.commentObject = self.reactionObjects[indexPath.row]            // Set PFObject
            cell.updateView(withObject: self.reactionObjects[indexPath.row])    // Update UI
            cell.countLikes(forObject: self.reactionObjects[indexPath.row])     // Count likes
            return cell
        }
        
        if self.segmentedControl.selectedSegmentIndex == 1 {
        // LIKES
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
            
            // MARK: - RPExtensions
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
            // Get and set user's data
            if let user = self.reactionObjects[indexPath.row].value(forKey: "fromUser") as? PFUser {
                // (1) Set realNameOfUser
                cell.rpFullName.text = (user.value(forKey: "realNameOfUser") as! String)
                // (2) Set rpUsername
                cell.rpUsername.text = (user.value(forKey: "username") as! String)
                // (3) Get and set userProfilePicture
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    cell.rpUserProPic.sd_showActivityIndicatorView()
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
            }
            
            return cell
        }
        
        
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }

    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // LIKES
        if self.segmentedControl.selectedSegmentIndex == 1 {
            // Append data
            otherObject.append(self.reactionObjects[indexPath.item].value(forKey: "fromUser") as! PFUser)
            otherName.append((self.reactionObjects[indexPath.item].value(forKey: "fromUser") as! PFUser).value(forKey: "username") as! String)
            let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.groupTableViewBackground
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.white
        }
    }

    // MARK: - UIScrollView Delegate Method
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.textView.resignFirstResponder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on database are > than shown
            if page <= self.reactionObjects.count {
                
                // Increase page size to load more posts
                page = page + 50
                
                // Fetch more objects
                handleCase()
            }
        }
    }
}



// MARK: - RPExtensions; used to like/unlike objects
extension Reactions {
    
    // LIKE POST
    func likePost(forObject: PFObject, andButton: UIButton) {
        // Disable button
        andButton.isUserInteractionEnabled = false
        // SAVE Likes
        let likes = PFObject(className: "Likes")
        likes["fromUser"] = PFUser.current()!
        likes["from"] = PFUser.current()!.username!
        likes["toUser"] = forObject.object(forKey: "byUser") as! PFUser
        likes["to"] = (forObject.object(forKey: "byUser") as! PFUser).username!
        likes["forObjectId"] = forObject.objectId!
        likes.saveInBackground(block: { (success: Bool, error: Error?) in
            if success {
                print("Successfully saved object: \(likes)")
                
                // Re-enable button
                andButton.isUserInteractionEnabled = true
                // Set Button Image
                andButton.setImage(UIImage(named: "HeartFilled"), for: .normal)
                // Animate like button
                UIView.animate(withDuration: 0.6 ,
                               animations: { andButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                               completion: { finish in
                                UIView.animate(withDuration: 0.5) {
                                    andButton.transform = CGAffineTransform.identity
                                }
                })

                // SAVE to Notification
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = forObject.object(forKey: "byUser") as! PFUser
                notifications["to"] = (forObject.object(forKey: "byUser") as! PFUser).username!
                notifications["forObjectId"] = forObject.objectId!
                notifications["type"] = "like \(forObject.value(forKey: "contentType") as! String)"
                notifications.saveInBackground()
                
                // MARK: - RPHelpers; pushNotification
                let rpHelpers = RPHelpers()
                switch forObject.value(forKey: "contentType") as! String {
                    case "tp":
                    rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Text Post")
                    case "ph":
                        rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                                   activityType: "liked your Photo")
                    case "pp":
                        rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                                   activityType: "liked your Profile Photo")
                    case "vi":
                        rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                                   activityType: "liked your Video")
                    case "sp":
                        rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                                   activityType: "liked your Space Post")
                    case "itm":
                        rpHelpers.pushNotification(toUser: forObject.object(forKey: "byUser") as! PFUser,
                                                   activityType: "liked your Moment")
                default:
                    break;
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    
    }
    
    // UNLIKE POST
    func unlikePost(forObject: PFObject, andButton: UIButton) {
        // Disable button
        andButton.isUserInteractionEnabled = false
        // Query PFObject
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
        likes.whereKey("fromUser", equalTo: PFUser.current()!)
        likes.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object.deleteInBackground()
                    
                    // Re-enable button
                    andButton.isUserInteractionEnabled = true
                    // Set Button Image
                    andButton.setImage(UIImage(named: "LikeBlack"), for: .normal)
                    // Animate like button
                    UIView.animate(withDuration: 0.6 ,
                                   animations: { andButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
                                   completion: { finish in
                                    UIView.animate(withDuration: 0.5) {
                                        andButton.transform = CGAffineTransform.identity
                                    }
                    })

                    // Remove from Notifications
                    let notifications = PFQuery(className: "Notifications")
                    notifications.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
                    notifications.whereKey("fromUser", equalTo: PFUser.current()!)
                    notifications.findObjectsInBackground(block: {
                        (objects: [PFObject]?, error: Error?) in
                        if error == nil {
                            for object in objects! {
                                object.deleteInBackground()
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showError(withTitle: "Network Error")
                        }
                    })
                }
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
}
