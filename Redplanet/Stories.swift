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
import SVProgressHUD
import VIMVideoPlayer

// Array to hold storyObjects
var storyObjects = [PFObject]()

class Stories: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, SegmentedProgressBarDelegate, ReactionFeedbackDelegate {
    
    // ScrollSets for database <contentType>
    let scrollSets = ["tp", "ph", "pp", "sp"]
    
    // Array to hold stories
    var stories = [PFObject]()
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    
    // MARK: - VIMVideoPlayer
    var vimVideoPlayerView: VIMVideoPlayerView?
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    // MARK: - Reactions; Initialize (1) ReactionButton, (2) ReactionSelector, (3) Reactions
    let reactButton = ReactionButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    let reactionSelector = ReactionSelector()
    let reactions = [Reaction(id: "rpLike", title: "LIKE", color: .lightGray, icon: UIImage(named: "Like")!),
                     Reaction(id: "rpComment", title: "COMMENT", color: .lightGray, icon: UIImage(named: "Comment")!),
                     Reaction(id: "rpShare", title: "SHARE", color: .lightGray, icon: UIImage(named: "Share")!),
                     Reaction(id: "rpMore", title: "MORE", color: .lightGray, icon: UIImage(named: "MoreButton")!)]
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // FUNCTION - Configure view
    func configureView() {
        // MARK: - SegmentedProgressBar
        self.spb = SegmentedProgressBar(numberOfSegments: self.stories.count, duration: 10)
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
    
    // FUNCTION - Update Reactions
    func updateReactions() {
//        self.reactionSelector.setReactions(
//            [Reaction(id: "rpLike", title: "LIKE", color: .lightGray, icon: UIImage(named: "Like")!),
//             Reaction(id: "rpComment", title: "COMMENT", color: .lightGray, icon: UIImage(named: "Comment")!),
//             Reaction(id: "rpShare", title: "SHARE", color: .lightGray, icon: UIImage(named: "Share")!),
//             Reaction(id: "rpMore", title: "MORE", color: .lightGray, icon: UIImage(named: "MoreButton")!)
//            ])
        
//        let likes = PFQuery(className: "Likes")
//        likes.whereKey("forObjectId", equalTo: self.stories[currentIndex!].objectId!)
//        likes.countObjectsInBackground { (count: Int32, error: Error?) in
//            if error == nil {
//                if count != 0 {
//                    self.reactionSelector.setReactions(
//                        [Reaction(id: "rpLiked", title: "UNLIKE", color: .lightGray, icon: UIImage(named: "LikeFilled")!),
//                         Reaction(id: "rpComment", title: "COMMENT", color: .lightGray, icon: UIImage(named: "Comment")!),
//                         Reaction(id: "rpShare", title: "SHARE", color: .lightGray, icon: UIImage(named: "Share")!),
//                         Reaction(id: "rpMore", title: "MORE", color: .lightGray, icon: UIImage(named: "MoreButton")!)
//                        ])
//                }
//            } else {
//                print(error?.localizedDescription as Any)
//            }
//        }
    }

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
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear array
                self.stories.removeAll(keepingCapacity: false)
                // Reverse chronology
                for object in objects!.reversed() {
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
        self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: true)
    }
    
    func segmentedProgressBarFinished() {
        // Dismiss VC
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Reactions Delegate Method
    func reactionFeedbackDidChanged(_ feedback: ReactionFeedback?) {
        if feedback == nil || feedback == .tapToSelectAReaction {
            // Pause SegmentedProgressBar
            self.spb.isPaused = true
            switch reactionSelector.selectedReaction!.id {
                case "rpMore":
                // MORE
                    self.showOption(sender: self)
                case "rpLike":
                // LIKE
                    self.like(sender: self)
                case "rpComment":
                // COMMENT
                    reactionObject.append(self.stories[self.currentIndex!])
                    let reactionsVC = self.storyboard?.instantiateViewController(withIdentifier: "reactionsVC") as! Reactions
                    self.navigationController?.pushViewController(reactionsVC, animated: true)
                case "rpShare":
                // SHARE
                    shareWithObject.append(self.stories[self.currentIndex!])
                    let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                    self.navigationController?.pushViewController(shareWithVC, animated: true)
            default:
                break;
            }
        } else {
            self.spb.isPaused = false
        }
        // Reset ReactButton
        self.reactButton.reactionSelector?.selectedReaction = Reaction(id: "rpReact", title: "", color: .lightGray, icon: UIImage(named: "ReactButton")!)
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
        SVProgressHUD.setForegroundColor(UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
        SVProgressHUD.show()
        SVProgressHUD.show(withStatus: "\((storyObjects.last!.value(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String)")
        
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
        // Manipulate SegmentedProgressBar
        if self.lastOffSet!.x < scrollView.contentOffset.x {
            self.spb.skip()
        } else if self.lastOffSet!.x > scrollView.contentOffset.x {
            self.spb.rewind()
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
        
//        self.collectionView!.reloadData()

        // Reload data
        if self.stories[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
        } else if self.currentIndex! != 0 && self.stories[self.currentIndex! - 1].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! - 1, section: 0)])
        } else if self.currentIndex! != self.stories.count && self.stories[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! + 1, section: 0)])
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



// MARK: - Stories; Interactive functions go here...
extension Stories {
    
    // *** FUNCTION - Save Views ***
    func saveViews(withIndex: Int) {
        // Save to Views
        let views = PFQuery(className: "Views")
        views.whereKey("forObject", equalTo: self.stories[withIndex])
        views.whereKey("byUser", equalTo: PFUser.current()!)
        views.countObjectsInBackground { (count: Int32, error: Error?) in
            if error == nil && count == 0 {
                // MARK: - Save PFObject
                let views = PFObject(className: "Views")
                views["byUser"] = PFUser.current()!
                views["byUsername"] = PFUser.current()!.username!
                views["forObject"] = self.stories[withIndex]
                views["screenshotted"] = false
                views.saveInBackground()
            } else {
                print("Error: \(error?.localizedDescription as Any)")
            }
        }
    }
    
    // *** FUNCTION - More options for post ***
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
            viewsVC.fetchObject = self.stories[self.currentIndex!]
            viewsVC.viewsOrLikes = "Views"
            self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) Delete Post
        let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
            // Query post
            let posts = PFQuery(className: "Newsfeeds")
            posts.whereKey("objectId", equalTo: self.stories[self.currentIndex!].objectId!)
            posts.whereKey("byUser", equalTo: PFUser.current()!)
            posts.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        object.deleteInBackground()
                        
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Deleted")
                        
                        // Reload data
                        self.stories.remove(at: self.currentIndex!)
                        self.collectionView.deleteItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
                        if self.currentIndex! == 0 {
                            self.collectionView.scrollToItem(at: IndexPath(item: self.currentIndex! + 1, section: 0),
                                                             at: .right, animated: true)
                        } else if self.currentIndex! == self.stories.count {
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
            editVC.editObject = self.stories[self.currentIndex!]
            self.navigationController?.pushViewController(editVC, animated: true)
        })
        
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
                report["to"] = self.stories[self.currentIndex!].value(forKey: "username") as! String
                report["toUser"] = self.stories[self.currentIndex!].value(forKey: "byUser") as! PFUser
                report["forObjectId"] = self.stories[self.currentIndex!].objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: {
                    (success: Bool, error: Error?) in
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
            
            let cancel = UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: { (alertAction: UIAlertAction!) in
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
        
        if (self.stories[currentIndex!].value(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Views, Delete, Edit
            if editTypes.contains(self.stories[self.currentIndex!].value(forKey: "contentType") as! String) {
                dialogController.addAction(views)
                dialogController.addAction(delete)
                dialogController.addAction(edit)
                dialogController.show(in: self)
            } else {
            // Views and delete
                dialogController.addAction(views)
                dialogController.addAction(delete)
                dialogController.show(in: self)
            }
        } else {
            // Report
            dialogController.addAction(report)
            dialogController.show(in: self)
        }
    }
    
    
    
    // *** FUNCTION - Like Post ***
    func like(sender: Any) {
        /*
        // Like PFObject
        let likes = PFObject(className: "Likes")
        likes["byUser"] = PFUser.current()!
        likes["byUsername"] = PFUser.current()!.username!
        likes["toUser"] = self.stories[currentIndex!].object(forKey: "byUser") as! PFUser
        likes["toUsername"] = (self.stories[currentIndex!].object(forKey: "byUser") as! PFUser).username!
        likes["forObjectId"] = self.stories[currentIndex!].objectId!
        likes.saveInBackground(block: { (success: Bool, error: Error?) in
            if success {
                print("Successfully saved object: \(likes)")
                
//                // Re-enable button
//                activeButton!.isUserInteractionEnabled = true
//                
//                // Change button
//                activeButton!.setImage(UIImage(named: "LikeFilled"), for: .normal)
//                
//                // Animate like button
//                UIView.animate(withDuration: 0.6 ,
//                               animations: { activeButton!.transform = CGAffineTransform(scaleX: 0.6, y: 0.6) },
//                               completion: { finish in
//                                UIView.animate(withDuration: 0.5) {
//                                    activeButton!.transform = CGAffineTransform.identity
//                                }
//                })
                
                // Save to Notification in Background
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser
                notifications["to"] = (self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser).username!
                notifications["forObjectId"] = self.stories[self.currentIndex!].objectId!
                notifications["type"] = "like \(self.stories[self.currentIndex!].value(forKey: "contentType") as! String)"
                notifications.saveInBackground()
                
                // MARK: - RPHelpers; send pushNotification
                let rpHelpers = RPHelpers()
                switch self.stories[self.currentIndex!].value(forKey: "contentType") as! String {
                    case "tp":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Text Post")
                    case "ph":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Photo")
                    case "pp":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Profile Photo")
                    case "vi":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Video")
                    case "sp":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Space Post")
                    case "itm":
                    rpHelpers.pushNotification(toUser: self.stories[self.currentIndex!].object(forKey: "byUser") as! PFUser,
                                               activityType: "liked your Moment")
                default:
                    break;
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        */
    }
    
}
