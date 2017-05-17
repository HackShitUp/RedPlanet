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

class Explore: UITableViewController, UITextFieldDelegate {
    
    // Arrays to hold publisherNames and Objects for Stories
    var sourceObjects = [PFObject]() // used for Selected Stories
    var publisherNames = [String]()
    var articles = [AnyObject]()
    
    // Array to hold people
    var promotedPosts = [PFObject]()
    var geocodeUsers = [PFObject]()
    var randomUsers = [PFObject]()
    
    // AppDelegate
    let appDelegate = AppDelegate()
    // UIRefreshControl
    var refresher: UIRefreshControl!
    // PFQuery pipeline method
    var page: Int = 30
    // Boolean to determine randomized query; whether function will fetch public/private accounts
    var switchBool: Bool? = false
    // Titles for header
    var exploreTitles = ["News", "Promoted", "Suggested Accounts", "People Near Me"]
    
    @IBOutlet weak var searchBar: UITextField!
    
    func refresh() {
        self.refresher.endRefreshing()
//        fetchNews()
//        fetchPromoted()
//        fetchRandoms()
    }
    
    // (1) Fetch News
    func fetchNews() {
        let ads = PFQuery(className: "Ads")
        ads.order(byAscending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
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

    // (2) Fetch Promoted
    func fetchPromoted() {
        let promoted = PFQuery(className: "Newsfeeds")
        promoted.whereKey("byUser", matchesQuery: PFUser.query()!.whereKey("private", equalTo: false))
        promoted.whereKey("contentType", containedIn: ["tp", "ph", "vi", "itm"])
        promoted.includeKey("byUser")
        promoted.order(byDescending: "createdAt")
        promoted.limit = self.page
        promoted.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.promotedPosts.removeAll(keepingCapacity: false)
                for object in objects! {
                    // TODO:::
                    self.promotedPosts.append(object)
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
    
    // (3) Fetch random users
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
    
    // (4) Fetch near users
    func fetchNearMe() {
        // Find location
        let discover = PFUser.query()!
        discover.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        discover.whereKey("objectId", notContainedIn: self.randomUsers.map {$0.objectId!})
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.order(byAscending: "createdAt")
        discover.limit = self.page
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.geocodeUsers.removeAll(keepingCapacity: false)
                for object in objects! {
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
    
    // MARK: - UIView Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        fetchPromoted()
        fetchRandoms()
        
        // Configure UITableView
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        
        // Configure UITextField
        searchBar.delegate = self
        searchBar.backgroundColor = UIColor.groupTableViewBackground
        searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 32, height: 30)
        searchBar.roundAllCorners(sender: searchBar)
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refresher)
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UITextField Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
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
        header.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        header.font = UIFont(name: "AvenirNext-Bold", size: 12)
        header.textAlignment = .left
        header.text = "      \(self.exploreTitles[section])"
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 || indexPath.section == 1 {
            return 175
        } else {
            return 125
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableCollectionCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tCell = self.tableView.dequeueReusableCell(withIdentifier: "tableCollectionCell", for: indexPath) as! TableCollectionCell
        // The below code is "unecessary"
        tCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
        return tCell
    }
}



// MARK: - Explore Extension for UITableViewCell --> TableCollectionCell
extension Explore: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return self.articles.count
        } else if collectionView.tag == 1 {
            return self.promotedPosts.count
        } else if collectionView.tag == 2 {
            return self.randomUsers.count
        } else {
            return self.geocodeUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 0 {
            let fCell = collectionView.dequeueReusableCell(withReuseIdentifier: "featuredCell", for: indexPath) as! FeaturedCell
            
            // Configure background color
            fCell.storyCover.backgroundColor = UIColor.randomColor()
            
            // (1) Set publisher's name
            fCell.publisherName.text = self.publisherNames[indexPath.item]
            
            // (2) Set cover photo
            if let urlToImage = self.articles[indexPath.item].value(forKey: "urlToImage") as? String {
                // MARK: - SDWebImage
                fCell.storyCover.sd_setImage(with: URL(string: urlToImage)!)
            }
            
            // (3) Set title
            if let title = self.articles[indexPath.item].value(forKey: "title") as? String {
                fCell.storyTitle.text = title
            }
            
            // MARK: - RPHelpers
            fCell.storyCover.roundAllCorners(sender: fCell.storyCover)
            fCell.storyTitle.layer.applyShadow(layer: fCell.storyTitle.layer)
            fCell.publisherName.layer.applyShadow(layer: fCell.publisherName.layer)
            
            return fCell

        } else if collectionView.tag == 1 {
            let pCell = collectionView.dequeueReusableCell(withReuseIdentifier: "promotedCell", for: indexPath) as! PromotedCell
            
            // (1) Set user's name
            if let user = self.promotedPosts[indexPath.item].value(forKey: "byUser") as? PFUser {
                pCell.rpUsername.text = (user.value(forKey: "username") as! String)
            }

            
            // (4) Set mediaPreview or textPreview
            pCell.textPreview.isHidden = true
            pCell.mediaPreview.isHidden = true
            
            // Promoted Posts
            if self.promotedPosts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                pCell.textPreview.text = "\(self.promotedPosts[indexPath.row].value(forKey: "textPost") as! String)"
                pCell.textPreview.isHidden = false
            } else if self.promotedPosts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                pCell.mediaPreview.image = UIImage(named: "CSpacePost")
                pCell.mediaPreview.isHidden = false
            } else {
                if let photo = self.promotedPosts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                    // MARK: - SDWebImage
                    pCell.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
                } else if let video = self.promotedPosts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                    // MARK: - AVPlayer
                    let player = AVPlayer(url: URL(string: video.url!)!)
                    let playerLayer = AVPlayerLayer(player: player)
                    playerLayer.frame = pCell.mediaPreview.bounds
                    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    pCell.mediaPreview.contentMode = .scaleAspectFit
                    pCell.mediaPreview.layer.addSublayer(playerLayer)
                    player.isMuted = true
                    player.play()
                }
                pCell.mediaPreview.isHidden = false
            }

            // MARK: - RPExtensions
            pCell.textPreview.makeCircular(forView: pCell.textPreview, borderWidth: 0, borderColor: UIColor.clear)
            pCell.mediaPreview.makeCircular(forView: pCell.mediaPreview, borderWidth: 0, borderColor: UIColor.clear)
            
            return pCell
            
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
            // PROMOTED
            
            // Append object
            storyObjects.append(self.promotedPosts[indexPath.item])
            
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
