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
    
    @IBAction func refresh(_ sender: Any) {
        handleCase()
    }
    
    // Function to query objects based on Switch Case...
    func handleCase() {
        // Configure UI
        self.textView.resignFirstResponder()
        self.commentContainer.isHidden = true
        // Handle switched TwicketSegmentedControl
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchLikes()
            reactionType = "likes"
        case 1:
            fetchComments()
            reactionType = "comments"
            self.commentContainer.isHidden = false
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
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView!.reloadData()
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
            let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
            
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
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textView.text = ""
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()
        }
        return true
    }
    
}
