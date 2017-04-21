//
//  Timeline.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import AVKit
import AVFoundation

import AnimatedCollectionViewLayout
import Parse
import ParseUI
import Bolts

// Array to hold which user to fetch stories for
var storyForUser = [PFObject]()

class Timeline: UICollectionViewController {
    
    var posts = [PFObject]()
    var likes = [PFObject]()
    
    func fetchStories() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", equalTo: storyForUser.last!.value(forKey: "byUser") as! PFUser)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.includeKeys(["byUser", "toUser", "pointObject"])
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.posts.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.posts.append(object)
                }
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch stories
        fetchStories()
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = ZoomInOutAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.frame = self.view.bounds
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
    
    // MARK: - UICollectionViewHeader
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return self.view.bounds.size
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Configure initial setup for time
        let from = self.posts[indexPath.row].createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        
        let mCell = Bundle.main.loadNibNamed("MomentPhoto", owner: self, options: nil)?.first as! MomentPhoto
        let tpCell = Bundle.main.loadNibNamed("TextPostCell", owner: self, options: nil)?.first as! TextPostCell
        
        if self.posts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
         
            // (1) Set user's full name; "realNameOfUser"
            if let user = self.posts[indexPath.row].value(forKey: "byUser") as? PFUser {
                mCell.rpUsername.setTitle((user.value(forKey: "realNameOfUser") as! String), for: .normal)
            }
            
            // (2) Set time
            mCell.time.text = difference.getFullTime(difference: difference, date: from)
            
            // (3) Set time
            
            
            return mCell
            
        } else {
            return tpCell
        }
    }
    
    
}
