//
//  Stories.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/28/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVFoundation
import AVKit
import Parse
import ParseUI
import Bolts

import AnimatedCollectionViewLayout
import SwipeNavigationController

// Array to hold storyObjects
var storyObjects = [PFObject]()

class Stories: UICollectionViewController, UINavigationControllerDelegate, SegmentedProgressBarDelegate {
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!
    
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    
    // Array to hold storyPosts/likes
    var storyPosts = [PFObject]()
    var likes = [PFObject]()
    
    func fetchStories() {
        
//        let keys = ["DLnG0kTEdF", "hBK4V32cHA", "tFPeSVIQF1", "1I0ps1kceb", "Hema8xEngE"]
        
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: storyObjects.last!.value(forKey: "byUser") as! PFUser)
        
//        newsfeeds.whereKey("objectId", notEqualTo: "hBK4V32cHA")
//        newsfeeds.whereKey("objectId", containedIn: keys)
        
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.storyPosts.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.storyPosts.append(object)
                    }
//                    self.storyPosts.append(object)
                }
                
                // MARK: - SegmentedProgressBar
                if self.storyPosts.count == 0 {
                    self.spb = SegmentedProgressBar(numberOfSegments: 1, duration: 10)
                } else {
                    self.spb = SegmentedProgressBar(numberOfSegments: self.storyPosts.count, duration: 10)
                }
                self.spb.frame = CGRect(x: 8, y: 8, width: self.view.frame.width - 16, height: 4)
                self.spb.topColor = UIColor.white
                self.spb.layer.applyShadow(layer: self.spb.layer)
                self.spb.padding = 2
                self.spb.delegate = self
                self.view.addSubview(self.spb)
                self.spb.startAnimation()
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    // MARK: - SegmentedProgressBar Delegate Methods
    func segmentedProgressBarChangedIndex(index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        self.collectionView!.scrollToItem(at: indexPath, at: .right, animated: true)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPButton
        rpButton.isHidden = true
        
        // Hide UITabBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = PageAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.estimatedItemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.frame = self.view.bounds
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.backgroundColor = UIColor.black
        
        // Fetch Stories
        fetchStories()
        
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "TextPostCell", bundle: nil), forCellWithReuseIdentifier: "TextPostCell")
        self.collectionView?.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        // Show rpButton
        rpButton.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.storyPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 375, height: 800)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Configure initial setup for time
        let from = self.storyPosts[indexPath.item].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // TEXT POST
        if self.storyPosts[indexPath.item].value(forKey: "contentType") as! String == "tp" {
            let tpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "TextPostCell", for: indexPath) as! TextPostCell
            
            // Set delegate
            tpCell.delegate = self
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.storyPosts[indexPath.item].value(forKey: "byUser") as? PFUser {
                tpCell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                
                // (2) Set user's profile photo
                if let proPic = user["userProfilePicture"] as? PFFile {
                    // MARK: - SDWebImage
                    tpCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPHelpers
                    tpCell.rpUserProPic.makeCircular(imageView: tpCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (3) MARK: - RPHelpers; Set time
            tpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (4) Set Text Post
            tpCell.textPost.text = (self.storyPosts[indexPath.item].value(forKey: "textPost") as! String)
            
            return tpCell
            
        } else if self.storyPosts[indexPath.row].value(forKey: "contentType") as! String == "ph" {
            let pCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
            
            // (1) Get user's object
            if let user = self.storyPosts[indexPath.item].value(forKey: "byUser") as? PFUser {
                // Set user's fullName; "realNameOfUser"
                pCell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // Set user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    pCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPHelpers
                    pCell.rpUserProPic.makeCircular(imageView: pCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (2) MARK: - RPHelpers; Set time
            pCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let photo = self.storyPosts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                pCell.photo.sd_showActivityIndicatorView()
                pCell.photo.sd_setIndicatorStyle(.gray)
                pCell.photo.sd_setImage(with: URL(string: photo.url!)!)
            }
            
            // (4) Set caption
            if let textPost = self.storyPosts[indexPath.item].value(forKey: "textPost") as? String {
                pCell.caption.text = textPost
            }
            
            return pCell
            
        } else if self.storyPosts[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.storyPosts[indexPath.item].value(forKey: "photoAsset") != nil {
            // MOMENT PHOTO
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.storyPosts[indexPath.item].value(forKey: "byUser") as? PFUser {
                mpCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let photo = self.storyPosts[indexPath.item].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mpCell.photoMoment.sd_showActivityIndicatorView()
                mpCell.photoMoment.sd_setIndicatorStyle(.gray)
                mpCell.photoMoment.sd_setImage(with: URL(string: photo.url!)!)
            }
            
            return mpCell
            
        } else {
            
            //            if self.storyPosts[indexPath.row].value(forKey: "contentType") as! String == "itm" && self.storyPosts[indexPath.row].value(forKey: "videoAsset") != nil
            
            // MOMENT VIDEO CELL
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.storyPosts[indexPath.row].value(forKey: "byUser") as? PFUser {
                mvCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mvCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set video
            if let video = self.storyPosts[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // Add Video
                mvCell.addVideo(videoURL: URL(string: video.url!)!)
            }
            
            return mvCell
        }
    }
    
    
    // MARK: - UIScrollView Delegate Method
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastOffSet = scrollView.contentOffset
    }
    
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
//        for cell:  UICollectionViewCell in self.collectionView!.visibleCells {
//            let indexPath: IndexPath? = self.collectionView?.indexPath(for: cell)
//            print("IndexPath: \n\(indexPath!.item)\n")
//        }
        
        // Scrolled to the right; skip
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb.skip()
        } else {
            // Scrolled to the left; rewind
            self.spb.rewind()
        }
    }
    
    
    
}
