//
//  SendTo.swift
//  Redplanet
//
//  Created by Joshua Choi on 7/5/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import SDWebImage
import SVProgressHUD
import SwipeNavigationController

class SendTo: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SwipeNavigationControllerDelegate {
    
    // MARK: - Class Variable; Used to hold newly created object
    var sendToObject: PFObject?
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // Array to hold users to share with
    var usersToShareWith = [PFObject]()
    
    // Initialize UISearchBar
    var searchBar = UISearchBar()
    // PFQuery limit; pipline method initialization
    var page: Int = 1000000
    
    // Array to hold following
    var abcFollowing = [PFObject]()
    
    var sortedFollowingSections = Dictionary<String, Array<PFObject>>()
    
    
    let alphabet = ["🔍", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    
    private var animals = [AnyHashable: Any]()
    private var animalSectionTitles = [Any]()
    
    
    
    // Array to hold searched
    var searchedUsers = [PFObject]()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendMenu: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func backAction(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        // Fetch Following
        self.fetchFollowing()
    }
    
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func sendAction(_ sender: Any) {
        switch self.usersToShareWith.count {
        case let x where x > 7:
            // Show Alert
            self.showAlert(withStatus: "Exceeded")
        case let x where x > 0:
            // Disable button
            self.sendButton.isEnabled = false
            // Save to <Posts>
            if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                // Traverse PFObject to get object data...
                let postObject = self.sendToObject!
                if let geoPoint = PFUser.current()!.value(forKey: "location") as? PFGeoPoint {
                    postObject["location"] = geoPoint   // add geoLocation...
                }
                postObject.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        // Handle nil textPost
                        if postObject.value(forKey: "textPost") != nil {
                            // MARK: - RPHelpers; check for #'s and @'s
                            let rpHelpers = RPHelpers()
                            rpHelpers.checkHash(forObject: postObject,
                                                forText: (postObject.value(forKey: "textPost") as! String))
                            rpHelpers.checkTags(forObject: postObject,
                                                forText: (postObject.value(forKey: "textPost") as! String),
                                                postType: (postObject.value(forKey: "contentType") as! String))
                        }
                        
                        // Send Notification
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error...")
                    }
                })
            }
            
            // Send to individual people
            for user in self.usersToShareWith {
                if user.objectId! != PFUser.current()!.objectId! {
                    // Switch Statement...
                    switch self.sendToObject!.value(forKey: "contentType") as! String {
                    case "tp":
                        // TEXT POST
                        let textPostChat = PFObject(className: "Chats")
                        textPostChat["sender"] = PFUser.current()!
                        textPostChat["senderUsername"] = PFUser.current()!.username!
                        textPostChat["receiver"] = user
                        textPostChat["receiverUsername"] = user.value(forKey: "username") as! String
                        textPostChat["read"] = false
                        textPostChat["saved"] = false
                        textPostChat["Message"] = self.sendToObject!.value(forKey: "textPost") as! String
                        // Update "CHATS"
                        self.updateChats(withObject: textPostChat, user: user)
                        
                    case "ph":
                        // PHOTO
                        let photoChat = PFObject(className: "Chats")
                        photoChat["sender"] = PFUser.current()!
                        photoChat["senderUsername"] = PFUser.current()!.username!
                        photoChat["receiver"] = user
                        photoChat["receiverUsername"] = user.value(forKey: "username") as! String
                        photoChat["read"] = false
                        photoChat["saved"] = false
                        photoChat["contentType"] = "ph"
                        photoChat["photoAsset"] = self.sendToObject!.value(forKey: "photoAsset") as! PFFile
                        // Update "ChatsQueue"
                        self.updateChats(withObject: photoChat, user: user)
                        
                    case "vi":
                        // VIDEO
                        let videoChat = PFObject(className: "Chats")
                        videoChat["sender"] = PFUser.current()!
                        videoChat["senderUsername"] = PFUser.current()!.username!
                        videoChat["receiver"] = user
                        videoChat["receiverUsername"] = user.value(forKey: "username") as! String
                        videoChat["read"] = false
                        videoChat["saved"] = false
                        videoChat["contentType"] = "vi"
                        videoChat["videoAsset"] = self.sendToObject!.value(forKey: "videoAsset") as! PFFile
                        // Update "ChatsQueue"
                        self.updateChats(withObject: videoChat, user: user)
                        
                    case "itm":
                        // MOMENT
                        let momentChat = PFObject(className: "Chats")
                        momentChat["sender"] = PFUser.current()!
                        momentChat["senderUsername"] = PFUser.current()!.username!
                        momentChat["receiver"] = user
                        momentChat["receiverUsername"] = user.value(forKey: "username") as! String
                        momentChat["contentType"] = "itm"
                        momentChat["read"] = false
                        momentChat["saved"] = false
                        if self.sendToObject!.value(forKey: "photoAsset") != nil {
                            momentChat["photoAsset"] = self.sendToObject!.value(forKey: "photoAsset") as! PFFile
                        } else {
                            momentChat["videoAsset"] = self.sendToObject!.value(forKey: "videoAsset") as! PFFile
                        }
                        // Update "ChatsQueue"
                        self.updateChats(withObject: momentChat, user: user)
                        
                    default:
                        break
                    }
                }
            }
            
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showSuccess(withTitle: "Shared")
            
            // Deallocate CapturedStill.swift
            let capturedStill = CapturedStill()
            capturedStill.clearArrays()
            
            // Clear arrays
            self.usersToShareWith.removeAll(keepingCapacity: false)
            
            // Show center, or pop VC
            if self.navigationController?.restorationIdentifier == "right" || self.navigationController?.restorationIdentifier == "left" {
                // MARK: - SwipeNavigationController; show center VC
                self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
                
            } else if self.navigationController?.restorationIdentifier == "center" {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
            
        case let x where x == 0 :
            // Show alert
            self.showAlert(withStatus: "None")
        default:
            break;
        }
    }
    
    // FUNCTION - MARK: - RPHelpers; update "chatsQueue" and send push notification
    func updateChats(withObject: PFObject?, user: PFObject?) {
        withObject!.saveInBackground(block: { (success: Bool, error: Error?) in
            if success {
                // MARK: - RPHelpers; update chatsQueue; and send push notification
                let rpHelpers = RPHelpers()
                rpHelpers.updateQueue(chatQueue: withObject!, userObject: user)
                rpHelpers.pushNotification(toUser: user, activityType: "from")
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Error Sharing...")
            }
        })
    }
    
    // FUNCTION - Show status alert
    func showAlert(withStatus: String) {
        // Vibrate device
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        // Resign first responder
        self.searchBar.resignFirstResponder()
        
        // Instantiate message variable to show in alert
        var title: String?
        var message: String?
        if withStatus == "Exceeded" {
            title = "Exceeded Maximum Number of Shares"
            message = "You can only share posts with a maximum of 7 people..."
        } else if withStatus == "None" {
            title = "Post or share with friends..."
            message = "You're not sharing with anyone. Sharing is caring!"
        }
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "💩\n\(title!)", message: "\(message!)")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
            button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.layer.masksToBounds = true
        }
        // Add OK button
        dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
        }))
        // Show
        dialogController.show(in: self)
    }
    
    // FUNCTION - Fetch Current User's Following
    func fetchFollowing() {
        // MARK: - AppDelegate; queryRelationships
        _ = appDelegate.queryRelationships()
        
        // Get following
        let following = PFQuery(className: "FollowMe")
        following.whereKey("follower", equalTo: PFUser.current()!)
        following.whereKey("isFollowing", equalTo: true)
        following.includeKeys(["follower", "following"])
        following.order(byDescending: "createdAt")
        following.limit = self.page
        following.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Create array
                var following = [PFObject]()
                // Clear array
                following.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    if !blockedUsers.contains(where: {$0.objectId == (object.object(forKey: "following") as! PFUser).objectId!}) {
                        following.append(object.object(forKey: "following") as! PFUser)
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    self.abcFollowing = following.sorted{ ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String)}
                    
                    for a in self.abcFollowing {
                        
                    }
                    
                    self.tableView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }

    // FUNCTION - Stylize UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Send To..."
        }
        
        // MARK: - RPHelpers; whiten UINavigationBar and roundAllCorners
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - SwipeNavigationControllerDelegate Method
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        let vcCount = self.navigationController?.viewControllers.count
        
        // Center
        if position == .center {
            // Pop 2 VC's and push to bot || pop 1 VC
            if self.navigationController?.viewControllers.count == vcCount {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        // Main UI
        if position == .bottom {
            NotificationCenter.default.post(name: homeNotification, object: nil)
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        // Code
    }
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        // If there are NO following OR searchBar is typing AND thre are no search results...
        if self.abcFollowing.isEmpty || (self.searchBar.isFirstResponder && self.searchedUsers.isEmpty) {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        
        if self.searchBar.text == "" && self.abcFollowing.isEmpty {
            // No Active Chats
            str = "🙊\nNo Followings"
        } else if self.searchedUsers.isEmpty {
            // No Results
            str = "💩\nNo Results"
        }
        
        let font = UIFont(name: "AvenirNext-Medium", size: 30)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - SwipeNavigationControllerDelegate
        self.containerSwipeNavigationController?.delegate = self
        
        // Configure UISearchBar
        searchBar.delegate = self
        searchBar.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        searchBar.barTintColor = UIColor.white
        searchBar.sizeToFit()
        
        // Configure UITableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = self.searchBar
        tableView.tableHeaderView?.layer.borderWidth = 0.5
        tableView.tableHeaderView?.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        tableView.tableHeaderView?.clipsToBounds = true
        tableView.separatorColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        tableView.sectionIndexColor = UIColor.darkGray
        tableView.sectionIndexTrackingBackgroundColor = UIColor.groupTableViewBackground
        
        // Register NIB
        tableView.register(UINib(nibName: "SendToCell", bundle: nil), forCellReuseIdentifier: "SendToCell")
        
        // Implement back swipe method
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backAction))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Fetch Following
        fetchFollowing()
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
        if searchBar.text == "Search" {
            searchBar.text! = ""
        } else {
            searchBar.text! = searchBar.text!
        }
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
                self.searchedUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    if self.abcFollowing.contains(where: {$0.objectId! == object.objectId!}) {
                        self.searchedUsers.append(object)
                    }
                }
                // Reload data
                if self.searchedUsers.count != 0 {
                    // De-allocate DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = nil
                    self.tableView.emptyDataSetDelegate = nil
                    // Reload UITableView
                    self.tableView.reloadData()
                    print("SEARCHED: \(self.searchedUsers)")
                } else {
                    // MARK: - DZNEmptyDataSet
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadEmptyDataSet()
                    self.tableView.reloadData()
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    // MARK: - UITableView DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        if searchBar.text != "" && self.searchBar.isFirstResponder {
            // SEARCHED
            return 1
        } else {
            // MY STORY & FOLLOWING
//            return 2 + 26
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // # of Rows
        var numberOfRows: Int?
        // SEARCHED
        if self.tableView.numberOfSections == 1 && self.searchBar.text != "" {
            numberOfRows = self.searchedUsers.count
        } else if self.tableView.numberOfSections == 2 && section == 0 {
        // MY STORY
            numberOfRows = 1
        } else if self.tableView.numberOfSections == 2 && section == 1 {
        // FOLLOWING
            numberOfRows = self.abcFollowing.count
        }
        
        return numberOfRows!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.backgroundColor = UIColor.white
        header.textColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        header.font = UIFont(name: "AvenirNext-Bold", size: 12)
        header.textAlignment = .left
        if self.tableView.numberOfSections == 1 {
            header.text = "   SEARCHED..."
        } else {
            if section == 0 {
                header.text = "   MY STORY"
            } else {
                header.text = "   FOLLOWING"
            }
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SendToCell") as! SendToCell

        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0, borderColor: UIColor.clear)
        
        switch self.tableView.numberOfSections {
        case 2:
            if indexPath.section == 0 && indexPath.row == 0 {
            // MY STORY
                // (1) Set text
                // Manipulate font size and type of String for UILabel
                let formattedString = NSMutableAttributedString()
                // MARK: - RPExtensions
                _ = formattedString
                    .bold("Post", withFont: UIFont(name: "AvenirNext-Demibold", size: 15))
                    .normal(" to My Story", withFont: UIFont(name: "AvenirNext-Medium", size: 15))
                cell.rpUsername.attributedText = formattedString
                
                // (2) Set Profile Photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                
                // (3) Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}) {
                    cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                    cell.accessoryType = .checkmark
                } else {
                    cell.contentView.backgroundColor = UIColor.white
                    cell.accessoryType = .none
                }
                
            } else {
            // FOLLOWING
                // (1) Set realNameOfUser followed by username
                // Manipulate font size and type of String for UILabel
                let formattedString = NSMutableAttributedString()
                // MARK: - RPExtensions
                _ = formattedString
                    .bold("\(self.abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String)", withFont: UIFont(name: "AvenirNext-Demibold", size: 15))
                    .normal("\n\((self.abcFollowing[indexPath.row].value(forKey: "username") as! String).lowercased())", withFont: UIFont(name: "AvenirNext-Medium", size: 15))
                cell.rpUsername.attributedText = formattedString
                
                // (2) Set Profile Photo
                if let proPic = self.abcFollowing[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (3) Configure selected state
                if self.usersToShareWith.contains(where: {$0.objectId! == self.abcFollowing[indexPath.row].objectId!}) {
                    cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                    cell.accessoryType = .checkmark
                } else {
                    cell.contentView.backgroundColor = UIColor.white
                    cell.accessoryType = .none
                }
            }
            
        case 1:
            // SEARCHED
            // (1) Set realNameOfUser followed by username
            // Manipulate font size and type of String for UILabel
            let formattedString = NSMutableAttributedString()
            // MARK: - RPExtensions
            _ = formattedString
                .bold("\(self.searchedUsers[indexPath.row].value(forKey: "realNameOfUser") as! String)", withFont: UIFont(name: "AvenirNext-Demibold", size: 17))
                .normal("\n\((self.searchedUsers[indexPath.row].value(forKey: "username") as! String).lowercased())", withFont: UIFont(name: "AvenirNext-Medium", size: 17))
            cell.rpUsername.attributedText = formattedString
            
            // (2) Set Profile Photo
            if let proPic = self.searchedUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // (3) Configure selected state
            if self.usersToShareWith.contains(where: {$0.objectId! == self.searchedUsers[indexPath.row].objectId!}) {
                cell.contentView.backgroundColor = UIColor.groupTableViewBackground
                cell.accessoryType = .checkmark
            } else {
                cell.contentView.backgroundColor = UIColor.white
                cell.accessoryType = .none
            }
        default:
            break
        }
        
        
        return cell
    }
    
    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append object to array
        switch self.tableView.numberOfSections {
        case 1:
            // SEARCHED
            // Append searched object
            if !self.usersToShareWith.contains(where: {$0.objectId! == self.searchedUsers[indexPath.row].objectId!}) {
                self.usersToShareWith.append(self.searchedUsers[indexPath.row])
            }
        case 2:
            // MY STORY: Append current user's object
            if indexPath.section == 0 && indexPath.row == 0 && !self.usersToShareWith.contains(where: {$0.objectId! == PFUser.current()!.objectId!}){
                self.usersToShareWith.append(PFUser.current()!)
            } else {
            // FOLLOWING: Sort Following in ABC-Order
                // Append following object
                if !self.usersToShareWith.contains(where: {$0.objectId! == self.abcFollowing[indexPath.row].objectId!}) {
                    self.usersToShareWith.append(self.abcFollowing[indexPath.row])
                }
            }
        default:
            break;
        }
        // Configure selected state
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.groupTableViewBackground
            cell.accessoryType = .checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch self.tableView.numberOfSections {
        case 1:
            // SEARCHED
            // Remove Searched User
            self.searchedUsers.remove(at: self.searchedUsers.index(of: self.searchedUsers[indexPath.row])!)
            // Clear searchBar text
            self.searchBar.text! = ""
            // Query Following
            fetchFollowing()
        case 2:
            // NOT SEARCHED
            if indexPath.section == 0 && indexPath.row == 0 {
                // Remove: PFUser.current()!
                self.usersToShareWith.remove(at: self.usersToShareWith.index(of: PFUser.current()!)!)
            } else {
                // Remove object at index
                if let removalIndex = self.usersToShareWith.index(of: self.abcFollowing[indexPath.row]) {
                    self.usersToShareWith.remove(at: removalIndex)
                }
            }
        default:
            break;
        }
        
        // Configure selected state
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = UIColor.white
            cell.accessoryType = .none
        }
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.alphabet
    }
    
//    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
//    }
    
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.abcFollowing.count {
                // Increase page size to load more posts
                page = page + 50
                // Query friends
                fetchFollowing()
            }
        }
        */
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign first responder
        searchBar.resignFirstResponder()
        // Clear searchBar
        self.searchBar.text! = ""
        // Reload data
        fetchFollowing()
    }

}
