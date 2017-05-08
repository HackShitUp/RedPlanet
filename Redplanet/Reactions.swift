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

class Reactions: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TwicketSegmentedControlDelegate {
    
    // MARK: - Class Variable; Determines what to fetch: Likes, Comments, Shares
    var reactionType: String?
    
    // MARK: - TwicketSegmentedControl
    let segmentedControl = TwicketSegmentedControl()
    
    // AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    // Keyboard Frame
    var keyboard = CGRect()
    // Pipeline method
    var page: Int = 50
    // UIRefreshControl
    var refresher: UIRefreshControl!
    // Array to hold reactionObjects
    var reactionObjects = [PFObject]()
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func back(_ sender: Any) {
        // Deallocate class array and variable
        reactionObject.removeAll(keepingCapacity: false)
        reactionType = ""
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Function to query objects based on Switch Case...
    func handleCase() {
        // Configure UI
        self.refresher?.endRefreshing()
        self.textView.resignFirstResponder()
        // Handle switched TwicketSegmentedControl
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchLikes()
            reactionType = "likes"
        case 1:
            fetchComments()
            reactionType = "comments"
        case 2:
            fetchShares()
            reactionType = "shares"
        default:
            break;
        }
    }
    
    // Fetch Likes
    func fetchLikes() {
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
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView!.reloadData()
            }
        }
    }
    
    // Fetch Comments
    func fetchComments() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        // Fetch Comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
        comments.includeKey("byUser")
        comments.order(byAscending: "createdAt")
        comments.limit = self.page
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.reactionObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "byUser") as! PFUser).objectId!}) {
                        self.reactionObjects.append(object)
                    }
                }
                
                // MARK: - DZNEmptyDataSet
                if self.reactionObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView!.reloadData()
            }
        })
    }

    // Fetch Shares
    func fetchShares() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        let shares = PFQuery(className: "Newsfeeds")
        shares.whereKey("pointObject", equalTo: reactionObject.last!)
        shares.includeKey("byUser")
        shares.limit = self.page
        shares.order(byDescending: "createdAt")
        shares.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.reactionObjects.removeAll(keepingCapacity: false)
                // Append objects
                for object in objects! {
                    self.reactionObjects.append(object)
                }
                
                // MARK: - DZNEmptyDataSet
                if self.reactionObjects.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView!.reloadData()
            }
        }
    }
    
    // Function to send comment
    func sendComment() {
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
            comments["toUser"] = reactionObject.last!.value(forKey: "byUser") as! PFUser
            comments["to"] = reactionObject.last!.value(forKey: "username") as! String
            comments.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Send notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = reactionObject.last!.value(forKey: "byUser") as! PFUser
                    notifications["to"] = reactionObject.last!.value(forKey: "username") as! String
                    notifications["forObjectId"] = reactionObject.last!.objectId!
                    notifications["type"] = "comment"
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.checkTags(forObject: comments, forText: commentText)

                            // Handle optional chaining for user object
                            if let user = reactionObject.last!.value(forKey: "byUser") as? PFUser {
                                // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                if user.value(forKey: "apnsId") != nil {
                                    let rpHelpers = RPHelpers()
                                    _ = rpHelpers.pushNotification(toUser: user, activityType: "commented on your post")
                                }
                            }
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            
                        }
                    })
                    
                    // Reload data
                    DispatchQueue.main.async {
                        self.handleCase()
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
            str = "💩\nNo Likes Yet."
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            str = "💩\nNo Comments Yet."
        } else {
            str = "💩\nNo Shares Yet."
        }
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            // Layout views
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            // If table view's origin is 0
            if self.tableView!.frame.origin.y == 0 {
                // Move tableView up
                self.tableView!.frame.origin.y -= self.keyboard.height
                // Move chatbox up
                self.commentContainer.frame.origin.y -= self.keyboard.height
                // Scroll to the bottom
                if self.reactionObjects.count > 0 && self.segmentedControl.selectedSegmentIndex == 1 {
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
            self.commentContainer.frame.origin.y += self.keyboard.height
        }
    }

    // MARK: - UIViewController Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // MARK: - RPExtensions
        self.navigationController?.view.roundAllCorners(sender: self.navigationController?.view)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Configure UINavigationBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Handle Switch Case
        handleCase()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - TwicketSegmentedControl
        let frame = CGRect(x: 5, y: view.frame.height / 2 - 20, width: view.frame.width - 10, height: 40)
        segmentedControl.frame = frame
        segmentedControl.delegate = self
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["Likes", "Comments", "Shares"])
        segmentedControl.defaultTextColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Bold", size: 12)!
        self.navigationItem.titleView = segmentedControl
        
        // Configure UITableView
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 65
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView.tableFooterView = UIView()
        // Register NIB
        self.tableView.register(UINib(nibName: "ReactionsHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "ReactionsHeader")

        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(handleCase), for: .valueChanged)
        self.tableView.addSubview(refresher)
        
        // NotificationCenter: Add Observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UITableView Data Source Methods
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let reactionsHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ReactionsHeader") as! ReactionsHeader
        reactionsHeader.contentView.backgroundColor = UIColor.white
        reactionsHeader.reactionType.font = UIFont(name: "AvenirNext-Demibold", size: 15)
        reactionsHeader.reactionType.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        if self.segmentedControl.selectedSegmentIndex == 0 {
            reactionsHeader.reactionType.text = "\(self.reactionObjects.count) Likes"
            reactionsHeader.reactButton.isHidden = false
            if reactionObjects.map({ $0.object(forKey: "fromUser") as! PFUser}).contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                reactionsHeader.reactButton.setImage(UIImage(named: "LikeFilled"), for: .normal)
            } else {
                reactionsHeader.reactButton.setImage(UIImage(named: "Like"), for: .normal)
            }
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            reactionsHeader.reactionType.text = "\(self.reactionObjects.count) Comments"
            reactionsHeader.reactButton.isHidden = true
        } else {
            reactionsHeader.reactionType.text = "\(self.reactionObjects.count) Shares"
            reactionsHeader.reactButton.isHidden = false
            reactionsHeader.reactButton.setImage(UIImage(named: "Share"), for: .normal)
        }
        
        return reactionsHeader
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
            // Likes
            let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
            
            // (1) Get user's data
            if let user = self.reactionObjects[indexPath.row].value(forKey: "fromUser") as? PFUser {
                // Set user's full name
                cell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // Set user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    cell.rpUserProPic.sd_showActivityIndicatorView()
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPExtensions
                    cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }

            return cell
            
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            // Comments
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsCell
            
            // (1) Get user's data
            if let user = self.reactionObjects[indexPath.row].value(forKey: "byUser") as? PFUser {
                // Set user's full name
                cell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // Set user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    cell.rpUserProPic.sd_showActivityIndicatorView()
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPExtensions
                    cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (2) Set time
            let from = self.reactionObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            // MARK: - RPHelpers
            cell.time.text = difference.getFullTime(difference: difference, date: from)

            // (3) Set comment
            cell.comment.text = (self.reactionObjects[indexPath.row].value(forKey: "commentOfContent") as! String)
            
            return cell
            
        } else {
            // Shares
            let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
            
            // (1) Get user's data
            if let user = self.reactionObjects[indexPath.row].value(forKey: "byUser") as? PFUser {
                // Set user's full name
                cell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // Set user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    cell.rpUserProPic.sd_showActivityIndicatorView()
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPExtensions
                    cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            return cell
        }
    }
    
    // MARK: - UIScrollViewDelegate Methods
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder
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
    
    // MARK: - UITextViewDelegate Methods
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if self.segmentedControl.selectedSegmentIndex == 1 {
            return true
        } else {
            return false
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textView.text = ""
        self.textView.textColor = UIColor.black
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()
            self.sendComment()
        }
        return true
    }
    
}
