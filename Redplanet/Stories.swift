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

// Array to hold storyObjects
var storyObjects = [PFObject]()

class Stories: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate {
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - Reactions; Initialize (1) ReactionButton, (2) ReactionSelector, (3) Reactions
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let reactionSelector = ReactionSelector()
    let reactions = [Reaction(id: "ReactMore", title: "More", color: .lightGray, icon: UIImage(named: "ReactMore")!),
                     Reaction(id: "Like", title: "Like", color: .lightGray, icon: UIImage(named: "Like")!),
                     Reaction(id: "Comment", title: "Comment", color: .lightGray, icon: UIImage(named: "Comment")!),
                     Reaction(id: "Share", title: "Share", color: .lightGray, icon: UIImage(named: "Share")!)]
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Array to hold stories/likes
    var stories = [PFObject]()
    var likes = [PFObject]()
    
    let scrollSets = ["tp", "pp", "vi", "sp"]
    
    @IBOutlet weak var collectionView: UICollectionView!

    func fetchStories() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: storyObjects.last!.value(forKey: "byUser") as! PFUser)
//        let keys = ["DLnG0kTEdF", "hBK4V32cHA", "tFPeSVIQF1", "1I0ps1kceb", "Hema8xEngE", "qvz1ATrnSO"]        
//        newsfeeds.whereKey("objectId", containedIn: keys)
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
                
                // MARK: - SegmentedProgressBar
                if self.stories.count == 0 {
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
    
    // MARK: - Reactions
    func reactionFeedbackDidChanged(_ feedback: ReactionFeedback?) {
        if feedback == nil || feedback == .tapToSelectAReaction {
            // More
            if reactionSelector.selectedReaction?.id == "ReactMore" {
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
                shareWithVC.createdPost = false
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
        reactButton.frame.origin.y = self.view.bounds.height - 75
        reactButton.frame.origin.x = self.view.bounds.width/2 - reactButton.frame.size.width/2
        self.view.addSubview(reactButton)
        self.view.bringSubview(toFront: reactButton)
        
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if cell == self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo {
            self.rpVideoPlayer?.pause()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        print("CELL: \(cell)\n")
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
            scrollCell.parentDelegate = self
            
            return scrollCell
            
        } else if self.stories[indexPath.row].value(forKey: "contentType") as! String == "ph" {
            
            let pCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
            
            // (1) Get user's object
            if let user = self.stories[indexPath.item].value(forKey: "byUser") as? PFUser {
                // Set user's fullName; "realNameOfUser"
                pCell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                // Set user's profile photo
                if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    pCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPHelpers
                    pCell.rpUserProPic.makeCircular(forView: pCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (2) MARK: - RPHelpers; Set time
            pCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let photo = self.stories[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                pCell.photo.sd_showActivityIndicatorView()
                pCell.photo.sd_setIndicatorStyle(.gray)
                pCell.photo.sd_setImage(with: URL(string: photo.url!)!)
            }
            
            // (4) Set caption
            if let textPost = self.stories[indexPath.item].value(forKey: "textPost") as? String {
                pCell.caption.text = textPost
            }
            
            return pCell
            
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
