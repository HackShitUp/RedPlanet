//
//  Hashtags.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import Parse
import ParseUI
import Bolts

import AnimatedCollectionViewLayout
import SDWebImage


class Hashtags: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate {
    
    // MARK: - Class Variable
    var hashtagString = String()
    
    // Array to hold # PFObject ids...
    var hashtagIds = [String]()
    // Public users
    var publicUsers = [PFObject]()
    // Posts/Skipped
    var posts = [PFObject]()
    var skipped = [PFObject]()
    
    let scrollSets = ["tp", "ph", "pp", "vi", "sp"]
    
    // AppDelegate
    let appDelegate = AppDelegate()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Function to fetch hashtags
    func fetchHastags() {
        let hashtags = PFQuery(className: "Hashtags")
        hashtags.whereKey("hashtag", equalTo: hashtagString)
        hashtags.order(byDescending: "createdAt")
        hashtags.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.hashtagIds.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.hashtagIds.append(object.value(forKey: "forObjectId") as! String)
                }
                
                // Fetch posts
                self.fetchPosts()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }

    }
    
    // Function to fetch hashtag posts
    func fetchPosts() {
        // Get blocked users
        _ = appDelegate.queryRelationships()
        // Check for public users
        let user = PFUser.query()!
        user.whereKey("private", equalTo: false)
        user.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.publicUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId!}) {
                        self.publicUsers.append(object)
                    }
                }
                
                // Get posts
                let newsfeeds = PFQuery(className: "Newsfeeds")
                newsfeeds.includeKey("byUser")
                newsfeeds.whereKey("byUser", containedIn: self.publicUsers)
                newsfeeds.whereKey("objectId", containedIn: self.hashtagIds)
                newsfeeds.whereKey("contentType", containedIn: ["tp", "ph", "vi", "itm"])
                newsfeeds.order(byDescending: "createdAt")
                newsfeeds.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.posts.removeAll(keepingCapacity: false)
                        for object in objects! {
//                            // Ephemeral content
//                            let components : NSCalendar.Unit = .hour
//                            let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
//                            if difference.hour! < 24 {
//                                self.posts.append(object)
//                            } else {
//                                self.skipped.append(object)
//                            }
                            self.posts.append(object)
                        }
                        
                        // Reload data in main thread
                        if self.posts.count != 0 {
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        } else {
                            // MARK: - DZNEmptyDataSet
                            // TODO::
                        }
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
    }

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide UINavigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch hastags
        fetchHastags()
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.animator = LinearCardAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView!.collectionViewLayout = layout
        collectionView!.frame = self.view.bounds
        collectionView!.isPagingEnabled = true
        collectionView!.backgroundColor = UIColor.white
    
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Returning: \(self.posts.count) posts")
        return self.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let storyScrollCell = cell as? StoryScrollCell else { return }
        storyScrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Configure initial setup for time
        let from = self.posts[indexPath.item].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // Text Posts, Profile Photo
        if self.scrollSets.contains(self.posts[indexPath.item].value(forKey: "contentType") as! String) {
            let scrollCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "StoryScrollCell", for: indexPath) as! StoryScrollCell
            
            // Set PFObject
            scrollCell.postObject = self.posts[indexPath.item]
            // Set parentDelegate
            scrollCell.delegate = self
            scrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            
            return scrollCell
            
        } else if self.posts[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.posts[indexPath.item].value(forKey: "photoAsset") != nil {
            // MOMENT PHOTO
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.posts[indexPath.item].value(forKey: "byUser") as? PFUser {
                mpCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let photo = self.posts[indexPath.item].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mpCell.photoMoment.sd_showActivityIndicatorView()
                mpCell.photoMoment.sd_setIndicatorStyle(.gray)
                mpCell.photoMoment.sd_setImage(with: URL(string: photo.url!)!)
            }
            
            return mpCell
            
        } else {
            // MOMENT VIDEO CELL
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
                mvCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mvCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set video
            if let video = self.posts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
//                // MARK: - RPVideoPlayerView
//                self.rpVideoPlayer = RPVideoPlayerView(frame: mvCell.contentView.bounds)
//                self.rpVideoPlayer.setupVideo(videoURL: URL(string: video.url!)!)
//                mvCell.contentView.addSubview(rpVideoPlayer)
//                self.rpVideoPlayer.autoplays = false
//                self.rpVideoPlayer.playbackLoops = false
//                self.rpVideoPlayer?.pause()
//                // Update view???
//                mvCell.updateView()
            }
            
            
            return mvCell
        }
    }



}



// MARK: - Hashtags Extension
extension Hashtags: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableViewData Source Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.posts[tableView.tag].value(forKey: "contentType") as! String == "tp" {
            // TEXT POST
            let tpCell = Bundle.main.loadNibNamed("TextPostCell", owner: self, options: nil)?.first as! TextPostCell
            
            // Set PFObject
            tpCell.postObject = self.posts[tableView.tag]
            tpCell.superDelegate = self
            tpCell.updateView(withObject: self.posts[tableView.tag])
            
            return tpCell
            
        } else if self.posts[tableView.tag].value(forKey: "contentType") as! String == "ph" {
            // PHOTO
            let phCell = Bundle.main.loadNibNamed("PhotoCell", owner: self, options: nil)?.first as! PhotoCell
            
            phCell.postObject = self.posts[tableView.tag]
            phCell.superDelegate = self
            phCell.updateView(postObject: self.posts[tableView.tag])
            
            return phCell
            
        } else {
            // if self.stories[indexPath.row].value(forKey: "contentType") as! String == "pp" {
            // PROFILE PHOTO
            let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell
            
            ppCell.postObject = self.posts[tableView.tag]
            ppCell.superDelegate = self
            ppCell.updateView(postObject: self.posts[tableView.tag])
            
            return ppCell
        }
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= 0 && scrollView.contentOffset.x == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
