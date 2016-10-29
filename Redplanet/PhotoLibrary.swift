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

class PhotoLibrary: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // Variable to hold UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    
    // Array to hold PHAssets
    var photoAssets = [PHAsset]()
    
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop View Controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func iosPhotos(_ sender: AnyObject) {
        // Load Photo Library
        DispatchQueue.main.async(execute: {
            self.navigationController!.present(self.imagePicker, animated: true, completion: nil)
        })
    }
    
    
    
    
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
    
    
    
    
    // UIImagePickercontroller Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Selected image
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        // TODO::
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
            self.title = "Photos Library"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch Photos
        fetchPhotos()
        
        // Stylize title
        configureView()
        
        
        // Hide TabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        
        
        // Open photo library
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)]
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
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
