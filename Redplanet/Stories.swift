//
//  Stories.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/4/17.
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
import Reactions
import SDWebImage
import VIMVideoPlayer

// Array to hold storyObjects
var storyObjects = [PFObject]()


class UserStories {
    var userObject = PFObject()
    var postObjects = [PFObject]()
    
    init(userObject: PFObject, posts: [PFObject]) {
        self.userObject = userObject
        self.postObjects = posts
    }
}

class Stories: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate {
    
    
    // MARK: - VIMVideoPlayer
    var vimPlayerView: VIMVideoPlayerView!
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - Reactions; Initialize (1) ReactionButton, (2) ReactionSelector, (3) Reactions
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let reactionSelector = ReactionSelector()
    let reactions = [Reaction(id: "More", title: "More", color: .lightGray, icon: UIImage(named: "MoreBlack")!),
                     Reaction(id: "Like", title: "Like", color: .lightGray, icon: UIImage(named: "Like")!),
                     Reaction(id: "Comment", title: "Comment", color: .lightGray, icon: UIImage(named: "Comment")!),
                     Reaction(id: "Share", title: "Share", color: .lightGray, icon: UIImage(named: "Share")!)]
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    // Array to hold stories/likes
    var stories = [PFObject]()
    var likes = [PFObject]()
    
    // ScrollSets
    let scrollSets = ["tp", "ph", "pp", "vi", "sp"]
    
    @IBOutlet weak var collectionView: UICollectionView!

    func fetchStories() {
        // Fetch stories
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: storyObjects.last!.value(forKey: "byUser") as! PFUser)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.limit = 50
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.stories.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
//                    let components: NSCalendar.Unit = .hour
//                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
//                    if difference.hour! < 24 {
//                        self.stories.append(object)
//                    }
                    self.stories.append(object)
                }
                
                // MARK: - SegmentedProgressBar
                if self.stories.count == 1 {
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
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                
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
    
    // MARK: - Reactions
    func reactionFeedbackDidChanged(_ feedback: ReactionFeedback?) {
        if feedback == nil || feedback == .tapToSelectAReaction {
            // More
            if reactionSelector.selectedReaction?.id == "More" {
                self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
                
            } else if reactionSelector.selectedReaction?.id == "Like" {
                // Like
                self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "LikeFilled", title: "", color: .lightGray, icon: UIImage(named: "LikeFilled")!)
                
            } else if reactionSelector.selectedReaction?.id == "Comment" {
                // Comment
                self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
                
                reactionObject.append(self.stories.last!)
                let reactionsVC = self.storyboard?.instantiateViewController(withIdentifier: "reactionsVC") as! Reactions
                self.navigationController?.pushViewController(reactionsVC, animated: true)
                
            } else if reactionSelector.selectedReaction?.id == "Share" {
                // Share
                self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
                
                shareWithObject.append(self.stories.last!)
                let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                self.navigationController?.pushViewController(shareWithVC, animated: true)
            }
        } else {
            // Share
            self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
        }
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPButton
        rpButton.isHidden = true
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        // MARK: - RPExtensions
        self.navigationController?.view.straightenCorners(sender: self.navigationController?.view)
        // Hide UITabBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch Stories
        fetchStories()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
        
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

        // MARK: - Reactions
        // (2) Create ReactionSelector and add Reactions from <1>
        reactionSelector.feedbackDelegate = self
        reactionSelector.setReactions(reactions, sizeToFit: true)
        // (3) Configure ReactionSelector
        reactionSelector.config = ReactionSelectorConfig {
            $0.spacing = 12
            $0.iconSize = 35
            $0.stickyReaction = true
        }
        // (4) Set ReactionSelector
        reactButton.reactionSelector = reactionSelector
        // (5) Configure reactButton
        reactButton.config = ReactionButtonConfig() {
            $0.iconMarging = 8
            $0.spacing = 8
            $0.alignment = .centerLeft
            $0.font = UIFont(name: "AvenirNext-Medium", size: 15)
            $0.neutralTintColor = UIColor.black
        }
        reactButton.reaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
        reactButton.frame.origin.y = self.view.bounds.height - reactButton.frame.size.height
        reactButton.frame.origin.x = self.view.bounds.width/2 - reactButton.frame.size.width/2
        reactButton.layer.applyShadow(layer: reactButton.layer)
        self.view.addSubview(reactButton)
        self.view.bringSubview(toFront: reactButton)
        
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
    
        
        
        
        let forwardTap = UITapGestureRecognizer(target: self, action: #selector(forward))
        forwardTap.numberOfTapsRequired = 1
        
        
    
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        // MARK: - RPExtensions; rpButton
        rpButton.isHidden = false
        
        // De-allocate rpVideoPlayer
        self.rpVideoPlayer?.pause()
        self.rpVideoPlayer?.player?.replaceCurrentItem(with: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    func forward() {
        print("Forwarded")
    }
    
    
    func rewind() {
        print("Rewinded")
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
//        if collectionView.cellForItem(at: indexPath) == collectionView.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo {
//            self.vimPlayerView.player.pause()
//        } else if collectionView.cellForItem(at: indexPath) == Bundle.main.loadNibNamed("StoryScrollCell", owner: self, options: nil)?.first as! StoryScrollCell && self.stories[indexPath.item].value(forKey: "contentType") as! String == "vi" {
//            self.vimPlayerView.player.pause()
//        }
        if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
            guard let mvCell = cell as? MomentVideo else  { return }
            mvCell.vimPlayerView.player.pause()
        } else if self.stories[indexPath.item].value(forKey: "contentType") as! String == "vi" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
            //            guard let vCell = cell as? MomentVideo else  { return }
            //            mvCell.vimPlayerView.player.play()
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.scrollSets.contains(self.stories[indexPath.item].value(forKey: "contentType") as! String) {
        // StoryScrollCell
            guard let storyScrollCell = cell as? StoryScrollCell else { return }
            storyScrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        }
//        } else if self.collectionView.cellForItem(at: indexPath) == self.collectionView.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo {
//            print("Should play because MomentVideo...")
//            self.vimPlayerView.player.play()
//        } else if self.collectionView.cellForItem(at: indexPath) == Bundle.main.loadNibNamed("StoryScrollCell", owner: self, options: nil)?.first as! StoryScrollCell && self.stories[indexPath.item].value(forKey: "contentType") as! String == "vi" {
//            print("Should play because Video...")
//            self.vimPlayerView.player.play()
//        }
        
//        if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
//            guard let mvCell = cell as? MomentVideo else  { return }
//            mvCell.vimPlayerView.player.play()
//        } else if self.stories[indexPath.item].value(forKey: "contentType") as! String == "vi" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
//            guard let vCell = cell as? MomentVideo else  { return }
//            mvCell.vimPlayerView.player.play()
//        }
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // TEXT POST, PHOTO, PROFILE PHOTO, VIDEO, SPACE POST
        if self.scrollSets.contains(self.stories[indexPath.item].value(forKey: "contentType") as! String) {
            let scrollCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "StoryScrollCell", for: indexPath) as! StoryScrollCell
            
            // Set PFObject
            scrollCell.postObject = self.stories[indexPath.item]
            // Set parentDelegate
            scrollCell.delegate = self
            scrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            
            return scrollCell
            
        } else if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "photoAsset") != nil {
        // MOMENT PHOTO
            
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            mpCell.postObject = self.stories[indexPath.item]
            mpCell.delegate = self
            mpCell.updateView(withObject: self.stories[indexPath.item])
            return mpCell
            
        } else {
        // MOMENT VIDEO CELL
            
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            mvCell.postObject = self.stories[indexPath.item]
            mvCell.delegate = self
            mvCell.updateView(withObject: self.stories[indexPath.item])
            mvCell.addVideo(withObject: self.stories[indexPath.item])
            
            return mvCell
        }
    }
    
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.lastOffSet = scrollView.contentOffset
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Manipulate SegmentedProgressBar
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb.skip()
        } else {
            self.spb.rewind()
        }
        
        // Get visible indexPath
        var visibleRect = CGRect()
        visibleRect.origin = self.collectionView!.contentOffset
        visibleRect.size = self.collectionView!.bounds.size
        let visiblePoint = CGPoint(x: CGFloat(visibleRect.midX), y: CGFloat(visibleRect.midY))
        let indexPath: IndexPath = self.collectionView!.indexPathForItem(at: visiblePoint)!
    }

}







// MARK: - Stories Extension used to configure StoryScrollCell.swift...
extension Stories: UITableViewDataSource, UITableViewDelegate {
    // MARK: - UITableViewData Source Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.stories[tableView.tag].value(forKey: "contentType") as! String == "tp" {
        // TEXT POST
            
            let tpCell = Bundle.main.loadNibNamed("TextPostCell", owner: self, options: nil)?.first as! TextPostCell
            tpCell.postObject = self.stories[tableView.tag]                 // Set PFObject
            tpCell.superDelegate = self                                     // Set parent UIViewController
            tpCell.updateView(withObject: self.stories[tableView.tag])      // Update UI
            return tpCell
            
        } else if self.stories[tableView.tag].value(forKey: "contentType") as! String == "ph" {
        // PHOTO
            
            let phCell = Bundle.main.loadNibNamed("PhotoCell", owner: self, options: nil)?.first as! PhotoCell
            phCell.postObject = self.stories[tableView.tag]                 // Set PFObject
            phCell.superDelegate = self                                     // Set parent UIViewController
            phCell.updateView(postObject: self.stories[tableView.tag])      // Update UI
            return phCell
            
        } else if self.stories[tableView.tag].value(forKey: "contentType") as! String == "pp" {
        // PROFILE PHOTO
            
            let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell
            ppCell.postObject = self.stories[tableView.tag]                 // Set PFObject
            ppCell.superDelegate = self                                     // Set parent UIViewController
            ppCell.updateView(postObject: self.stories[tableView.tag])      // Update UI
            return ppCell
            
        } else {
        // VIDEO
            
            let vCell = Bundle.main.loadNibNamed("VideoCell", owner: self, options: nil)?.first as! VideoCell
            return vCell
        }
    }
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= 0 && scrollView.contentOffset.x == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
