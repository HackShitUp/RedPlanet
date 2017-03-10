//
//  PhotosLibrary.swift
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


class PhotosLibrary: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // Initialize image picker
    var imagePicker: UIImagePickerController!
    // Array to hold photos
    var photoAssets = [PHAsset]()
    // Array to hold videos
    var videoAssets = [PHAsset]()
    
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
        self.photoAssets.removeAll(keepingCapacity: false)
        // Clear assets array
        self.videoAssets.removeAll(keepingCapacity: false)
        
        // Options for fetching assets
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch assets
        let photos = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
        photos.enumerateObjects({ (photo: PHAsset, i: Int, Bool) in
            // append PHAsset
            self.photoAssets.append(photo)
        })
        
        // Fetch assets
        let videos = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: options)
        videos.enumerateObjects({ (video: PHAsset, i: Int, Bool) in
            // append PHAsset
            self.videoAssets.append(video)
        })
        
        // Reload data
        self.collectionView!.reloadData()
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0),
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
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: UIViewLifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize navigation bar
        configureView()
        // Fetch Assets
        fetchAssets()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        // Size should be the same size of the headerView's label size:
        return CGSize(width: self.view.frame.size.width, height: 44.00)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = UICollectionReusableView()
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "AvenirNext-Demibold", size: 12.00)
        label.textColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
        
        if indexPath.section == 0 {
            label.text = "   PHOTOS"
            headerView.addSubview(label)
        } else {
            label.text = "   PHOTOS"
            headerView.addSubview(label)
        }
        
        return headerView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return self.photoAssets.count
        } else {
            return self.videoAssets.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "libraryCell", for: indexPath) as! LibraryCell
        
        // Configure cell
        cell.thumbnail.layoutIfNeeded()
        cell.thumbnail.layoutSubviews()
        cell.thumbnail.setNeedsLayout()
        cell.contentView.frame = cell.contentView.frame
        
        if indexPath.section == 0 {
        // PHOTOS
            // Set frame
            cell.thumbnail.layer.cornerRadius = 6.00
            cell.thumbnail.clipsToBounds = true
            
            // Set PHImageRequestOptions
            // To high quality; cancel pixelation
            // Synchronously called
            let imageOptions = PHImageRequestOptions()
            imageOptions.deliveryMode = .highQualityFormat
            imageOptions.isSynchronous = true
            
            PHImageManager.default().requestImage(for: photoAssets[indexPath.row],
                                                  targetSize: CGSize(width: UIScreen.main.bounds.size.width/3,
                                                                     height: UIScreen.main.bounds.size.width/3),
                                                  contentMode: .aspectFit,
                                                  options: nil) {
                                                    (img, _) -> Void in
                                                    
                                                    // Set cell's image to photo
                                                    cell.thumbnail.image = img
            }
        } else {
        // VIDEOS
            
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
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
        // PHOTO
            mediaType = "photo"
            // Append PHAsset
            shareMediaAsset.append(photoAssets[indexPath.item])

        } else {
        // VIDEO
            mediaType = "video"
            // Append PHAsset
            shareMediaAsset.append(self.videoAssets[indexPath.item])
        }
        
        // Push VC
        let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
        self.navigationController?.pushViewController(shareMediaVC, animated: true)
    }

}
