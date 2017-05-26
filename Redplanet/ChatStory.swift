//
//  ChatStory.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/26/17.
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

class ChatStory: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, SegmentedProgressBarDelegate {
    
    // Array to hold chat moments
    var chatPosts = [PFObject]()
    
    // Used for skipping/rewinding segments
    var lastOffSet: CGPoint?
    // Variabel to hold currentIndex
    var currentIndex: Int? = 0
    
    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    // MARK: - VIMVideoPlayer
    var vimVideoPlayerView: VIMVideoPlayerView?

    @IBOutlet weak var collectionView: UICollectionView!
    
    // FUNCTION - Fetch Moments in Chats
    func fetchChat() {
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        
        let chats = PFQuery.orQuery(withSubqueries: [receiver, sender])
        chats.whereKey("contentType", equalTo: "itm")
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.chatPosts.removeAll(keepingCapacity: false)
                for object in objects!.reversed() {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 || (difference.hour! < 24 && object.value(forKey: "saved") as! Bool == true) {
                        self.chatPosts.append(object)
                    }
                }
                
                if self.chatPosts.count != 0 {
                    // Reload data in main thread and configureView
                    DispatchQueue.main.async(execute: {
                        // MARK: - SegmentedProgressBar
                        self.spb = SegmentedProgressBar(numberOfSegments: self.chatPosts.count, duration: 10)
                        self.spb.frame = CGRect(x: 8, y: 8, width: self.view.frame.width - 16, height: 3)
                        self.spb.topColor = UIColor.white
                        self.spb.layer.applyShadow(layer: self.spb.layer)
                        self.spb.padding = 2
                        self.spb.delegate = self
                        self.view.addSubview(self.spb)
                        self.spb.startAnimation()
                        
                        self.collectionView.reloadData()
                    })
                } else {
                    // TODO
                    // MARK: - DZNEmptyDataSet
                }
                
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
        fetchChat()
        
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
        return self.chatPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if self.chatPosts[indexPath.item].value(forKey: "contentType") as! String == "itm" && self.chatPosts[indexPath.item].value(forKey: "videoAsset") != nil {
            // MOMENT VIDEO
            
            let mvCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentVideo", for: indexPath) as! MomentVideo
            // Add and play || pause video when visible
            if self.currentIndex == indexPath.item {
                // Set PFObject, parent UIViewController, update UI, and play video
                mvCell.postObject = self.chatPosts[indexPath.item]
                mvCell.delegate = self

                // (1) Set usernames depending on who sent what
                if (self.chatPosts[indexPath.item].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    // Set Current user's username
                    mvCell.rpUsername.setTitle("\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)", for: .normal)
                } else {
                    // Set username
                    mvCell.rpUsername.setTitle("\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)", for: .normal)
                }
                
                // (2) Set time
                let from = self.chatPosts[indexPath.item].createdAt!
                let now = Date()
                let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                mvCell.time.text = difference.getFullTime(difference: difference, date: from)
                
                // (3) Add video
                if let video = self.chatPosts[indexPath.item].value(forKey: "videoAsset") as? PFFile {
                    
                    // MARK: - VIMVideoPlayer
                    vimVideoPlayerView!.frame = mvCell.contentView.bounds
                    vimVideoPlayerView!.player.isLooping = true
                    vimVideoPlayerView!.setVideoFillMode(AVLayerVideoGravityResizeAspect)
                    vimVideoPlayerView!.player.setURL(URL(string: video.url!)!)
                    vimVideoPlayerView!.player.isMuted = false
                    mvCell.contentView.addSubview(vimVideoPlayerView!)
                    mvCell.contentView.bringSubview(toFront: vimVideoPlayerView!)
                }
                
                // (4) Configure UI
                mvCell.contentView.bringSubview(toFront: mvCell.rpUsername)
                mvCell.contentView.bringSubview(toFront: mvCell.time)
                // MARK: - RPExtensions
                mvCell.rpUsername.layer.applyShadow(layer: mvCell.rpUsername.layer)
                mvCell.time.layer.applyShadow(layer: mvCell.time.layer)
            }
            
            return mvCell
            
        } else {
        // MOMENT PHOTO
            
            let mpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            mpCell.postObject = self.chatPosts[indexPath.item]                // Set PFObject
            mpCell.delegate = self                                            // Set parent UIViewController
            
            // (1) Set usernames depending on who sent what
            if (self.chatPosts[indexPath.item].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Set Current user's username
                mpCell.rpUsername.setTitle("\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)", for: .normal)
            } else {
                // Set username
                mpCell.rpUsername.setTitle("\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)", for: .normal)
            }
            
            // (2) Set time
            let from = self.chatPosts[indexPath.item].createdAt!
            let now = Date()
            let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            mpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set Photo
            if let photo = self.chatPosts[indexPath.item].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mpCell.photoMoment.sd_setImage(with: URL(string: photo.url!)!)
            }
            
            // (4) Bring name/time to front and add subview
            mpCell.contentView.bringSubview(toFront: mpCell.rpUsername)
            mpCell.contentView.bringSubview(toFront: mpCell.time)
            mpCell.rpUsername.layer.applyShadow(layer: mpCell.rpUsername.layer)
            mpCell.time.layer.applyShadow(layer: mpCell.time.layer)
            
            return mpCell
        }

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
        
        // Reload data
        self.collectionView!.reloadData()
        
        // Reload data
        if self.chatPosts[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex!, section: 0)])
        } else if self.currentIndex! != 0 && self.chatPosts[self.currentIndex! - 1].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! - 1, section: 0)])
        } else if self.currentIndex! != self.chatPosts.count && self.chatPosts[self.currentIndex!].value(forKey: "videoAsset") != nil {
            self.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            self.collectionView.reloadItems(at: [IndexPath(item: self.currentIndex! + 1, section: 0)])
        }
    }


}
