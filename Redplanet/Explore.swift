//
//  Explore.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AudioToolbox
import AVFoundation
import AVKit
import DZNEmptyDataSet

import Parse
import ParseUI
import Bolts
import SDWebImage


/*
 UITableViewController class reinforcing UITableViewDataSource, and UITableViewDelegate methods. This class is a relationship 
 view controller to "MasterUI.swift" and in the 2nd tab-bar. This class presents the following in Explore:
 
 • NEWS: Stories from selected publishers via NewsApi.org.
 • FEATURED POSTS: Posts shared by public accounts.
 • SUGGESTED ACCOUNTS: Accounts that are shuffled like a deck of cards (randomized) and then presented.
 • NEAR ME: Accounts within the current user's PFGeoPoint.
 
 The data is also binded in this class
 
 *** The follow illustrates the hierarchy of views, from left to right presenting the lowest to highest executable configurations in this class:
 
 UICollectionViewCell --> UICollectionView --> UITableViewCell --> UITableView (self)
 */

class Explore: UITableViewController, UISearchBarDelegate {
    
    // Arrays to hold publisherNames and Objects for Stories
    var sourceObjects = [PFObject]() // used for Selected Stories
    var publisherNames = [String]()
    var articles = [AnyObject]()
    
    // Array to hold people
    var featuredPosts = [PFObject]()
    var geocodeUsers = [PFObject]()
    var randomUsers = [PFObject]()
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // UIRefreshControl
    var refresher: UIRefreshControl!
    // PFQuery pipeline method
    var page: Int = 100
    // Boolean to determine randomized query; whether function will fetch public/private accounts
    var switchBool: Bool? = false
    // Titles for header
    var exploreTitles = ["NEWS", "FEATURED", "SUGGESTED ACCOUNTS", "PEOPLE NEAR ME"]
    
    // UISearchBar
    var searchBar = UISearchBar()
    
    func refresh() {
        fetchFeatured()
        self.refresher?.endRefreshing()
    }
    
    @IBAction func contacts(_ sender: Any) {
        // Push to Contacts VC
        let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
        self.navigationController!.pushViewController(contactsVC, animated: true)
    }
    
    @IBAction func invite(_ sender: Any) {
        // Track when user taps the invite button
        Heap.track("TappedInvite", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        // Show Activity
        let textToShare = "Yo this app is 🔥! Follow me on Redplanet, my username is @\(PFUser.current()!.username!)"
        if let myWebsite = NSURL(string: "https://redplanetapp.com/download/") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // FUNCTION - Fetch News
    func fetchNews() {
        
        // Show UIRefreshControl
        self.refresher?.tintColor = UIColor.white
        self.refresher?.beginRefreshing()
        
        let ads = PFQuery(className: "Ads")
        ads.order(byAscending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                
                // Clear arrays
                self.sourceObjects.removeAll(keepingCapacity: false)
                self.publisherNames.removeAll(keepingCapacity: false)
                self.articles.removeAll(keepingCapacity: false)
                for object in objects! {
                    // (1) Append publisherNames, and articles
                    URLSession.shared.dataTask(with: URL(string: object.value(forKey: "URL") as! String)!,
                                               completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                                                if error != nil {
                                                    print(error?.localizedDescription as Any)
                                                    return
                                                }
                                                do  {
                                                    // Traverse JSON data to "Mutable Containers"
                                                    let json = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                                                    // (2) Get Source (publisherNames) --> remove "-" and capitalize first word
                                                    let source = ((json as AnyObject).value(forKey: "source") as! String).replacingOccurrences(of: "-", with: " ")
                                                    self.publisherNames.append(source.localizedCapitalized)
                                                    // (3) Get First Article for each source
                                                    let items = (json as AnyObject).value(forKey: "articles") as? Array<Any>
                                                    let firstSource = items![0]
                                                    self.articles.append(firstSource as AnyObject)
                                                    // (4) Append source object
                                                    self.sourceObjects.append(object)
                                                    
                                                    // Reload data in main thread
                                                    DispatchQueue.main.async {
                                                        self.tableView.reloadData()
                                                    }
                                                    
                                                } catch let error {
                                                    print(error.localizedDescription as Any)
                                                }
                    }) .resume()
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }

    // FUNCTION - Fetch Featured
    func fetchFeatured() {
        let featured = PFQuery(className: "Posts")
        featured.whereKey("byUser", matchesQuery: PFUser.query()!.whereKey("private", equalTo: false))
        // Only fetch Text Post, Photo, or Moment...
        featured.whereKey("contentType", containedIn: ["tp", "ph", "itm"])
        featured.includeKeys(["byUser", "toUser"])
        featured.order(byDescending: "createdAt")
        featured.limit = self.page
        featured.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.featuredPosts.removeAll(keepingCapacity: false)
                for object in objects! {
                    
                    // Configure time to check for "Ephemeral" content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components,
                                                                                 from: object.createdAt!,
                                                                                 to: Date(),
                                                                                 options: [])
                    // Prevent duplicates, and add
                    let users = self.featuredPosts.map{$0.object(forKey: "byUser") as! PFUser}
                    if !users.contains(where: {$0.objectId! == (object.object(forKey: "byUser") as! PFUser).objectId!}) && difference.hour! < 24 {
                        self.featuredPosts.append(object)
                    }
                    
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - Fetch random users
    func fetchRandoms() {
        // Fetch blocked users
        _ = appDelegate.queryRelationships()

        let both = PFQuery.orQuery(withSubqueries:
            [PFUser.query()!.whereKey("private", equalTo: false),
             PFUser.query()!.whereKey("private", equalTo: true)])
        both.limit = self.page
        both.whereKey("proPicExists", equalTo: true)
        both.whereKey("objectId", notEqualTo: "mWwx2cy2H7")
        if switchBool == true {
            both.order(byAscending: "createdAt")
        } else {
            both.order(byDescending: "createdAt")
        }
        both.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.randomUsers.removeAll(keepingCapacity: false)
                let shuffled = objects!.shuffled()
                
                for object in shuffled {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) {
                        self.randomUsers.append(object)
                    }
                }
                
                // Fetch Location
                if PFUser.current()!.value(forKey: "location") != nil {
                    self.fetchNearMe()
                } else {
                    // Vibrate device
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    
                    // MARK: - AZDialogViewController
                    let dialogController = AZDialogViewController(title: "Location Access Denied",
                                                                  message: "Please enable Location access so you can share Moments with geo-filters and help us find your friends better!")
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
                    
                    // Add settings button
                    dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                        // Dismiss
                        dialog.dismiss()
                        // Show Settings
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    }))
                    
                    // Cancel
                    dialogController.cancelButtonStyle = { (button,height) in
                        button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                        button.setTitle("LATER", for: [])
                        return true
                    }
                    
                    dialogController.show(in: self)
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            
            }
        })
    }
    
    // FUNCTION - Fetch near users
    func fetchNearMe() {
        // Find location
        let discover = PFUser.query()!
        discover.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        discover.whereKey("objectId", notContainedIn: self.randomUsers.map {$0.objectId!})
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.order(byDescending: "createdAt")
        discover.limit = self.page
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.geocodeUsers.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) && !self.geocodeUsers.contains(where: {$0.objectId! == object.objectId!}) {
                        self.geocodeUsers.append(object)
                    }
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    // FUNCTION - Stylize and set title of UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Explore"
        }
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure UISearchBar
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Search rp for other humans or posts..."
        self.searchBar.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        self.searchBar.barTintColor = UIColor.white
        self.searchBar.sizeToFit()
        
        // Configure UITableView
        self.tableView.tableHeaderView = self.searchBar
        self.tableView.tableHeaderView?.layer.borderWidth = 0.5
        self.tableView.tableHeaderView?.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.tableView.tableHeaderView?.clipsToBounds = true
        
        // Determine randomized integer that SHUFFLES OBJECTS
        let randomInt = arc4random()
        if randomInt % 2 == 0 {
            // Even
            switchBool = true
        } else {
            // Odd
            switchBool = false
        }
        
        // Call queries
        fetchNews()
        fetchFeatured()
        fetchRandoms()
        
        // Configure UITableView
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refresher)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchBar.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UISearchBar Delegate Methods
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Push to Search
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! Search
        self.navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.exploreTitles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.backgroundColor = UIColor.white
        if section == 0 {
            header.textColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        } else {
            header.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        }
        header.font = UIFont(name: "AvenirNext-Heavy", size: 12)
        header.textAlignment = .left
        header.text = "   \(self.exploreTitles[section])"
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if self.featuredPosts.count == 0 && section == 1 {
            return 0
        } else {
            return 35
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 175
        } else if indexPath.section == 1 && self.featuredPosts.count != 0 {
            return 175
        } else if indexPath.section == 1 && self.featuredPosts.count == 0 {
            return 0
        } else {
            return 125
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tCell = cell as? TableCollectionCell else { return }
        tCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tCell = self.tableView.dequeueReusableCell(withIdentifier: "tableCollectionCell", for: indexPath) as! TableCollectionCell
        tCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
        
        if self.featuredPosts.count == 0 {
            if let featuredCV = tCell.collectionView.viewWithTag(1) as? UICollectionView {
                // MARK: - DZNEmptyDataSet
                featuredCV.emptyDataSetSource = self
                featuredCV.emptyDataSetDelegate = self
                featuredCV.reloadEmptyDataSet()
            }
        }
        
        if self.geocodeUsers.count == 0 {
            if let geocodeCV = tCell.collectionView.viewWithTag(3) as? UICollectionView {
                // MARK: - DZNEmptyDataSet
                geocodeCV.emptyDataSetSource = self
                geocodeCV.emptyDataSetDelegate = self
                geocodeCV.reloadEmptyDataSet()
            }
        }
        return tCell
    }
}


/*
 MARK: - Explore Extensions; UICollectionViewDataSource, UICollectionViewDelegate, DZNEmptyDataSource, and DZNEmptyDelegate Methods
 */
extension Explore: UICollectionViewDelegate, UICollectionViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        var str: String?
        if scrollView.tag == 1 {
            str = "🚀"
        } else if scrollView.tag == 3 {
            str = "💩\nThere's no one near you..."
        }
        let font = UIFont(name: "AvenirNext-Demibold", size: 15)
        let attributeDictionary: [String: AnyObject]? = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: font!]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        var str: String?
        if scrollView.tag == 1 {
            str = "Tap to retry"
        } else if scrollView.tag == 3 {
            str = "Manage Location Access"
        }
        let font = UIFont(name: "AvenirNext-Demibold", size: 12)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str!, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        if scrollView.tag == 1 {
            self.fetchFeatured()
        } else if scrollView.tag == 3 {
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return CGFloat(5)
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 3
    }
    
    
    
    // MARK: - UICollectionView Data Source Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return self.articles.count
        } else if collectionView.tag == 1 {
            return self.featuredPosts.count
        } else if collectionView.tag == 2 {
            return self.randomUsers.count
        } else {
            return self.geocodeUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 0 {
            let nCell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsCell
            
            // Set background color
            nCell.storyCover.backgroundColor = UIColor.groupTableViewBackground
            
            // (1) Set publisher's name
            nCell.publisherName.text = self.publisherNames[indexPath.item]
            
            // (2) Set cover photo
            if let urlToImage = self.articles[indexPath.item].value(forKey: "urlToImage") as? String {
                // MARK: - SDWebImage
                nCell.storyCover.sd_setImage(with: URL(string: urlToImage))
                
            } else {
                nCell.storyCover.image = UIImage()
                nCell.storyCover.backgroundColor = UIColor.randomColor()
            }
            
            // (3) Set title
            if let title = self.articles[indexPath.item].value(forKey: "title") as? String {
                nCell.storyTitle.text = title
            }
            
            // MARK: - RPHelpers
            nCell.storyCover.roundAllCorners(sender: nCell.storyCover)
            nCell.storyTitle.layer.applyShadow(layer: nCell.storyTitle.layer)
            nCell.publisherName.layer.applyShadow(layer: nCell.publisherName.layer)
            
            return nCell

        } else if collectionView.tag == 1 {
            let fCell = collectionView.dequeueReusableCell(withReuseIdentifier: "featuredCell", for: indexPath) as! FeaturedCell
            
            // (1) Set user's name
            if let user = self.featuredPosts[indexPath.item].object(forKey: "byUser") as? PFUser {
                fCell.rpUsername.text = (user.value(forKey: "username") as! String)
            }

            
            // (4) Set mediaPreview or textPreview
            fCell.textPreview.isHidden = true
            fCell.mediaPreview.isHidden = true
            
            // Promoted Posts
            if self.featuredPosts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                fCell.textPreview.text = "\(self.featuredPosts[indexPath.row].value(forKey: "textPost") as! String)"
                fCell.textPreview.isHidden = false
            } else if self.featuredPosts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                fCell.mediaPreview.image = UIImage(named: "CSpacePost")
                fCell.mediaPreview.isHidden = false
                
                
            } else if let photo = self.featuredPosts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
            // PHOTO ASSET
                // MARK: - SDWebImage
                fCell.mediaPreview.sd_setImage(with: URL(string: photo.url!))
                fCell.mediaPreview.isHidden = false
            } else if let video = self.featuredPosts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
            // VIDEO ASSET
                // MARK: - AVPlayer
                let player = AVPlayer(url: URL(string: video.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = fCell.mediaPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                fCell.mediaPreview.contentMode = .scaleAspectFit
                fCell.mediaPreview.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
                fCell.mediaPreview.isHidden = false
            }

            // MARK: - RPExtensions
            fCell.textPreview.roundAllCorners(sender: fCell.textPreview)
            fCell.mediaPreview.roundAllCorners(sender: fCell.mediaPreview)
            
            return fCell
            
        } else {
            let eCell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
            //set contentView frame and autoresizingMask
            eCell.contentView.frame = eCell.bounds
            
            // MARK: - RPHelpers extension
            eCell.rpUserProPic.makeCircular(forView: eCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
            // SUGGESTED
            if collectionView.tag == 2 {
                // (1) Set username
                eCell.rpUsername.text! = (self.randomUsers[indexPath.item].value(forKey: "username") as! String).lowercased()
                // (2) Set fullName
                eCell.rpFullName.text! = (self.randomUsers[indexPath.item].value(forKey: "realNameOfUser") as! String)
                // (3) Get and set profile photo
                // Handle optional chaining
                if let proPic = self.randomUsers[indexPath.item].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    eCell.rpUserProPic.sd_addActivityIndicator()
                    eCell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    eCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (4) Get user's bio
                if let userBio = self.randomUsers[indexPath.item].value(forKey: "userBiography") as? String {
                    eCell.rpUserBio.textColor = UIColor.black
                    eCell.rpUserBio.text = userBio
                } else {
                    eCell.rpUserBio.textColor = UIColor.lightGray
                    eCell.rpUserBio.text = "This human doesn't have a bio yet..."
                }
            } else {
            // GEOCODE
                // (1) Set username
                eCell.rpUsername.text! = (self.geocodeUsers[indexPath.item].value(forKey: "username") as! String).lowercased()
                // (2) Set fullName
                eCell.rpFullName.text! = (self.geocodeUsers[indexPath.item].value(forKey: "realNameOfUser") as! String)
                // (3) Get and set profile photo
                // Handle optional chaining
                if let proPic = self.geocodeUsers[indexPath.item].value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    eCell.rpUserProPic.sd_addActivityIndicator()
                    eCell.rpUserProPic.sd_setIndicatorStyle(.gray)
                    eCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                }
                // (4) Get user's bio
                if let userBio = self.geocodeUsers[indexPath.item].value(forKey: "userBiography") as? String {
                    eCell.rpUserBio.textColor = UIColor.black
                    eCell.rpUserBio.text = userBio
                } else {
                    eCell.rpUserBio.textColor = UIColor.lightGray
                    eCell.rpUserBio.text = "This human doesn't have a bio yet..."
                }
            }
            
            return eCell
        }
    }
    
    // MARK: - UICollectionView Delegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 0 {
        // Track Who Tapped a story
            Heap.track("TappedSelectedStories", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            
            let selectedStoriesVC = self.storyboard?.instantiateViewController(withIdentifier: "selectedStoriesVC") as! SelectedStories
            // Pass data...
            // (1) Publisher Name
            selectedStoriesVC.publisherName = self.publisherNames[indexPath.item]
            // (2) Publisher Logo URL
            if let publisherLogo = self.sourceObjects[indexPath.item].value(forKey: "photo") as? PFFile {
                selectedStoriesVC.logoURL = publisherLogo.url!
            }
            // (3) NewsApi.org source URL
            selectedStoriesVC.sourceURL = (self.sourceObjects[indexPath.item].value(forKey: "URL") as! String)
            
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: selectedStoriesVC)
            self.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)

        } else if collectionView.tag == 1 {
        // FEATURED
            // Append object
            storyObjects.append(self.featuredPosts[indexPath.item])
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            let storiesVC = self.storyboard?.instantiateViewController(withIdentifier: "storiesVC") as! Stories
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storiesVC)
            self.present(UINavigationController(rootViewController: rpPopUpVC), animated: true)
            
        } else if collectionView.tag == 2 {
        // SUGGESTED
            otherObject.append(self.randomUsers[indexPath.item])
            otherName.append(self.randomUsers[indexPath.item].value(forKey: "username") as! String)
            let otherUserVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherUserVC, animated: true)
            
        } else if collectionView.tag == 3 {
        // NEAR ME
            otherObject.append(self.geocodeUsers[indexPath.item])
            otherName.append(self.geocodeUsers[indexPath.item].value(forKey: "username") as! String)
            let otherUserVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherUserVC, animated: true)
        }
    }
}
