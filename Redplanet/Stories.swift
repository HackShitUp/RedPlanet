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
import DZNEmptyDataSet
import Reactions
import SDWebImage
import SVProgressHUD
import VIMVideoPlayer

// Array to hold storyObjects
var storyObjects = [PFObject]()


/*
 UIViewController class reinforcing UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, and UITableViewDelegate
 methods. This class presents all the stories for a given user by traversing the user's object in the last value of the above 
 array, "storyObjects" and presents them in a UICollectionView. The UICollectionView then manages the configurations for data-binding in
 its relative UICollectionViewCell.
 
 
 *** The follow illustrates the hierarchy of views, from left to right presenting the lowest to highest executable configurations in this class:
 
 UITableViewCell(?) --> UITableView(?) --> UICollectionViewCell --> UICollectionView (self)
 
 *** The (?) indicate that the UITableView and UITableViewCell may or MAY NOT exist depending on the type of content presented. The content types, followed by a Boolean value indicate whether the UICollectionViewCell will have a UITableView and UITableViewCell in it:
    (1) Text Post = True
    (2) Photo = True
    (3) Profile Photo = True
    (4) Space Post = True
    (5) Video = False
    (6) Moment (Photo) = False
    (6A) Moment (Video) = False
*/

class Stories: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate {
    
    // ScrollSets for database <contentType>
    let scrollSets = ["tp", "ph", "pp", "sp"]
    
    // Array to hold posts
    var posts = [PFObject]()
    // Array to hold viewed posts
    var viewedPosts = [String]()
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    // MARK: - VIMVideoPlayer
    var vimVideoPlayerView: VIMVideoPlayerView?
    // MARK: - Reactions; Initialize...
    // (1) ReactionButton
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    // (2) Reaction Selector
    let reactionSelector = ReactionSelector()
    // (3) Reactions
    let rpLike = Reaction(id: "rpLike", title: "Like", color: .lightGray, icon: UIImage(named: "Like")!)
    let rpComment = Reaction(id: "rpComment", title: "Comment", color: .lightGray, icon: UIImage(named: "Comment")!)
    let rpShare = Reaction(id: "rpShare", title: "Share", color: .lightGray, icon: UIImage(named: "Share")!)
    let rpViews = Reaction(id: "rpViews", title: "Views", color: .lightGray, icon: UIImage(named: "Views")!)
    let rpMore = Reaction(id: "rpSave", title: "More", color: .lightGray, icon: UIImage(named: "Bookmark")!)
    

    @IBOutlet weak var collectionView: UICollectionView!
    
    // FUNCTION - Fetch viewed posts
    func fetchViewed() {
        let views = PFQuery(className: "Views")
        views.limit = 2500
        views.whereKey("byUser", equalTo: PFUser.current()!)
        views.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.viewedPosts.removeAll(keepingCapacity: false)
                for object in objects! {
                    if let forObjectId = object.value(forKey: "forObjectId") as? String {
                        self.viewedPosts.append(forObjectId)
                    }
                }
                
                // Map posts' objectIds
                let postIds = self.posts.map {$0.objectId!}
                // Get viewed posts that are a subset of all current posts
                let notViewedPosts = Set(postIds).subtracting(self.viewedPosts)
                // Subtract all of current posts, and the subset, and scroll to index
                let difference = self.posts.count - notViewedPosts.count

                // Scroll to the index not yet viewed IF the post is not the current user's
                if difference != self.posts.count && (storyObjects.last!.object(forKey: "byUser") as! PFUser).objectId! != PFUser.current()!.objectId!  {
                    
                    // Set currentIndex
                    self.currentIndex! = difference
                    // Save currentIndex to "Views"
                    self.saveViews(withIndex: self.currentIndex!)
                    
                    DispatchQueue.main.async(execute: {
                        // Skip SegmentedProgressBar by number of collectionViews
                        for _ in 0..<self.currentIndex! {
                            self.spb.skip()
                        }
                        // Reload item
                        self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }

    // FUNCTION - Fetch user's stories...
    func fetchStories() {
        // Fetch stories
        let postsClass = PFQuery(className: "Posts")
        postsClass.whereKey("byUser", equalTo: storyObjects.last!.object(forKey: "byUser") as! PFUser)
        postsClass.includeKeys(["byUser", "toUser"])
        postsClass.order(byDescending: "createdAt")
        postsClass.limit = 1000
        postsClass.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                // Reverse chronology
                for object in objects!.reversed() {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.posts.append(object)
                    }
                }
                
                // Reload data in main thread and configureView
                DispatchQueue.main.async(execute: {
                    if self.posts.count != 0 {
                        // Configure View
                        self.configureView()
                        // Fetch views
                        self.fetchViewed()
                        // reload data
                        self.collectionView.reloadData()
                    } else {
                        // MARK: - DZNEmptyDataSet
                        self.collectionView.emptyDataSetSource = self
                        self.collectionView.emptyDataSetDelegate = self
                        self.collectionView.reloadEmptyDataSet()
                    }
                })

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    
    // MARK: - SegmentedProgressBar Delegate Methods
    func segmentedProgressBarChangedIndex(index: Int) {
        self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: false)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Reactions; Delegate Method
    func reactionFeedbackDidChanged(_ feedback: ReactionFeedback?) {
        if feedback == nil || feedback == .tapToSelectAReaction {
            switch reactionSelector.selectedReaction!.id {
                case "rpMore":
                // MORE
                    self.showOption(sender: self)
                case "rpLike":
                // LIKE
                    self.like(sender: self)
                case "rpComment":
                // COMMENT
                    reactionObject.append(self.posts[self.currentIndex!])
                    let reactionsVC = self.storyboard?.instantiateViewController(withIdentifier: "reactionsVC") as! Reactions
                    self.navigationController?.pushViewController(reactionsVC, animated: true)
                case "rpShare":
                // SHARE
                    let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                    shareWithVC.shareWithObject = self.posts[self.currentIndex!]
                    self.navigationController?.pushViewController(shareWithVC, animated: true)
                case "rpViews":
                // VIEWS
                    let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
                    viewsVC.fetchObject = self.posts[self.currentIndex!]
                    self.navigationController?.pushViewController(viewsVC, animated: true)
            default:
                break;
            }
        }
        // Reset ReactButton
        self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "rpReact", title: "", color: .lightGray, icon: UIImage(named: "ReactButton")!)
    }
    
    
    // MARK: - DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.posts.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let font = UIFont(name: "AvenirNext-Medium", size: 25)
        let attributeDictionary: [String: AnyObject]? = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font!]
        return NSAttributedString(string: "💩\nThe story doesn't exist...", attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let font = UIFont(name: "AvenirNext-Demibold", size: 17)
        let attributeDictionary: [String: AnyObject]? = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font!]
        return NSAttributedString(string: "OK", attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        // Dismiss
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPExtensions
        self.view.straightenCorners(sender: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SVProgressHUD
        SVProgressHUD.setBackgroundColor(UIColor.clear)
        SVProgressHUD.setForegroundColor(UIColor.groupTableViewBackground)
        SVProgressHUD.setFont(UIFont(name: "AvenirNext-Medium", size: 21))
        SVProgressHUD.show(withStatus: "\((storyObjects.last!.object(forKey: "byUser") as! PFUser).username!.lowercased())")
        
        // Fetch Stories
        fetchStories()

        // MARK: - VIMVideoPlayerView
        vimVideoPlayerView = VIMVideoPlayerView()
        
        // MARK: - SubtleVolume
        let subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 7)
        subtleVolume.animation = .slideDown
        subtleVolume.barTintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        subtleVolume.barBackgroundColor = UIColor.white
        self.view.addSubview(subtleVolume)
        subtleVolume.superview?.bringSubview(toFront: subtleVolume)
        
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
        
        // Add long press method in UICollectionView
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(showOption(sender:)))
        hold.minimumPressDuration = 0.40
        self.collectionView!.isUserInteractionEnabled = true
        self.collectionView!.addGestureRecognizer(hold)
        
        // MARK: - HEAP
        // Set App ID
        Heap.setAppId("3455525110");
        // Track Who Opens the App
        Heap.track("ViewedPost", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Add observer for screenshots
        NotificationCenter.default.addObserver(self, selector: #selector(sendScreenshot),
                                               name: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // MARK: - VIMVideoPlayerView; de-allocate AVPlayer's currentItem
        self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
        // MARK: - SVProgressHUD
        SVProgressHUD.dismiss()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    // MARK: UICollectionView DataSource Methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // TEXT POST, PHOTO, PROFILE PHOTO, SPACE POST
        if self.scrollSets.contains(self.posts[indexPath.item].value(forKey: "contentType") as! String) {
            let scrollCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "StoryScrollCell", for: indexPath) as! StoryScrollCell
            
            // Set PFObject
            scrollCell.postObject = self.posts[indexPath.item]
            // Set parent UIViewController
            scrollCell.delegate = self
            // Set UITableView Data Source and Delegates
            scrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
            return scrollCell
        }
        
        if self.posts[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.posts[indexPath.item].value(forKey: "videoAsset") != nil {
        // MOMENT VIDEO
            
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            // Add and play || pause video when visible
            if self.currentIndex == indexPath.item {
                // Set PFObject, parent UIViewController, update UI, and play video
                mvCell.postObject = self.posts[indexPath.item]
                mvCell.delegate = self
                mvCell.updateView(withObject: self.posts[indexPath.item], videoPlayer: self.vimVideoPlayerView)
                self.vimVideoPlayerView?.player.play()
            }
            
            return mvCell
        }
        
        if self.posts[indexPath.item].value(forKey: "contentType") as! String == "vi" && self.posts[indexPath.item].value(forKey: "videoAsset") != nil {
        // VIDEO
            
            let videoCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
            // Add and play || pause video when visible
            if self.currentIndex == indexPath.item {
                // Set PFObject, parent UIViewController, update UI, and play video
                videoCell.postObject = self.posts[indexPath.item]
                videoCell.delegate = self
                videoCell.updateView(withObject: self.posts[indexPath.item], videoPlayer: self.vimVideoPlayerView)
                self.vimVideoPlayerView?.player.play()
            }

            return videoCell
        }
        
        
        if self.posts[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.posts[indexPath.item].value(forKey: "photoAsset") != nil {
        // MOMENT PHOTO
            
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            mpCell.postObject = self.posts[indexPath.item]                // Set PFObject
            mpCell.delegate = self                                        // Set parent UIViewController
            mpCell.updateView(withObject: self.posts[indexPath.item])     // Update UI
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
        
        // Set currentIndex
        self.currentIndex! = indexPath.item
        
        // If currentIndex has videoAsset, replace VIMVideoPlayerView with new AVPlayerItem
        if self.posts[currentIndex!].value(forKey: "videoAsset") != nil {
            if let videoURL = self.posts[currentIndex!].value(forKey: "videoAsset") as? PFFile {
                let playerItem = AVPlayerItem(url: URL(string: videoURL.url!)!)
                self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: playerItem)
            }
            self.collectionView.reloadItems(at: [IndexPath(item: currentIndex!, section: 0)])
        } else if currentIndex! != 0 {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: currentIndex! - 1, section: 0)])
        } else if currentIndex! != self.posts.count {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: currentIndex! + 1, section: 0)])
        }

        
        // SAVE to "Views" if story is NOT the currentUser's story
        if (storyObjects.last!.object(forKey: "byUser") as! PFUser).objectId! != PFUser.current()!.objectId! {
            saveViews(withIndex: indexPath.item)
        }
        
        // Manipulate SegmentedProgressBar
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb?.skip()
        } else if self.lastOffSet!.x > scrollView.contentOffset.x {
            self.spb?.rewind()
        }
    }
}



/*
 MARK: - Stories Extension; Manages to present posts in a UITableViewCell if they are...
 • Text Posts
 • Photos
 • Profile Photos
 • Space Posts
 */
extension Stories: UITableViewDataSource, UITableViewDelegate {
    
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
            tpCell.postObject = self.posts[tableView.tag]                 // Set PFObject
            tpCell.superDelegate = self                                   // Set parent UIViewController
            tpCell.updateView(withObject: self.posts[tableView.tag])      // Update UI
            return tpCell
            
        } else if self.posts[tableView.tag].value(forKey: "contentType") as! String == "ph" {
            // PHOTO
            
            let phCell = Bundle.main.loadNibNamed("PhotoCell", owner: self, options: nil)?.first as! PhotoCell
            phCell.postObject = self.posts[tableView.tag]                 // Set PFObject
            phCell.superDelegate = self                                   // Set parent UIViewController
            phCell.updateView(withObject: self.posts[tableView.tag])      // Update UI
            return phCell
            
        } else if self.posts[tableView.tag].value(forKey: "contentType") as! String == "pp" {
            // PROFILE PHOTO
            
            let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell
            ppCell.postObject = self.posts[tableView.tag]                 // Set PFObject
            ppCell.superDelegate = self                                   // Set parent UIViewController
            ppCell.updateView(withObject: self.posts[tableView.tag])      // Update UI
            return ppCell
            
        } else {
            // SPACE POST
            let spCell = Bundle.main.loadNibNamed("SpacePostCell", owner: self, options: nil)?.first as! SpacePostCell
            spCell.postObject = self.posts[tableView.tag]                 // Set PFObject
            spCell.superDelegate = self                                   // Set parent UIViewController
            spCell.updateView(withObject: self.posts[tableView.tag])      // Update UI
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



/*
 MARK: - Stories Extension; Functions
 • configureView() = Configures reactButton (Reactions) and adds spb (SegmentedProgressBar)
 • like(_ ) = Likes/unlikes post
 • saveViews(_ ) = Handles whether to save viewed data to server or not
 • sendScreenShot(_ ) = Handles saving data and sending push notification if post was screenshotted
 • showOption(_ ) = Shows options for a given post
 */
extension Stories {
    
    // FUNCTION - Configure view
    func configureView() {
        // MARK: - SegmentedProgressBar
        self.spb = SegmentedProgressBar(numberOfSegments: self.posts.count, duration: 10)
        self.spb.frame = CGRect(x: 8, y: 8, width: self.view.frame.width - 16, height: 3)
        self.spb.topColor = UIColor.white
        self.spb.layer.applyShadow(layer: self.spb.layer)
        self.spb.padding = 2
        self.spb.delegate = self
        self.view.addSubview(self.spb)
        self.spb.startAnimation()
        
        // MARK: - Reactions
        // (2) Create ReactionSelector and add Reactions from <1> depending on the owner of the story
        reactionSelector.feedbackDelegate = self
        if (storyObjects.last!.object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            reactionSelector.setReactions([rpLike, rpComment, rpShare, rpViews, rpMore])
        } else {
            reactionSelector.setReactions([rpLike, rpComment, rpShare, rpMore])
        }
        
        // (3) Configure ReactionSelector
        reactionSelector.config = ReactionSelectorConfig {
            $0.spacing = 8
            $0.iconSize = 40
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
        
        reactButton.reaction = Reaction(id: "rpReact", title: "", color: .lightGray, icon: UIImage(named: "ReactButton")!)
        reactButton.center = self.view.center
        reactButton.frame.origin.y = self.view.bounds.height - reactButton.frame.size.height
        reactButton.layer.applyShadow(layer: reactButton.layer)
        view.addSubview(reactButton)
        view.bringSubview(toFront: reactButton)
    }
    
    // FUNCTION - Like Post
    func like(sender: Any) {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        // Query likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: self.posts[self.currentIndex!].objectId!)
        likes.whereKey("fromUser", equalTo: PFUser.current()!)
        likes.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                if objects!.isEmpty {
                    // LIKE POST
                    rpHelpers.reactLike(forPostObject: self.posts[self.currentIndex!])
                } else {
                    // UNLIKE POST
                    for object in objects! {
                        rpHelpers.reactUnlike(forLikeObject: object, forPostObject: self.posts[self.currentIndex!])
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
                // Show Error
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FUNCTION - Save Views
    func saveViews(withIndex: Int) {
        // Save to Views
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: self.posts[withIndex].objectId!)
        views.whereKey("byUser", equalTo: PFUser.current()!)
        views.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                if objects!.isEmpty {
                    // MARK: - Save PFObject
                    let views = PFObject(className: "Views")
                    views["byUser"] = PFUser.current()!
                    views["byUsername"] = PFUser.current()!.username!
                    views["forObjectId"] = self.posts[withIndex].objectId!
                    views["didScreenshot"] = false
                    views.saveInBackground()
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - Send Screenshot Notifiication
    func sendScreenshot() {
        // Update "didScreenshot" attribute in "Views"
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: self.posts[self.currentIndex!].objectId!)
        views.whereKey("byUser", equalTo: PFUser.current()!)
        views.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    object["didScreenshot"] = true
                    object.saveInBackground()
                    
                    // Save to Notifications
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = self.posts[self.currentIndex!].object(forKey: "byUser") as! PFUser
                    notifications["to"] =  (self.posts[self.currentIndex!].object(forKey: "byUser") as! PFUser).username!
                    notifications["forObjectId"] = object.value(forKey: "forObjectId") as! String
                    notifications["type"] = "screenshot"
                    notifications.saveInBackground()
                    
                    // MARK: - RPHelpers; send push notification
                    let rpHelpers = RPHelpers()
                    rpHelpers.pushNotification(toUser: self.posts[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "screenshotted your post.")
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    // FUNCTION - More options for post ***
    func showOption(sender: Any) {
        
        // Manipulate UIView Animations based on UIGestureRecognizer's state
        if (sender as! UILongPressGestureRecognizer).state == .began {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2,
                           options: .beginFromCurrentState,
                           animations: {
                            self.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                            // MARK: - RPExtensions
                            self.view.roundAllCorners(sender: self.view)
            }, completion: nil)
        } else if (sender as! UILongPressGestureRecognizer).state == .ended || (sender as! UILongPressGestureRecognizer).state == .cancelled {
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2,
                           options: .beginFromCurrentState,
                           animations: {
                            self.view.transform = CGAffineTransform.identity
                            // MARK: - RPExtensions
                            self.view.straightenCorners(sender: self.view)
            }, completion: nil)
        }
        
        // Set edit-able contentType's
        let editTypes = ["tp", "ph", "pp", "sp", "vi"]
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Options", message: nil)
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
            button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
            button.layer.masksToBounds = true
        }
        
        // (1) Delete Post
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Query post
            let posts = PFQuery(className: "Posts")
            posts.whereKey("objectId", equalTo: self.posts[self.currentIndex!].objectId!)
            posts.whereKey("byUser", equalTo: PFUser.current()!)
            posts.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Delete object
                        object.deleteInBackground()
                        
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Deleted")
                        
                        // Replace VIMVideoPlayer's AVPlayerItem if it's playing
                        self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
                        
                        // Replace userProfilePicture if contentType is "pp"
                        if object.value(forKey: "contentType") as! String == "pp" {
                            // Save PFFile context
                            let proPicData = UIImageJPEGRepresentation(UIImage(named: "GenderNeutralUser")!, 0.5)
                            let parseFile = PFFile(data: proPicData!)
                            // Replace with "GenderNeutralUser"
                            PFUser.current()!["userProfilePicture"] = parseFile
                            PFUser.current()!["proPicExists"] = false
                            PFUser.current()!.saveInBackground()
                        }
                        
                        // Reload data
                        self.posts.remove(at: self.currentIndex!)
                        self.collectionView.deleteItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                        
                        if self.posts.count == 0 {
                            // Hide reactButton
                            self.reactButton.isHidden = true
                            // Set DZN
                            self.collectionView.emptyDataSetSource = self
                            self.collectionView.emptyDataSetDelegate = self
                            self.collectionView.reloadEmptyDataSet()
                        } else {
                            if self.currentIndex! == 0 {
                                self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex! + 1, section: 0),
                                                                 at: .right, animated: true)
                            } else if self.currentIndex! == self.posts.count {
                                self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex! - 1, section: 0),
                                                                 at: .right, animated: true)
                            }
                        }
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        })
        
        // (2) Edit Post
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Show EditVC
            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            editVC.editObject = self.posts[self.currentIndex!]
            self.navigationController?.pushViewController(editVC, animated: true)
        })
        
        
        // (3) SAVE or UNSAVE ACTION; add tool action
        dialogController.rightToolAction = { (button) in
            // Query
            let posts = PFQuery(className: "Posts")
            posts.getObjectInBackground(withId: self.posts[self.currentIndex!].objectId!,
                                        block: { (object: PFObject?, error: Error?) in
                                            if error == nil {
                                                
                                                if object!["saved"] as! Bool == false {
                                                    object!["saved"] = true
                                                    // MARK: - RPHelpers
                                                    let rpHelpers = RPHelpers()
                                                    rpHelpers.showSuccess(withTitle: "Saved Post")
                                                } else if object!["saved"] as! Bool == true {
                                                    object!["saved"] = false
                                                    // MARK: - RPHelpers
                                                    let rpHelpers = RPHelpers()
                                                    rpHelpers.showAction(withTitle: "Unsaved Post")
                                                }
                                                object!.saveInBackground()
                                                
                                                // Dismiss dialog
                                                dialogController.dismiss()
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - RPHelpers
                                                let rpHelpers = RPHelpers()
                                                rpHelpers.showError(withTitle: "Network Error")
                                            }
            })
        }

        // (4) Report
        let report = AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            // MARK: - UIAlertController
            let alert = UIAlertController(title: "Report Post",
                                          message: "Please provide your reason for reporting this Post",
                                          preferredStyle: .alert)
            let report = UIAlertAction(title: "Report", style: .destructive) {
                [unowned self, alert] (action: UIAlertAction!) in
                let answer = alert.textFields![0]
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["to"] = (self.posts[self.currentIndex!].object(forKey: "byUser") as! PFUser).username!
                report["toUser"] = self.posts[self.currentIndex!].object(forKey: "byUser") as! PFUser
                report["forObjectId"] = self.posts[self.currentIndex!].objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: { (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved report: \(report)")
                        // Dismiss
                        dialog.dismiss()
                    } else {
                        print(error?.localizedDescription as Any)
                        // Dismiss
                        dialog.dismiss()
                    }
                })
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction: UIAlertAction!) in
                                        // Dismiss
                                        dialog.dismiss()
            })
            
            alert.addTextField(configurationHandler: nil)
            alert.addAction(report)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            dialog.present(alert, animated: true, completion: nil)
        })
        
        // (5) CANCEL
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        // Show options depending on who owns the post...
        if (self.posts[currentIndex!].object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Delete
            dialogController.addAction(delete)
            // Add saveButton
            dialogController.rightToolStyle = { (button) in
                button.setImage(UIImage(named: "Bookmark"), for: .normal)
                button.tintColor = .darkGray
                return true
            }
            // Add Edit Option
            if editTypes.contains(self.posts[self.currentIndex!].value(forKey: "contentType") as! String) {
                dialogController.addAction(edit)
            }
            dialogController.show(in: self)
        } else {
            // Report
            dialogController.addAction(report)
            dialogController.show(in: self)
        }
    }
}
