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
import Reactions
import SDWebImage
import VIMVideoPlayer
import DZNEmptyDataSet

class Hashtags: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ReactionFeedbackDelegate {
    
    // MARK: - Class Configureable Variable
    var hashtagString = String()

    
    // ScrollSets for database <contentType>
    let scrollSets = ["tp", "ph", "pp", "sp"]
    // AppDelegate
    let appDelegate = AppDelegate()
    
    // Array to hold # PFObject ids...
    var hashtagIds = [String]()
    // Public users
    var publicUsers = [PFObject]()
    // Posts
    var posts = [PFObject]()
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    
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
    
    // FUNCTION - Fetch hashtags
    func fetchHastags() {
        let hashtags = PFQuery(className: "Hashtags")
        hashtags.whereKey("hashtag", equalTo: "#\(hashtagString)")
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
    
    // FUNCTION - Fetch hashtag Posts
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
                let postsClass = PFQuery(className: "Posts")
                postsClass.includeKey("byUser")
                postsClass.whereKey("byUser", containedIn: self.publicUsers)
                postsClass.whereKey("objectId", containedIn: self.hashtagIds)
                postsClass.order(byDescending: "createdAt")
                postsClass.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear array
                        self.posts.removeAll(keepingCapacity: false)
                        for object in objects! {
                            // Ephemeral content
                            let components : NSCalendar.Unit = .hour
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
                                // Save currentIndex
                                self.saveViews(withIndex: self.currentIndex!)
                            } else {
                                // MARK: - DZNEmptyDataSet
                                self.collectionView.emptyDataSetSource = self
                                self.collectionView.emptyDataSetDelegate = self
                                self.collectionView.reloadEmptyDataSet()
                            }
                            self.collectionView.reloadData()
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
            }
        }
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
        let attributeDictionary: [String: AnyObject]? = [ NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font!]
        return NSAttributedString(string: "💩\nUh oh, we couldn't find\n#\(self.hashtagString.uppercased())\n...",
            attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "OK"
        let font = UIFont(name: "AvenirNext-Bold", size: 17)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        self.navigationController?.dismiss(animated: true, completion: nil)
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
        layout.animator = CubeAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView!.collectionViewLayout = layout
        collectionView!.frame = self.view.bounds
        collectionView!.isPagingEnabled = true
        collectionView!.backgroundColor = UIColor.randomColor()
    
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "MomentVideo", bundle: nil), forCellWithReuseIdentifier: "MomentVideo")
        self.collectionView?.register(UINib(nibName: "StoryScrollCell", bundle: nil), forCellWithReuseIdentifier: "StoryScrollCell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        rpHelpers.showAction(withTitle: "#\(self.hashtagString.uppercased())")
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
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let storyScrollCell = cell as? StoryScrollCell else { return }
        storyScrollCell.setTableViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
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
            mpCell.delegate = self                                          // Set parent UIViewController
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
        currentIndex = indexPath.item
        
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

        // SAVE to Views
        saveViews(withIndex: indexPath.item)
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



// MARK: - Stories Functions
extension Hashtags {
    
    // FUNCTION - Configure view
    func configureView() {
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
            button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 15)
            button.layer.masksToBounds = true
        }
        
        // (1) Show Views for post
        let views = AZDialogAction(title: "Views", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Views VC
            let viewsVC = self.storyboard?.instantiateViewController(withIdentifier: "viewsVC") as! Views
            viewsVC.fetchObject = self.posts[self.currentIndex!]
            self.navigationController?.pushViewController(viewsVC, animated: true)
        })
        
        // (2) Delete Post
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
        
        // (3) Edit Post
        let edit = AZDialogAction(title: "Edit", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Show EditVC
            let editVC = self.storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditContent
            editVC.editObject = self.posts[self.currentIndex!]
            self.navigationController?.pushViewController(editVC, animated: true)
        })
        
        
        // (4) SAVE or UNSAVE ACTION; add tool action
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
        
        // (5) Report
        let report = AZDialogAction(title: "REPORT", handler: { (dialog) -> (Void) in
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
        
        // (6) CANCEL
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        // Show options depending on who owns the post...
        if (self.posts[currentIndex!].object(forKey: "byUser") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Views/Delete
            dialogController.addAction(views)
            dialogController.addAction(delete)
            // Add saveButton
            dialogController.rightToolStyle = { (button) in
                button.setImage(UIImage(named: "SaveWhite"), for: .normal)
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
