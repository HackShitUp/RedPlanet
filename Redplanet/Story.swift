//
//  Story.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/12/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import AnimatedCollectionViewLayout
import SDWebImage

class Story: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, SegmentedProgressBarDelegate {
    
    // MARK: - Class Variable; Used to get object
    open var singleStory: PFObject?
    
    // Used to determine whether to fetch CHAT MOMENT or SINGLE STORY INCLUDING
    open var chatOrStory: String?

    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Array to hold stories/likes
    var stories = [PFObject]()
    var likes = [PFObject]()
    
    // ScrollSets
    let scrollSets = ["tp", "pp", "ph", "vi", "sp"]
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    func fetchChat() {
        let chats = PFQuery(className: "Chats")
        chats.whereKey("contentType", equalTo: "itm")
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.stories.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 || (difference.hour! < 24 && object.value(forKey: "saved") as! Bool == true) {
                        self.stories.append(object)
                    }
                }
                
                // Configure SegmentedProgressBar
                self.configureSPB(posts: self.stories)
                
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        }
    }
    
    // Function to fetch 1 story...
    func fetchSingle() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: self.singleStory!.objectId!)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.limit = 10
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.stories.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
//                        self.stories.append(object)
                    }
                    self.stories.append(object)
                }
                
                // Configure SPB
                self.configureSPB(posts: self.stories)
            } else {
                print(error?.localizedDescription as Any)
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    
    // Function to configure SegmentedProgressBar (MARK: - SegmentedProgressBar)
    func configureSPB(posts: [PFObject]) {
        // MARK: - SegmentedProgressBar
        if posts.count == 1 {
            self.spb = SegmentedProgressBar(numberOfSegments: 1, duration: 10)
        } else {
            self.spb = SegmentedProgressBar(numberOfSegments: self.stories.count, duration: 10)
        }
        self.spb.frame = CGRect(x: 8, y: 8, width: self.view.frame.width - 16, height: 3)
        self.spb.topColor = UIColor.white
        self.spb.layer.applyShadow(layer: self.spb.layer)
        self.spb.padding = 2
        self.spb.delegate = self
        self.view.addSubview(self.spb)
        self.spb.startAnimation()
    }
    
    
    // MARK: - SegmentedProgressBar Delegate Methods
    func segmentedProgressBarChangedIndex(index: Int) {
//        let indexPath = IndexPath(item: index, section: 0)
//        self.collectionView!.scrollToItem(at: indexPath, at: .right, animated: true)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        // Hide UINavigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Straighten UIView
        self.navigationController?.view.straightenCorners(sender: self.navigationController?.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - AnimatedCollectionViewLayout; configure UICollectionView
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = ParallaxAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.estimatedItemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        // Configure UICollectionView
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.isPagingEnabled = true
        collectionView!.collectionViewLayout = layout
        collectionView!.frame = self.view.bounds
        collectionView!.backgroundColor = UIColor.black
        collectionView!.showsHorizontalScrollIndicator = false
        
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch Chat
        if self.chatOrStory == "Chat" {
            fetchChat()
        } else {
        // Fetch Single Story
            fetchSingle()
        }
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
        return self.stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Configure initial setup for time
        let from = self.stories[indexPath.item].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // Text Posts, Profile Photo
        if self.scrollSets.contains(self.stories[indexPath.item].value(forKey: "contentType") as! String) {
            let scrollCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "StoryScrollCell", for: indexPath) as! StoryScrollCell
            
            // Set PFObject
            scrollCell.postObject = self.stories[indexPath.item]
            // Set parentDelegate
            scrollCell.delegate = self
            
            return scrollCell
            
        } else if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "photoAsset") != nil {
        // MOMENT PHOTO
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.stories[indexPath.item].value(forKey: "byUser") as? PFUser {
                mpCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let photo = self.stories[indexPath.item].value(forKey: "photoAsset") as? PFFile {
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
            if let user = self.stories[indexPath.row].value(forKey: "byUser") as? PFUser {
                mvCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) MARK: - RPHelpers; Set time
            mvCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set video
            if let video = self.stories[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // MARK: - RPVideoPlayerView
                self.rpVideoPlayer = RPVideoPlayerView(frame: mvCell.contentView.bounds)
                self.rpVideoPlayer.setupVideo(videoURL: URL(string: video.url!)!)
                mvCell.contentView.addSubview(rpVideoPlayer)
                self.rpVideoPlayer.autoplays = false
                self.rpVideoPlayer.playbackLoops = false
                self.rpVideoPlayer?.pause()
                // Update view???
                mvCell.updateView()
            }
            
            
            return mvCell
        }
    }
    
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.lastOffSet = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = self.collectionView!.contentOffset
        visibleRect.size = self.collectionView!.bounds.size
        let visiblePoint = CGPoint(x: CGFloat(visibleRect.midX), y: CGFloat(visibleRect.midY))
        let indexPath: IndexPath? = self.collectionView?.indexPathForItem(at: visiblePoint)
        
        // Scrolled to the right; skip
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            // TODO:: End if last indexPath
            self.spb.skip()
        } else {
            // Scrolled to the left; rewind
            self.spb.rewind()
        }
        
        if self.stories[indexPath!.item].value(forKey: "videoAsset") != nil {
            print("Video: \(indexPath![1])")
            print("OBJECTID: \(self.stories[indexPath!.item].objectId!)\n")
        } else {
            print("Not a video: \(indexPath![1])")
        }
    }

}
