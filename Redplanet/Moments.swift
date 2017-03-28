//
//  Moments.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/28/17.
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
import SDWebImage
import SVProgressHUD


/*
 To make this work, simply set the UICollectionViewCell to
 CUSTOM
 in Storyboard
 */


// Global array to hold moments
var momentObjects = [PFObject]()

class Moments: UICollectionViewController, UINavigationControllerDelegate {

    // Arrays to hold objects
    var moments = [PFObject]()
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    
    func dismiss() {
        // POP VC
        self.navigationController?.radialPopViewController(withDuration: 0.2, withStartFrame: CGRect(x: CGFloat(self.view.frame.size.width/2), y: CGFloat(self.view.frame.size.height), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {() -> Void in
        })
    }
    
    func fetchMoments() {
        print("FIRED")
        
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: momentObjects.last!.object(forKey: "byUser") as! PFUser)
        newsfeeds.whereKey("contentType", equalTo: "itm")
        newsfeeds.order(byAscending: "createdAt")
        newsfeeds.includeKey("byUser")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.moments.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.moments.append(object)
                    }
                }
             
                print("COUNT: \(self.moments.count)")
                
                // Reload data in the main thread
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchMoments()
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = CubeAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.isPagingEnabled = true
        
        // Register Nibs
        self.collectionView!.register(UINib(nibName: "MomentsPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentsPhoto")
        self.collectionView!.register(UINib(nibName: "MomentsVideo", bundle: nil), forCellWithReuseIdentifier: "MomentsVideo")
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
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.moments.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.moments[indexPath.row].value(forKey: "photoAsset") != nil {
            // PHOTO
            let mpCell = self.collectionView!.dequeueReusableCell(withReuseIdentifier: "MomentsPhoto", for: indexPath) as! MomentsPhoto
            mpCell.delegate = self
            mpCell.stillObject = self.moments[indexPath.row]

            // (1) Load moment
            if let moment = self.moments[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mpCell.stillMoment.sd_setImage(with: URL(string: moment.url!), placeholderImage: mpCell.stillMoment.image)
            }
            
            // (2) Set username
            if let user = itmObject.last!.object(forKey: "byUser") as? PFUser {
                mpCell.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
            }
            
            // (3) Set time
            let from = itmObject.last!.createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            if difference.second! <= 0 {
                mpCell.time.text = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    mpCell.time.text = "1 second ago"
                } else {
                    mpCell.time.text = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    mpCell.time.text = "1 minute ago"
                } else {
                    mpCell.time.text = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    mpCell.time.text = "1 hour ago"
                } else {
                    mpCell.time.text = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    mpCell.time.text = "1 day ago"
                } else {
                    mpCell.time.text = "\(difference.day!) days ago"
                }
                if itmObject.last!.value(forKey: "saved") as! Bool == true {
                    mpCell.likeButton.isUserInteractionEnabled = false
                    mpCell.numberOfLikes.isUserInteractionEnabled = false
                    mpCell.commentButton.isUserInteractionEnabled = false
                    mpCell.numberOfComments.isUserInteractionEnabled = false
                    mpCell.shareButton.isUserInteractionEnabled = false
                    mpCell.numberOfShares.isUserInteractionEnabled = false
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                mpCell.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
                if itmObject.last!.value(forKey: "saved") as! Bool == true {
                    mpCell.likeButton.isUserInteractionEnabled = false
                    mpCell.numberOfLikes.isUserInteractionEnabled = false
                    mpCell.commentButton.isUserInteractionEnabled = false
                    mpCell.numberOfComments.isUserInteractionEnabled = false
                    mpCell.shareButton.isUserInteractionEnabled = false
                    mpCell.numberOfShares.isUserInteractionEnabled = false
                }
            }
            
            
            // (4) Fetch likes
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
            likes.includeKey("fromUser")
            likes.order(byDescending: "createdAt")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.likes.removeAll(keepingCapacity: false)
                    
                    // (A) Append objects
                    for object in objects! {
                        self.likes.append(object["fromUser"] as! PFUser)
                    }
                    
                    // (B) Manipulate likes
                    if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
                        // liked
                        mpCell.likeButton.setTitle("liked", for: .normal)
                        mpCell.likeButton.setImage(UIImage(named: "WhiteLikeFilled"), for: .normal)
                    } else {
                        // notLiked
                        mpCell.likeButton.setTitle("notLiked", for: .normal)
                        mpCell.likeButton.setImage(UIImage(named: "WhiteLike"), for: .normal)
                    }
                    
                    // (C) Set number of likes
                    if self.likes.count == 0 {
                        mpCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        mpCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        mpCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            //
            //
            //            // (5) Fetch comments
            //            let comments = PFQuery(className: "Comments")
            //            comments.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
            //            comments.findObjectsInBackground(block: {
            //                (objects: [PFObject]?, error: Error?) in
            //                if error == nil {
            //                    // Clear arrays
            //                    self.comments.removeAll(keepingCapacity: false)
            //
            //                    // (A) Append objects
            //                    for object in objects! {
            //                        self.comments.append(object)
            //                    }
            //
            //                    // (B) Set number of comments
            //                    if self.comments.count == 0 {
            //                        self.numberOfComments.setTitle("comments", for: .normal)
            //                    } else if self.comments.count == 1 {
            //                        self.numberOfComments.setTitle("1 comment", for: .normal)
            //                    } else {
            //                        self.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
            //                    }
            //
            //                } else {
            //                    print(error?.localizedDescription as Any)
            //                }
            //            })
            //
            //
            //            // (6) Fetch shares
            //            let shares = PFQuery(className: "Newsfeeds")
            //            shares.whereKey("contentType", equalTo: "sh")
            //            shares.whereKey("pointObject", equalTo: itmObject.last!)
            //            shares.findObjectsInBackground(block: {
            //                (objects: [PFObject]?, error: Error?) in
            //                if error == nil {
            //                    // Clear arrays
            //                    self.shares.removeAll(keepingCapacity: false)
            //
            //                    // (A) Append objects
            //                    for object in objects! {
            //                        self.shares.append(object)
            //                    }
            //
            //                    // (B) Set number of shares
            //                    if self.shares.count == 0 {
            //                        self.numberOfShares.setTitle("shares", for: .normal)
            //                    } else if self.shares.count == 1 {
            //                        self.numberOfShares.setTitle("1 share", for: .normal)
            //                    } else {
            //                        self.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
            //                    }
            //
            //                } else {
            //                    print(error?.localizedDescription as Any)
            //                }
            //            })
            
            
            
            
            return mpCell
        } else {
            // VIDEO            
            let mvCell = self.collectionView!.dequeueReusableCell(withReuseIdentifier: "MomentsVideo", for: indexPath) as! MomentsVideo
            
            mvCell.delegate = self
            
            // (1) Load moment
            if let momentVideo = self.moments[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                
                //                // MARK: Player
                //                mvCell.player = Player()
                //                mvCell.player.delegate = self
                //                mvCell.player.view.frame = self.view.bounds
                //                mvCell.addChildViewController(self.player)
                //                mvCell.contentView.addSubview(self.player.view)
                //                mvCell.player.didMove(toParentViewController: self)
                //                mvCell.player.url = URL(string: momentVideo.url!)
                //                mvCell.player.fillMode = "AVLayerVideoGravityResizeAspect"
                //                mvCell.player.playbackLoops = true
                //                mvCell.player.playFromBeginning()
                
                // MARK: - SDWebImage
//                mvCell.videoPreview.sd_setShowActivityIndicatorView(true)
//                mvCell..sd_setIndicatorStyle(.gray)
                
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: momentVideo.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = mvCell.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                mvCell.contentView.contentMode = .scaleToFill
                mvCell.contentView.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
                
                // Store buttons in an array
                let buttons = [mvCell.likeButton,
                               mvCell.numberOfLikes,
                               mvCell.commentButton,
                               mvCell.numberOfComments,
                               mvCell.shareButton,
                               mvCell.numberOfShares,
                               mvCell.rpUsername,
                               mvCell.time,
                               mvCell.moreButton] as [Any]
                // Add shadows and bring view to front
                for b in buttons {
                    (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
                    (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
                    (b as AnyObject).layer.shadowRadius = 3
                    (b as AnyObject).layer.shadowOpacity = 0.6
                    self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                    //                    self.player.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                }
            }
            
            // (2) Set username
            if let user = self.moments[indexPath.row].object(forKey: "byUser") as? PFUser {
                mvCell.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
            }
            
            // (3) Set time
            let from = itmObject.last!.createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            if difference.second! <= 0 {
                mvCell.time.text = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                if difference.second! == 1 {
                    mvCell.time.text = "1 second ago"
                } else {
                    mvCell.time.text = "\(difference.second!) seconds ago"
                }
            } else if difference.minute! > 0 && difference.hour! == 0 {
                if difference.minute! == 1 {
                    mvCell.time.text = "1 minute ago"
                } else {
                    mvCell.time.text = "\(difference.minute!) minutes ago"
                }
            } else if difference.hour! > 0 && difference.day! == 0 {
                if difference.hour! == 1 {
                    mvCell.time.text = "1 hour ago"
                } else {
                    mvCell.time.text = "\(difference.hour!) hours ago"
                }
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                if difference.day! == 1 {
                    mvCell.time.text = "1 day ago"
                } else {
                    mvCell.time.text = "\(difference.day!) days ago"
                }
                if itmObject.last!.value(forKey: "saved") as! Bool == true {
                    mvCell.likeButton.isUserInteractionEnabled = false
                    mvCell.numberOfLikes.isUserInteractionEnabled = false
                    mvCell.commentButton.isUserInteractionEnabled = false
                    mvCell.numberOfComments.isUserInteractionEnabled = false
                    mvCell.shareButton.isUserInteractionEnabled = false
                    mvCell.numberOfShares.isUserInteractionEnabled = false
                }
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM d, yyyy"
                mvCell.time.text = createdDate.string(from: spaceObject.last!.createdAt!)
                if itmObject.last!.value(forKey: "saved") as! Bool == true {
                    mvCell.likeButton.isUserInteractionEnabled = false
                    mvCell.numberOfLikes.isUserInteractionEnabled = false
                    mvCell.commentButton.isUserInteractionEnabled = false
                    mvCell.numberOfComments.isUserInteractionEnabled = false
                    mvCell.shareButton.isUserInteractionEnabled = false
                    mvCell.numberOfShares.isUserInteractionEnabled = false
                }
            }
            
            // (4) Fetch likes
            let likes = PFQuery(className: "Likes")
            likes.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
            likes.includeKey("fromUser")
            likes.order(byDescending: "createdAt")
            likes.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear array
                    self.likes.removeAll(keepingCapacity: false)
                    
                    // (A) Append objects
                    for object in objects! {
                        self.likes.append(object["fromUser"] as! PFUser)
                    }
                    
                    
                    // (B) Manipulate likes
                    if self.likes.contains(where: { $0.objectId == PFUser.current()!.objectId! }) {
                        // liked
                        mvCell.likeButton.setTitle("liked", for: .normal)
                        mvCell.likeButton.setImage(UIImage(named: "WhiteLikeFilled"), for: .normal)
                    } else {
                        // notLiked
                        mvCell.likeButton.setTitle("notLiked", for: .normal)
                        mvCell.likeButton.setImage(UIImage(named: "WhiteLike"), for: .normal)
                    }
                    
                    // (C) Set number of likes
                    if self.likes.count == 0 {
                        mvCell.numberOfLikes.setTitle("likes", for: .normal)
                    } else if self.likes.count == 1 {
                        mvCell.numberOfLikes.setTitle("1 like", for: .normal)
                    } else {
                        mvCell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
            //            // (5) Fetch comments
            //            let comments = PFQuery(className: "Comments")
            //            comments.whereKey("forObjectId", equalTo: itmObject.last!.objectId!)
            //            comments.findObjectsInBackground(block: {
            //                (objects: [PFObject]?, error: Error?) in
            //                if error == nil {
            //                    // Clear arrays
            //                    self.comments.removeAll(keepingCapacity: false)
            //
            //                    // (A) Append objects
            //                    for object in objects! {
            //                        self.comments.append(object)
            //                    }
            //
            //                    // (B) Set number of comments
            //                    if self.comments.count == 0 {
            //                        self.numberOfComments.setTitle("comments", for: .normal)
            //                    } else if self.comments.count == 1 {
            //                        self.numberOfComments.setTitle("1 comment", for: .normal)
            //                    } else {
            //                        self.numberOfComments.setTitle("\(self.comments.count) comments", for: .normal)
            //                    }
            //
            //                } else {
            //                    print(error?.localizedDescription as Any)
            //                }
            //            })
            //
            //
            //            // (6) Fetch shares
            //            let shares = PFQuery(className: "Newsfeeds")
            //            shares.whereKey("contentType", equalTo: "sh")
            //            shares.whereKey("pointObject", equalTo: itmObject.last!)
            //            shares.findObjectsInBackground(block: {
            //                (objects: [PFObject]?, error: Error?) in
            //                if error == nil {
            //                    // Clear arrays
            //                    self.shares.removeAll(keepingCapacity: false)
            //                    
            //                    // (A) Append objects
            //                    for object in objects! {
            //                        self.shares.append(object)
            //                    }
            //                    
            //                    // (B) Set number of shares
            //                    if self.shares.count == 0 {
            //                        self.numberOfShares.setTitle("shares", for: .normal)
            //                    } else if self.shares.count == 1 {
            //                        self.numberOfShares.setTitle("1 share", for: .normal)
            //                    } else {
            //                        self.numberOfShares.setTitle("\(self.shares.count) shares", for: .normal)
            //                    }
            //                    
            //                } else {
            //                    print(error?.localizedDescription as Any)
            //                }
            //            })

            return mvCell
        }
    }
    
    
    

    
}
