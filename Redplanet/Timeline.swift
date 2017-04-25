//
//  Timeline.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/22/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import AnimatedCollectionViewLayout
import SwipeNavigationController

// Array to hold timelineObjects
var timelineObjects = [PFObject]()

class Timeline: UICollectionViewController, UINavigationControllerDelegate {
    
    // Array to hold posts/likes
    var posts = [PFObject]()
    var likes = [PFObject]()
    
    func fetchStories() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: timelineObjects.last!.value(forKey: "byUser") as! PFUser)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Ephemeral content
                    let components: NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    if difference.hour! < 24 {
                        self.posts.append(object)
                    }
                }

                // Reload data
                self.collectionView!.reloadData()
                
                // MARK: - SegmentedProgressBar
                let spb = SegmentedProgressBar(numberOfSegments: 2, duration: 5)
                spb.frame = CGRect(x: 15, y: 15, width: self.view.frame.width - 30, height: 4)
                spb.topColor = UIColor.white
                spb.bottomColor = UIColor.white.withAlphaComponent(0.25)
                spb.padding = 2
                self.view.addSubview(spb)
                spb.startAnimation()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView(title: String?) {
        if title == "" {
            // MARK: - RPHelpers
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            // Show UIstatusBar
            UIApplication.shared.isStatusBarHidden = false
            UIApplication.shared.statusBarStyle = .lightContent
            self.setNeedsStatusBarAppearanceUpdate()
        } else {
            // Change the font and size of nav bar text
            if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
                let navBarAttributesDictionary: [String: AnyObject]? = [
                    NSForegroundColorAttributeName: UIColor.black,
                    NSFontAttributeName: navBarFont
                ]
                navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
                self.title = "\(title!)"
            }
            // MARK: - RPHelpers
            self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
            // Show UIstatusBar
            UIApplication.shared.isStatusBarHidden = false
            UIApplication.shared.statusBarStyle = .default
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    
    
    
    
//    public func panRecognized(recognizer:UIPanGestureRecognizer)
//    {
//        if recognizer.state == .Began && tableView.contentOffset.y == 0
//        {
//            recognizer.setTranslation(CGPointZero, inView : tableView)
//            
//            isTrackingPanLocation = true
//        }
//        else if recognizer.state != .Ended && recognizer.state != .Cancelled &&
//            recognizer.state != .Failed && isTrackingPanLocation
//        {
//            let panOffset = recognizer.translationInView(tableView)
//            
//            // determine offset of the pan from the start here.
//            // When offset is far enough from table view top edge -
//            // dismiss your view controller. Additionally you can
//            // determine if pan goes in the wrong direction and
//            // then reset flag isTrackingPanLocation to false
//            
//            let eligiblePanOffset = panOffset.y > 200
//            if eligiblePanOffset
//            {
//                recognizer.enabled = false
//                recognizer.enabled = true
//                self.dismissViewControllerAnimated(true, completion: nil)
//            }
//            
//            if panOffset.y < 0
//            {
//                isTrackingPanLocation = false
//            }
//        }
//        else
//        {
//            isTrackingPanLocation = false
//        }
//    }
//    
//    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
//                                  shouldRecognizeSimultaneouslyWithGestureRecognizer 
//        otherGestureRecognizer : UIGestureRecognizer)->Bool
//    {
//        return true
//    }

    

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide UITabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Hide rpButton
        rpButton.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = PageAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.frame = self.view.bounds
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        
        // Fetch stories
        fetchStories()
        
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panRecognized:")
//        panGestureRecognizer.delegate = self
//        self.view.addGestureRecognizer(panGestureRecognizer)
        
        // Register NIBS
        self.collectionView?.register(UINib(nibName: "MomentPhoto", bundle: nil), forCellWithReuseIdentifier: "MomentPhoto")
        self.collectionView?.register(UINib(nibName: "TextPostCell", bundle: nil), forCellWithReuseIdentifier: "TextPostCell")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = true
        // Show rpButton
        rpButton.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.frame.size
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
//        let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "timelineCell", for: indexPath) as! TimelineCell
//        
//        // Set delegate
//        cell.delegate = self.navigationController
//        
//        // Set postObject
//        cell.postObject = self.posts[indexPath.row]
//        
//        // Configure view
//        cell.configureView()
//        
//        return cell
        

        // Configure initial setup for time
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        // TEXT POST
        if self.posts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
            let tpCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "TextPostCell", for: indexPath) as! TextPostCell
            
            print("CV FRAME: \(tpCell.contentView.frame)")
            
            // Set delegate
            tpCell.delegate = self
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
                tpCell.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
                
                // (2) Set user's profile photo
                if let proPic = user["userProfilePicture"] as? PFFile {
                    // MARK: - SDWebImage
                    tpCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
                    // MARK: - RPHelpers
                    tpCell.rpUserProPic.makeCircular(imageView: tpCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
                }
            }
            
            // (3) Set time
            tpCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (4) Set Text Post
            tpCell.textPost.text = (self.posts[indexPath.row].value(forKey: "textPost") as! String)
            
            return tpCell

        } else {
        // MOMENT PHOTO
            let mCell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "MomentPhoto", for: indexPath) as! MomentPhoto
            
            print("CV FRAME: \(mCell.contentView.frame)")
            
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
                mCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) Set time
            mCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set photo
            if let moment = self.posts[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                mCell.photoMoment.sd_showActivityIndicatorView()
                mCell.photoMoment.sd_setIndicatorStyle(.gray)
                mCell.photoMoment.sd_setImage(with: URL(string: moment.url!)!)
            }

            return mCell
        }

    
    
    }
}
