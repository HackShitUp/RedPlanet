//
//  CurrentUser.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import SDWebImage

// Define identifier
let myProfileNotification = Notification.Name("myProfile")

class CurrentUser: UIViewController, UITableViewDataSource, UITableViewDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate {
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Variable to hold my content
    var stories = [PFObject]()
    // Handle skipped objects for Pipeline
    var skipped = [PFObject]()
    
    // Set pipeline method
    var page: Int = 50
    
    // View to cover tableView when hidden swift
    let cover = UIButton()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shadowView: UIView!
    
    @IBAction func saved(_ sender: Any) {
        let savedVC = self.storyboard?.instantiateViewController(withIdentifier: "savedVC") as! SavedPosts
        self.navigationController?.pushViewController(savedVC, animated: true)
    }
    
    @IBAction func settings(_ sender: Any) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! UserSettings
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // Function to show ShareUI
    func showShareUI() {
        DispatchQueue.main.async {
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
        }
    }
    
    // Function to fetch my content
    func fetchMine() {
        // User's Posts
        let byUser = PFQuery(className: "Newsfeeds")
        byUser.whereKey("byUser", equalTo: PFUser.current()!)
        // User's Space Posts
        let toUser = PFQuery(className:  "Newsfeeds")
        toUser.whereKey("toUser", equalTo: PFUser.current()!)
        // Both
        let newsfeeds = PFQuery.orQuery(withSubqueries: [byUser, toUser])
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.limit = self.page
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.stories.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Set time constraints
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.stories.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                if self.stories.count == 0 {
                    // Add tap method to share something
                    let shareTap = UITapGestureRecognizer(target: self, action: #selector(self.showShareUI))
                    shareTap.numberOfTapsRequired = 1
                    self.cover.isUserInteractionEnabled = true
                    self.cover.addGestureRecognizer(shareTap)
                    // Add Tap
                    self.cover.setTitle("💩 No Posts Today", for: .normal)
                    self.tableView.addSubview(self.cover)
                    self.tableView!.allowsSelection = false
                    self.tableView!.isScrollEnabled = false
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView?.reloadData()
        }
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = PFUser.current()!.username!.lowercased()
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        // Create corner radiuss
        self.navigationController?.view.layer.cornerRadius = 8.00
        self.navigationController?.view.clipsToBounds = true
    }
    
    // Refresh function
    func refresh() {
        // fetch data
        fetchMine()
        // End refresher
        self.refresher.endRefreshing()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize bar
        configureView()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        
        // MARK: - MainUITab Extension
        /*
         Overlay UIButton to push to the camera (ShareUI
         */
        self.view.setButton(container: self.view)
        rpButton.addTarget(self, action: #selector(showShareUI), for: .touchUpInside)

        // Add gradient shadows w/3 colors: super light, ultra light gray, and white
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.shadowView.bounds
        let white1 = UIColor.white.withAlphaComponent(0.01).cgColor
        let white2 = UIColor.white.withAlphaComponent(0.10).cgColor
        let white3 = UIColor.white.withAlphaComponent(0.30).cgColor
        let white4 = UIColor.white.withAlphaComponent(0.50).cgColor
        let white = UIColor.white.withAlphaComponent(1.0).cgColor
        gradientLayer.colors = [white1, white2, white3, white4, white]
        gradientLayer.locations = [0, 0.10, 0.30, 0.50, 1]
        self.shadowView.layer.addSublayer(gradientLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize and set title
        configureView()
        
        // Fetch current user's content
        fetchMine()
        
        // Configure table view
        self.tableView?.backgroundColor = UIColor.white
        self.tableView?.estimatedRowHeight = 65.00
        self.tableView?.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        self.tableView?.tableFooterView = UIView()
        
        // Add refresher
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor.white
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        self.tableView?.addSubview(refresher)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: myProfileNotification, object: nil)
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        // Register NIB
        let nib = UINib(nibName: "CurrentUserHeader", bundle: nil)
        tableView?.register(nib, forHeaderFooterViewReuseIdentifier: "CurrentUserHeader")
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Stylize title
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    
    // MARK: - UITabBarController Delegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    
    
    // MARK: - UITableView Data Source Methods
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // created a constant that stores a registered header
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CurrentUserHeader") as! CurrentUserHeader
        
        // Declare delegate
        header.delegate = self
        
        //set contentView frame and autoresizingMask
        header.frame = header.frame
        
        // Query relationships
        appDelegate.queryRelationships()
        
        // Layout subviews
        header.myProPic.layoutSubviews()
        header.myProPic.layoutIfNeeded()
        header.myProPic.setNeedsLayout()
        
        // Make profile photo circular
        header.myProPic.layer.cornerRadius = header.myProPic.frame.size.width/2.0
        header.myProPic.layer.borderColor = UIColor.lightGray.cgColor
        header.myProPic.layer.borderWidth = 0.5
        header.myProPic.clipsToBounds = true
        
        // (1) Get User's Object
        if let myProfilePhoto = PFUser.current()!["userProfilePicture"] as? PFFile {
            // MARK: - SDWebImage
            header.myProPic.sd_setImage(with: URL(string: myProfilePhoto.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        // (2) Set user's bio and information
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            header.fullName.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            header.userBio.text! = "\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            header.fullName.text! = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
        }
        // Underline fullname
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "\(header.fullName.text!)", attributes: underlineAttribute)
        header.fullName.attributedText = underlineAttributedString
        
        // (3) Set count for posts, followers, and following
        let posts = PFQuery(className: "Newsfeeds")
        posts.whereKey("byUser", equalTo: PFUser.current()!)
        posts.countObjectsInBackground {
            (count: Int32, error: Error?) in
            if error == nil {
                if count == 1 {
                    header.numberOfPosts.setTitle("1\npost", for: .normal)
                } else {
                    header.numberOfPosts.setTitle("\(count)\nposts", for: .normal)
                }
            } else {
                print(error?.localizedDescription as Any)
                header.numberOfPosts.setTitle("posts", for: .normal)
            }
        }
        
        if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("\nfollowers", for: .normal)
        } else if myFollowers.count == 0 {
            header.numberOfFollowers.setTitle("1\nfollower", for: .normal)
        } else {
            header.numberOfFollowers.setTitle("\(myFollowers.count)\nfollowers", for: .normal)
        }
        
        
        if myFollowing.count == 0 {
            header.numberOfFollowing.setTitle("\nfollowing", for: .normal)
        } else if myFollowing.count == 1 {
            header.numberOfFollowing.setTitle("1\nfollowing", for: .normal)
        } else {
            header.numberOfFollowing.setTitle("\(myFollowing.count)\nfollowing", for: .normal)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 8, y: 305, width: 359, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        // Get user's info and bio
        if PFUser.current()!.value(forKey: "userBiography") != nil {
            // Set fullname
            let fullName = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            
            label.text = "\(fullName.uppercased())\n\(PFUser.current()!.value(forKey: "userBiography") as! String)"
        } else {
            label.text = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)\n\(PFUser.current()!.value(forKey: "birthday") as! String)"
        }
        
        label.sizeToFit()
        
        
        // Add cover
        self.cover.frame = CGRect(x: 0, y: CGFloat(375 + label.frame.size.height), width: self.tableView!.frame.size.width, height: self.tableView!.frame.size.height+375+label.frame.size.height)
        self.cover.titleLabel?.lineBreakMode = .byWordWrapping
        self.cover.contentVerticalAlignment = .top
        self.cover.contentHorizontalAlignment = .center
        self.cover.titleLabel?.textAlignment = .center
        self.cover.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
        self.cover.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        self.cover.backgroundColor = UIColor.white
        
        return CGFloat(375 + label.frame.size.height)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
 
    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        self.tableView!.cellForRow(at: indexPath)?.backgroundColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
    }
    
    
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            // If posts on server are > than shown
            if page <= self.stories.count + self.skipped.count {
                // Increase page size to load more posts
                page = page + 50
                // Query content
                fetchMine()
            }
        }
    }
    
    
    
}
