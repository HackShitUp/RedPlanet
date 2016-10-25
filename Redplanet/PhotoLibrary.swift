//
//  PhotoLibrary.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

class PhotoLibrary: UICollectionViewController, UINavigationControllerDelegate {
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Dismiss View Controller
//        self.dismiss(animated: true, completion: nil)
        self.navigationController!.popViewController(animated: true)
    }
    
    // Array to hold PHAssets
    var photoAssets = [PHAsset]()
    
    // Function to fetch PHAsset
    // P H O T O S
    func fetchPhotos() {
        print("Fired")
        
        // Clear assets array
        self.photoAssets.removeAll(keepingCapacity: false)
        
        
        // Options for fetching assets
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch assets
        let results = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: options)
        results.enumerateObjects({ (photo: PHAsset, i: Int, Bool) in
            // append PHAsset
            self.photoAssets.append(photo)
        })
        
        print("There are: \(self.photoAssets.count) photos")
        
        // Reload data
        self.collectionView!.reloadData()
        
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Photo Library"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch Photos
        fetchPhotos()
        
        
        // Set title
        self.title = "Photo Library"
        
        
        // Hide TabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    

    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        print("Returning: \(self.photoAssets.count) photos")
        return self.photoAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoLibraryCell", for: indexPath) as! PhotoLibraryCell
        
    
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
                                                                
                                                                // Set cell's image to either photo
                                                                // or FIRST frame of video
                                                                cell.photo.image = img
        }
        
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO::
    }

}
