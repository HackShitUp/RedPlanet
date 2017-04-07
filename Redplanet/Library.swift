//
//  Library.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/9/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

import SwipeNavigationController

import Parse
import ParseUI
import Bolts


class Library: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // Initialize image picker
    var imagePicker: UIImagePickerController!
    // Array to hold all PHAssets
    var allAssets = [PHAsset]()
    
    // Refresher
    var refresher: UIRefreshControl!
    
    // Function to refresh
    func refresh() {
        self.fetchAssets()
        self.refresher.endRefreshing()
    }
    
    
    @IBAction func camera(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func picker(_ sender: Any) {
        // Instnatiate UIImagePickerController
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        // Present UIImagePickerController
        self.navigationController!.present(self.imagePicker, animated: true, completion: nil)
    }
    
    
    // UIImagePickercontroller Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let pickerMedia = info[UIImagePickerControllerMediaType] as! NSString
        
        
        if pickerMedia == kUTTypeImage {
            // Edited image
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                // Append PHAsset
                shareImageAssets.append(image)
            }
            
            mediaType = "photo"
            
            // Dismiss
            self.imagePicker.dismiss(animated: true, completion: nil)
            
            // Push VC
            let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
            self.navigationController!.pushViewController(shareMediaVC, animated: true)
        }
        
        if pickerMedia == kUTTypeMovie {
            // Selected image
            if let video = info[UIImagePickerControllerMediaURL] as? URL {
                instanceVideoData = video
            }
            
            mediaType = "video"
            
            // Dismiss
            self.imagePicker.dismiss(animated: true, completion: nil)
            
            // Push VC
            let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
            self.navigationController!.pushViewController(shareMediaVC, animated: true)
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dsimiss image picker
        self.imagePicker.dismiss(animated: true, completion: nil)
    }

    
    // Function to fetch assets
    func fetchAssets() {
        // Clear assets array
        self.allAssets.removeAll(keepingCapacity: false)

        // Options for fetching assets
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // Get all assets
        let all = PHAsset.fetchAssets(with: options)
        all.enumerateObjects({ (asset: PHAsset, i: Int, Bool) in
            // append PHAsset
            self.allAssets.append(asset)
        })
        
        // Reload data
        self.collectionView!.reloadData()
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Photos & Videos"
        }
        
        // Show tab bar and navigation bar and configure nav bar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: UIViewLifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize navigation bar
        configureView()
        // Create corner radiuss
        self.navigationController?.view.layer.cornerRadius = 8.00
        self.navigationController?.view.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.collectionView!.addSubview(refresher)
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        // Fetch Assets
        fetchAssets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Fetch Assets
        fetchAssets()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return self.allAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "libraryCell", for: indexPath) as! LibraryCell
        
        // Configure cell
        cell.thumbnail.layoutIfNeeded()
        cell.thumbnail.layoutSubviews()
        cell.thumbnail.setNeedsLayout()
        cell.contentView.frame = cell.contentView.frame
        
        // Set PHImageRequestOptions
        // To high quality; cancel pixelation
        // Synchronously called
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.isSynchronous = true
        PHImageManager.default().requestImage(for: self.allAssets[indexPath.row],
                                              targetSize: CGSize(width: UIScreen.main.bounds.size.width/3,
                                                                 height: UIScreen.main.bounds.size.width/3),
                                              contentMode: .aspectFit,
                                              options: nil) {
                                                (img, _) -> Void in
                                                
                                                // Set cell's image to photo
                                                cell.thumbnail.image = img
                                                
                                                // Configure Assets's design depending on mediaType
                                                if self.allAssets[indexPath.row].mediaType == .image {
                                                    cell.thumbnail.layer.cornerRadius = 2.00
                                                } else {
                                                    cell.thumbnail.layer.cornerRadius = cell.thumbnail.frame.size.width/2
                                                }
        }
        
        // Clip to bounds
        cell.thumbnail.clipsToBounds = true
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if self.allAssets[indexPath.row].mediaType == .image {
        // PHOTO
            mediaType = "photo"
            // Append PHAsset
            shareMediaAsset.append(self.allAssets[indexPath.item])
            
        } else {
        // VIDEO
            mediaType = "video"
            // Append PHAsset
            shareMediaAsset.append(self.allAssets[indexPath.item])
        }
        
        // Push VC
        let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
        self.navigationController?.pushViewController(shareMediaVC, animated: true)
    }

}
