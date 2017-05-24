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
import Reactions
import SDWebImage
import VIMVideoPlayer

// Array to hold storyObjects
var storyObjects = [PFObject]()

class Stories: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate {
    
    // Array to hold stories
    var stories = [PFObject]()
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    
    // ScrollSets for database <contentType>
    let scrollSets = ["tp", "ph", "pp", "sp"]
    
    // MARK: - VIMVideoPlayer
    var vimVideoPlayerView: VIMVideoPlayerView?
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - Reactions; Initialize (1) ReactionButton, (2) ReactionSelector, (3) Reactions
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let reactionSelector = ReactionSelector()
    let reactions = [Reaction(id: "More", title: "More", color: .lightGray, icon: UIImage(named: "MoreBlack")!),
                     Reaction(id: "Like", title: "Like", color: .lightGray, icon: UIImage(named: "Like")!),
                     Reaction(id: "Comment", title: "Comment", color: .lightGray, icon: UIImage(named: "Comment")!),
                     Reaction(id: "Share", title: "Share", color: .lightGray, icon: UIImage(named: "Share")!)]
    
    @IBOutlet weak var collectionView: UICollectionView!

    // FUNCTION - Fetch user's stories...
    func fetchStories() {
        // Fetch stories
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: storyObjects.last!.value(forKey: "byUser") as! PFUser)
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.order(byDescending: "createdAt")
//        newsfeeds.limit = 500
        newsfeeds.limit = 30
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.stories.removeAll(keepingCapacity: false)
                // Reverse chronology
                for object in objects! {
//                    .reversed() {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
//                        self.stories.append(object)
                    }
                    self.stories.append(object)
                }

                
                // Reload data in main thread
                DispatchQueue.main.async(execute: {
                    // Configure view
                    self.configureView()
                    // Reload data
                    self.collectionView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    // FUNCTION - Configure view
    func configureView() {
        // MARK: - SegmentedProgressBar
        self.spb = SegmentedProgressBar(numberOfSegments: self.stories.count, duration: 10)
        self.spb.frame = CGRect(x: 8, y: 4, width: self.view.frame.width - 16, height: 3)
        self.spb.topColor = UIColor.white
        self.spb.layer.applyShadow(layer: self.spb.layer)
        self.spb.padding = 2
        self.spb.delegate = self
        self.view.addSubview(self.spb)
        self.spb.startAnimation()
        
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
        view.addSubview(reactButton)
        view.bringSubview(toFront: reactButton)
    }
    
    
    // FUNCTION - More option for post
    func showOption(sender: Any) {
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: nil)
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
        
        // (1) Show Views for post
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            
        })
    
        // (2) Delete Post
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // TODO
        })
        
        // (3) Edit Post
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // TODO
        })
        
        
        dialogController.show(in: self)
    }
    
    // FUNCTION - Like Post
    func like(sender: Any) {
        
    }
    
    
    // FUNCTION - Reload UICollectionView at specific indexPaths
    func reloadTrios(atIndex: Int) {
         self.collectionView.reloadItems(at: [IndexPath(item: atIndex, section: 0)])
        if atIndex != 0 && atIndex != self.stories.count && self.stories[atIndex].value(forKey: "videoAsset") != nil {
            self.collectionView.reloadItems(at: [IndexPath(item: atIndex - 1, section: 0)])
            self.collectionView.reloadItems(at: [IndexPath(item: atIndex + 1, section: 0)])
        }
    }
    
    
    // MARK: - SegmentedProgressBar Delegate Methods
    func segmentedProgressBarChangedIndex(index: Int) {
        self.collectionView!.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: true)
        self.reloadTrios(atIndex: index)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Reactions Delegate Method
    func reactionFeedbackDidChanged(_ feedback: ReactionFeedback?) {
        if feedback == nil || feedback == .tapToSelectAReaction {
            self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
            switch reactionSelector.selectedReaction!.id {
                case "More":
                    // MORE
                    self.showOption(sender: self)
                case "Like":
                    // LIKE
                    self.like(sender: self)
                case "Comment":
                    // COMMENT
                    reactionObject.append(self.stories[self.currentIndex!])
                    let reactionsVC = self.storyboard?.instantiateViewController(withIdentifier: "reactionsVC") as! Reactions
                    self.navigationController?.pushViewController(reactionsVC, animated: true)
                case "Share":
                    // SHARE
                    shareWithObject.append(self.stories[self.currentIndex!])
                    let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                    self.navigationController?.pushViewController(shareWithVC, animated: true)
            default:
                break;
            }
        } else {
            // RESET
            self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "ReactMore", title: "", color: .lightGray, icon: UIImage(named: "ReactMore")!)
        }
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPExtensions
        self.view.straightenCorners(sender: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch Stories
        fetchStories()
        
        // MARK: - VIMVideoPlayerView
        vimVideoPlayerView = VIMVideoPlayerView()
        
        // MARK: - AnimatedCollectionViewLayout
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
        self.collectionView?.register(UINib(nibName: "VideoCell", bundle: nil), forCellWithReuseIdentifier: "VideoCell")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // MARK: - VIMVideoPlayerView; de-allocate AVPlayer's currentItem
        self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
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

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // TEXT POST, PHOTO, PROFILE PHOTO, SPACE POST
        if self.scrollSets.contains(self.stories[indexPath.item].value(forKey: "contentType") as! String) {
            let scrollCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "StoryScrollCell", for: indexPath) as! StoryScrollCell
            
            // Set PFObject
            scrollCell.postObject = self.stories[indexPath.item]
            // Set parent UIViewController
            scrollCell.delegate = self
            // Set UITableView Data Source and Delegates
            scrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            return scrollCell
        }
        
        if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
        // MOMENT VIDEO
            
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            
            // Add and play || pause video when visible
            if self.currentIndex == indexPath.item {
                // Set PFObject, parent UIViewController, update UI, and play video
                mvCell.postObject = self.stories[indexPath.item]
                mvCell.delegate = self
                mvCell.updateView(withObject: self.stories[indexPath.item], videoPlayer: self.vimVideoPlayerView)
                self.vimVideoPlayerView?.player.play()
            }
            
//            else {
//                // Pass new AVPlayerItem
//                if let videoFile = self.stories[self.currentIndex!].value(forKey: "videoAsset") as? PFFile {
//                    let playerItem = AVPlayerItem(url: URL(string: videoFile.url!)!)
//                    self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: playerItem)
//                }
//                self.vimVideoPlayerView?.player.pause()
//            }
            
            return mvCell
        }
        
        if self.stories[indexPath.item].value(forKey: "contentType") as! String == "vi" && self.stories[indexPath.item].value(forKey: "videoAsset") != nil {
        // VIDEO
            let videoCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            // Add and play || pause video when visible
            if self.currentIndex == indexPath.item {
                // Set PFObject, parent UIViewController, update UI, and play video
                videoCell.postObject = self.stories[indexPath.item]
                videoCell.delegate = self
                videoCell.updateView(withObject: self.stories[indexPath.item], videoPlayer: self.vimVideoPlayerView)
                self.vimVideoPlayerView?.player.play()
            }
            
//            else {
//                // Pass new AVPlayerItem
//                if let videoFile = self.stories[self.currentIndex!].value(forKey: "videoAsset") as? PFFile {
//                    let playerItem = AVPlayerItem(url: URL(string: videoFile.url!)!)
//                    self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: playerItem)
//                }
//                self.vimVideoPlayerView?.player.isPlaying = false
//                self.vimVideoPlayerView?.player.pause()
//            }
            
            return videoCell
        }
        
        
        if self.stories[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.stories[indexPath.item].value(forKey: "photoAsset") != nil {
        // MOMENT PHOTO
            
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            mpCell.postObject = self.stories[indexPath.item]                // Set PFObject
            mpCell.delegate = self                                          // Set parent UIViewController
            mpCell.updateView(withObject: self.stories[indexPath.item])     // Update UI
            return mpCell
        }
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
        return cell
    }
    
    
    // MARK: - UIScrollView Delegate Methods
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.lastOffSet = scrollView.contentOffset
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        // Get visible indexPath
        var visibleRect = CGRect()
        visibleRect.origin = self.collectionView!.contentOffset
        visibleRect.size = self.collectionView!.bounds.size
        let visiblePoint = CGPoint(x: CGFloat(visibleRect.midX), y: CGFloat(visibleRect.midY))
        let indexPath: IndexPath = self.collectionView!.indexPathForItem(at: visiblePoint)!
        
        let views = PFObject(className: "Views")
        views["byUser"] = PFUser.current()!
        views["byUsername"] = PFUser.current()!.username!
        views["forObject"] = self.stories[indexPath.item]
        views["screenshotted"] = false
//        views.saveInBackground()
//        views.saveInBackground { (success: Bool, error: Error?) in
//            if success {
//                print("Successfully saved...")
//            } else {
//                print(error?.localizedDescription as Any)
//            }
//        }
        
        // Set currentIndex
        self.currentIndex = indexPath.item
        // Reload data to prevent previous or next video player from playing
        self.reloadTrios(atIndex: indexPath.item)
        
        // Manipulate SegmentedProgressBar
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb.skip()
        } else if self.lastOffSet!.x > scrollView.contentOffset.x {
            self.spb.rewind()
        }
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
            phCell.updateView(withObject: self.stories[tableView.tag])      // Update UI
            return phCell
            
        } else if self.stories[tableView.tag].value(forKey: "contentType") as! String == "pp" {
        // PROFILE PHOTO
            
            let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell
            ppCell.postObject = self.stories[tableView.tag]                 // Set PFObject
            ppCell.superDelegate = self                                     // Set parent UIViewController
            ppCell.updateView(withObject: self.stories[tableView.tag])      // Update UI
            return ppCell
            
        } else {
        // SPACE POST
            let spCell = Bundle.main.loadNibNamed("SpacePostCell", owner: self, options: nil)?.first as! SpacePostCell
            spCell.postObject = self.stories[tableView.tag]                 // Set PFObject
            spCell.superDelegate = self                                     // Set parent UIViewController
            spCell.updateView(withObject: self.stories[tableView.tag])      // Update UI
            return spCell
        }
    
    }
    
    // MARK: - UIScrollView Delegate Method
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= 0 && scrollView.contentOffset.x == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
