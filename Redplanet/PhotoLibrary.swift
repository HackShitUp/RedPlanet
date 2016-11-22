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


// Source type
var libraryType: Int = 0

class PhotoLibrary: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // Variable to hold UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    
    // Array to hold PHAssets
    var photoAssets = [PHAsset]()
    
    @IBOutlet weak var photosVideos: UISegmentedControl!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop View Controller
        self.navigationController?.popViewController(animated: true)
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
    
    
    
    // Function to fetch Videos
    // V I D E O S
    func fetchVideos() {
        // Clear assets array
        self.photoAssets.removeAll(keepingCapacity: false)
        
        
        // Options for fetching assets
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Fetch assets
        let results = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: options)
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

        // Fetch assets depending on type
        if libraryType == 0 {
            // Fetch Photos
            fetchPhotos()
            
        } else {
            // Fetch Photos
            fetchVideos()
            
        }
        
        
        // Stylize title
        configureView()

        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        layout.itemSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.width/3)
        layout.itemSize = CGSize(width: self.view.frame.size.width/4, height: self.view.frame.size.width/4)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        
        // Hide TabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Open photo library
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title
        configureView()
        
        // Hide TabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    // Function to switch source
    func switchType(sender: UISegmentedControl) -> Int {
        if sender.selectedSegmentIndex == 0 {
            // Fetch photos
            fetchPhotos()
            
            // Set content type: photo
            libraryType = 0
            
        } else {
            // Fetch videos
            fetchVideos()
            
            // Set content type: video
            libraryType = 1
            
        }

        
        return libraryType
    }
    
    
    
    
    
    
    
    // MARK: UICollectionViewHeaderSection datasource
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        
        // ofSize should be the same size of the headerView's label size:
//        return CGSize(width: self.view.frame.size.width, height: 45)
        return CGSize(width: self.view.frame.size.width, height: 0)
    }

    // MARK: UICollectionViewHeader
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Initialize header
        let header = self.collectionView!.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "libraryHeader", for: indexPath) as! LibraryHeader
        
        // Add function method to switch between sources
        header.photosVideos.addTarget(self, action: #selector(switchType), for: .allEvents)
        
        return header
    }

    
    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
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

        
        if libraryType == 0 {
            mediaType = "photo"
        } else {
            mediaType = "video"
        }
        
        // Append PHAsset
        shareMediaAsset.append(photoAssets[indexPath.item])
        
        // Push VC
        let shareMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "shareMediaVC") as! ShareMedia
        self.navigationController!.pushViewController(shareMediaVC, animated: true)

    }

}
