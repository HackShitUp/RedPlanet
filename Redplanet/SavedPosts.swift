//
//  SavedPosts.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/14/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import OneSignal
import SVProgressHUD
import SDWebImage
import SwipeNavigationController

class SavedPosts: UITableViewController, UINavigationControllerDelegate, UITabBarControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // Saved Stories
    var stories = [PFObject]()
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBAction func backButton(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func edit(_ sender: Any) {
        if self.tableView?.isEditing == true {
            self.tableView?.isEditing = false
        } else {
            self.tableView?.isEditing = true
        }
    }
    
    // Function to reload data
    func refresh() {
        self.fetchSaved()
        self.refresher.endRefreshing()
        self.tableView.reloadData()
    }
    
    // Function to fetch saved posts
    func fetchSaved() {
        let saved = PFQuery(className: "Newsfeeds")
        saved.whereKey("byUser", equalTo: PFUser.current()!)
        saved.whereKey("saved", equalTo: true)
        saved.includeKeys(["byUser", "toUser", "pointObject"])
        saved.order(byDescending: "createdAt")
        saved.findObjectsInBackground { 
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // clear array
                self.stories.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.stories.append(object)
                }
                
                // Set DZN
                if self.stories.count == 0 {
                    self.editButton.isEnabled = false
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
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
            self.title = "Saved"
        }
        
        // Configure UINavigationBar via extension
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch saved posts
        fetchSaved()
        
        // Layout
        self.tableView.layoutIfNeeded()
        self.tableView.setNeedsLayout()
        
        // Configure table view
        self.tableView!.estimatedRowHeight = 65.00
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView!.tableFooterView = UIView()
        
        // Add refresher
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.white
        self.tableView?.addSubview(refresher)
        self.refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.stories.count == 0 {
            return true
        } else {
            return false
        }
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Stickers")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "No saved posts yet."
        let font = UIFont(name: "AvenirNext-Medium", size: 25.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Share Something"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    
    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.stories.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("NewsFeedCell", owner: self, options: nil)?.first as! NewsFeedCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
        
        // Set delegate
        cell.delegate = self
        
        // Set PFObject
        cell.postObject = self.stories[indexPath.row]
        
        // (1) Get User's Object
        if let user = self.stories[indexPath.row].value(forKey: "byUser") as? PFUser {
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            // (2) Set rpUsername
            if let fullName = user.value(forKey: "realNameOfUser") as? String{
                cell.rpUsername.text = fullName
            }
        }
        
        // (3) Set time
        let from = self.stories[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        cell.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set mediaPreview or textPreview
        cell.textPreview.isHidden = true
        cell.mediaPreview.isHidden = true
        
        if self.stories[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            cell.textPreview.text = "\(self.stories[indexPath.row].value(forKey: "textPost") as! String)"
            cell.textPreview.isHidden = false
        } else if self.stories[indexPath.row].value(forKey: "contentType") as! String == "sh" {
            cell.mediaPreview.image = UIImage(named: "SharedPostIcon")
            cell.mediaPreview.isHidden = false
        } else if self.stories[indexPath.row].value(forKey: "contentType") as! String == "sp" {
            cell.mediaPreview.image = UIImage(named: "CSpacePost")
            cell.mediaPreview.isHidden = false
        } else {
            if let photo = self.stories[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                cell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
            } else if let video = self.stories[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // MARK: - AVPlayer
                let player = AVPlayer(url: URL(string: video.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = cell.mediaPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                cell.mediaPreview.contentMode = .scaleAspectFit
                cell.mediaPreview.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            cell.mediaPreview.isHidden = false
        }
        // MARK: - RPHelpers
        cell.textPreview.roundAllCorners(sender: cell.textPreview)
        cell.mediaPreview.roundAllCorners(sender: cell.mediaPreview)
        
        return cell
    }
 
    // Mark: UITableView Delegate Methods
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView!.cellForRow(at: indexPath)?.backgroundColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // Swipe to Delete Messages
        let unsave = UITableViewRowAction(style: .normal, title: "Unsave") {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            
            // Show Progress
            SVProgressHUD.setForegroundColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0))
            SVProgressHUD.setBackgroundColor(UIColor.white)
            SVProgressHUD.show(withStatus: "Removing")
           
            // Fetch
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.getObjectInBackground(withId: "\(self.stories[indexPath.row].objectId!)", block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    object!["saved"] = false
                    object!.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            // MARK: - SVProgressHUD
                            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
                            SVProgressHUD.showSuccess(withStatus: "Unsaved")
                            
                            // Delete post from table view
                            self.stories.remove(at: indexPath.row)
                            self.tableView?.deleteRows(at: [indexPath], with: .fade)
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            SVProgressHUD.showError(withStatus: "Error")
                        }
                    })
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - SVProgressHUD
                    SVProgressHUD.showError(withStatus: "Error")
                }
            })
            
            // Refresh
            self.refresh()
        }
        
        // Set background color
        unsave.backgroundColor = UIColor(red:1.00, green:0.19, blue:0.19, alpha:1.0)
        
        return [unsave]
    }

    
        
}
