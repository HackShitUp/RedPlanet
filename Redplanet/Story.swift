//
//  Story.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/12/17.
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

class Story: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    // MARK: - Class Variable; Used to get object and determine whether its for CHATS or Single Post
    open var storyObject: PFObject?
    
    // ScrollSets
    let scrollSets = ["tp", "pp", "ph", "vi", "sp"]
    // Array to hold posts; PFObject
    var posts = [PFObject]()

    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    // MARK: - VIMVideoPlayer
    var vimVideoPlayerView: VIMVideoPlayerView?
    
    // MARK: - Reactions; Initialize (1) ReactionButton, (2) ReactionSelector, (3) Reactions
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let reactionSelector = ReactionSelector()
    let reactions = [Reaction(id: "rpLike", title: "Like", color: .lightGray, icon: UIImage(named: "Like")!),
                     Reaction(id: "rpComment", title: "Comment", color: .lightGray, icon: UIImage(named: "Comment")!),
                     Reaction(id: "rpShare", title: "Share", color: .lightGray, icon: UIImage(named: "Share")!),
                     Reaction(id: "rpMore", title: "More", color: .lightGray, icon: UIImage(named: "MoreButton")!)]
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // FUNCTION - Fetch Story
    func fetchSingle() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: self.storyObject!.objectId!)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser"])
        newsfeeds.limit = 1
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                    }
                    self.posts.append(object)
                }
                
                // Reload data in main thread and configureView
                DispatchQueue.main.async(execute: {
                    if self.posts.count != 0 {
                        self.configureView()
                    } else {
                        // MARK: - DZNEmptyDataSet
                        self.collectionView.emptyDataSetSource = self
                        self.collectionView.emptyDataSetDelegate = self
                    }
                    self.collectionView.reloadData()
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    

    // MARK: - SegmentedProgressBar Delegate Methods
    func segmentedProgressBarChangedIndex(index: Int) {
        self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: true)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Reactions Delegate Method
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
                shareWithObject.append(self.posts[self.currentIndex!])
                let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                self.navigationController?.pushViewController(shareWithVC, animated: true)
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
        
        // MARK: - SVProgressHUD
        SVProgressHUD.setBackgroundColor(UIColor.clear)
        SVProgressHUD.setForegroundColor(UIColor.groupTableViewBackground)
        SVProgressHUD.setFont(UIFont(name: "AvenirNext-Medium", size: 21))
        SVProgressHUD.show()
        
        // Fetch Single Story
        fetchSingle()
        
        // MARK: - VIMVideoPlayerView
        vimVideoPlayerView = VIMVideoPlayerView()
        
        // MARK: - SubtleVolume
        let subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 7)
        subtleVolume.animation = .fadeIn
        subtleVolume.barTintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
    

    
    // MARK: UICollectionViewDataSource
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
        // Manipulate SegmentedProgressBar
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb?.skip()
        } else if self.lastOffSet!.x > scrollView.contentOffset.x {
            self.spb?.rewind()
        }
        
        // Get visible indexPath
        var visibleRect = CGRect()
        visibleRect.origin = self.collectionView!.contentOffset
        visibleRect.size = self.collectionView!.bounds.size
        let visiblePoint = CGPoint(x: CGFloat(visibleRect.midX), y: CGFloat(visibleRect.midY))
        let indexPath: IndexPath = self.collectionView!.indexPathForItem(at: visiblePoint)!
        
        // Set currentIndex
        self.currentIndex = indexPath.item
        // SAVE to Views
        saveViews(withIndex: indexPath.item)
        
        // Reload data
        self.collectionView!.reloadData()
        
        // Reload data
        if self.posts[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
        } else if self.currentIndex! != 0 && self.posts[self.currentIndex! - 1].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! - 1, section: 0)])
        } else if self.currentIndex! != self.posts.count && self.posts[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! + 1, section: 0)])
        }
    }
}


// MARK: - Story Extension for UITableViewDataSource and UITableViewDelegate Methods
extension Story: UITableViewDataSource, UITableViewDelegate {
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



// MARK: - Story; Functions for "configureView", "likePost", "unlikePost", "saveViews", and "showOptions"
extension Story {
    
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
        // (2) Create ReactionSelector and add Reactions from <1>
        reactionSelector.feedbackDelegate = self
        reactionSelector.setReactions(reactions)
        
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
        reactButton.reaction = Reaction(id: "rpReact", title: "", color: .lightGray, icon: UIImage(named: "ReactButton")!)
        reactButton.frame.origin.y = self.view.bounds.height - reactButton.frame.size.height
        reactButton.frame.origin.x = self.view.bounds.width/2 - reactButton.frame.size.width/2
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
        views.whereKey("forObject", equalTo: self.posts[withIndex])
        views.whereKey("byUser", equalTo: PFUser.current()!)
        views.countObjectsInBackground { (count: Int32, error: Error?) in
            if error == nil && count == 0 {
                // MARK: - Save PFObject
                let views = PFObject(className: "Views")
                views["byUser"] = PFUser.current()!
                views["byUsername"] = PFUser.current()!.username!
                views["forObject"] = self.posts[withIndex]
                views["screenshotted"] = false
                views.saveInBackground()
            } else {
                print("Error: \(error?.localizedDescription as Any)")
            }
        }
    }
    
    // FUNCTION - More options for post ***
    func showOption(sender: Any) {
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
            button.layer.borderColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1).cgColor
            button.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
            button.layer.masksToBounds = true
        }
        
        // (1) Show Views for post
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Views VC
            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            viewsVC.fetchObject = self.posts[self.currentIndex!]
            viewsVC.viewsOrLikes = "Views"
            self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) Delete Post
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Query post
            let posts = PFQuery(className: "Newsfeeds")
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
                        
                        // Replace userProfilePicture if contentType is "pp"
                        if object.value(forKey: "contentType") as! String == "pp" {
                            // Save PFFile context
                            let proPicData = UIImageJPEGRepresentation(UIImage(named: "GenderNeutralUser")!, 1)
                            let parseFile = PFFile(data: proPicData!)
                            // Replace with "GenderNeutralUser"
                            PFUser.current()!["userProfilePicture"] = parseFile
                            PFUser.current()!["proPicExists"] = false
                            PFUser.current()!.saveInBackground()
                        }
                        
                        // Reload data
                        self.posts.remove(at: self.currentIndex!)
                        self.collectionView.deleteItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                        if self.currentIndex! == 0 {
                            self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex! + 1, section: 0),
                                                             at: .right, animated: true)
                        } else if self.currentIndex! == self.posts.count {
                            self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex! - 1, section: 0),
                                                             at: .right, animated: true)
                        }
                        
                        // Dismiss
                        dialog.dismiss()
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        })
        
        // (3) Edit Post
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Show EditVC
            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            editVC.editObject = self.posts[self.currentIndex!]
            self.navigationController?.pushViewController(editVC, animated: true)
        })
        
        // (4) Save Post
        let save = AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
            let posts = PFQuery(className: "Newsfeeds")
            posts.whereKey("objectId", equalTo: self.posts[self.currentIndex!].objectId!)
            posts.whereKey("byUser", equalTo: PFUser.current()!)
            posts.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object["saved"] = true
                        object.saveInBackground()
                        
                        // Reload collectionView data and array data
                        self.posts[self.currentIndex!] = object
                        self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                        
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        })
        
        // (5) Unsave Post
        let unsave = AZDialogAction(title: "Unsave", handler: { (dialog) -> (Void) in
            let posts = PFQuery(className: "Newsfeeds")
            posts.whereKey("objectId", equalTo: self.posts[self.currentIndex!].objectId!)
            posts.whereKey("byUser", equalTo: PFUser.current()!)
            posts.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object["saved"] = false
                        object.saveInBackground()
                        
                        // Reload collectionView data and array data
                        self.posts[self.currentIndex!] = object
                        self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                        
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        })
        
        // (5) Report
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
                report["to"] = (self.posts[self.currentIndex!].value(forKey: "byUser") as! PFUser).username!
                report["toUser"] = self.posts[self.currentIndex!].value(forKey: "byUser") as! PFUser
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
            button.tintColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        
        if (self.posts[currentIndex!].value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Views/Delete
            dialogController.addAction(views)
            dialogController.addAction(delete)
            // Add Edit Option
            if editTypes.contains(self.posts[self.currentIndex!].value(forKey: "contentType") as! String) {
                dialogController.addAction(edit)
            }
            // Add Save/Unsave Option
            if self.posts[self.currentIndex!].value(forKey: "saved") as! Bool == true {
                dialogController.addAction(unsave)
            } else if self.posts[self.currentIndex!].value(forKey: "saved") as! Bool == false {
                dialogController.addAction(save)
            }
            dialogController.show(in: self)
        } else {
            // Report
            dialogController.addAction(report)
            dialogController.show(in: self)
        }
    }
}
