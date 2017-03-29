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
// Bool to determine # of Moments to load
var single: Bool = false

class Moments: UICollectionViewController, UINavigationControllerDelegate, PlayerDelegate {

    // Arrays to hold objects
    var moments = [PFObject]()
    // Array to hold like objects
    var likes = [PFObject]()
    
    var player: Player!
    
    
    func dismiss() {
        // POP VC
        self.navigationController?.radialPopViewController(withDuration: 0.2, withStartFrame: CGRect(x: CGFloat(self.view.frame.size.width/2), y: CGFloat(self.view.frame.size.height), width: CGFloat(0), height: CGFloat(0)), comlititionBlock: {() -> Void in
        })
    }
    
    func fetchMoments() {
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
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    func fetchContent() {
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: momentObjects.last!.objectId!)
        newsfeeds.whereKey("contentType", equalTo: "itm")
        newsfeeds.order(byAscending: "createdAt")
        newsfeeds.includeKey("byUser")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.moments.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.moments.append(object)
                }
                
                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch all Moments or a Moment depending on where it was loaded from
        if single == true {
            fetchContent()
        } else {
            fetchMoments()
        }
        
        // Hide navigationBar and tabBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Hide statusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        
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
        self.collectionView!.frame = self.view.bounds
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
            mpCell.postObject = self.moments[indexPath.row]
            mpCell.configureMoment()
            mpCell.fetchContent()
            
            return mpCell
        } else {
        // VIDEO
            let mvCell = self.collectionView!.dequeueReusableCell(withReuseIdentifier: "MomentsVideo", for: indexPath) as! MomentsVideo
            mvCell.delegate = self
            mvCell.postObject = self.moments[indexPath.row]
            mvCell.configureMoment()
            mvCell.fetchContent()
            
            return mvCell
        }
    }
}
