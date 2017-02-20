//
//  LibVideos.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/19/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

import Parse
import ParseUI
import Bolts



class LibVideos: UICollectionViewController, UINavigationControllerDelegate {
    
    // Initialize parent UINavigationController
    var roofedNavigator: UINavigationController?
    
    // Array to hold videos
    var videoAssets = [PHAsset]()
    
    // Function to fetch videos
    func fetchVideos() {
        // Clear assets array
        self.videoAssets.removeAll(keepingCapacity: false)
        
        // Options for fetching assets
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch assets
        let results = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: options)
        results.enumerateObjects({ (video: PHAsset, i: Int, Bool) in
            // append PHAsset
            self.videoAssets.append(video)
        })
        
        // Reload data
        self.collectionView!.reloadData()
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch videos
        fetchVideos()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/4, height: self.view.frame.size.width/4)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        // Fetch videos
        fetchVideos()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.videoAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "libVideosCell", for: indexPath) as! LibVideosCell
        
        // Set frame
        cell.contentView.frame = cell.bounds
        
        // LayoutViews
        cell.thumbnail.layoutIfNeeded()
        cell.thumbnail.layoutSubviews()
        cell.thumbnail.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.thumbnail.layer.cornerRadius = cell.thumbnail.frame.size.width/2.0
        cell.thumbnail.clipsToBounds = true
        
    
        // Set PHImageRequestOptions
        // To high quality; cancel pixelation
        // Synchronously called
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: videoAssets[indexPath.row],
                                              targetSize: CGSize(width: UIScreen.main.bounds.size.width/3,
                                                                 height: UIScreen.main.bounds.size.width/3),
                                              contentMode: .aspectFit,
                                              options: nil) {
                                                (img, _) -> Void in
                                                
                                                // set FIRST frame of video
                                                cell.thumbnail.image = img
        }
    
        return cell
    }
    
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        mediaType = "video"
        
        // Append PHAsset
        shareMediaAsset.append(self.videoAssets[indexPath.item])
        
        // Push VC
        let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
        self.roofedNavigator?.pushViewController(shareMediaVC, animated: true)   
    }


}
