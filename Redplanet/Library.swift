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

import Parse
import ParseUI
import Bolts

import DZNEmptyDataSet
import SDWebImage
import SwipeNavigationController
import TRMosaicLayout

/*
 UICollectionViewController class that presents a user's photos on their devices in a "waterfall-style" grid format.
 Works with "CollectionCell.swift" to bind data and present the image in the UICollectionViewCell. This class pushes to "NewMedia.swift"
 once the asset was selected from the UICollectionViewCell or from UIImagePickerController.
 */

class Library: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    // Array to hold all PHAssets
    var allAssets = [PHAsset]()
    
    // Initialized UIImagePickerController
    var imagePicker: UIImagePickerController!
    // Initialized UIRefreshControl
    var refresher: UIRefreshControl!
    
    // FUNCTION - To refresh
    func refresh() {
        self.fetchAssets()
        self.refresher.endRefreshing()
    }
    
    @IBAction func camera(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func picker(_ sender: Any) {
        // MARK: - UIImagePickerController
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.tintColor = UIColor.black
        
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            imagePicker?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            imagePicker?.title = "Photos & Videos"
        }
        
        
        navigationController?.present(self.imagePicker, animated: true, completion: nil)
    }
    
    // FUNCTION - Scroll to the top of UICollectionView
    func scrollToTop() {
        self.collectionView?.setContentOffset(.zero, animated: true)
    }
    
    // FUNCTION - Fetch all PHAssets
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

        if self.allAssets.count != 0 {
            // Reload data in main thread
            DispatchQueue.main.async(execute: {
                self.collectionView?.reloadData()
                self.collectionView?.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
        } else {
            // MARK: - DZNEmptyDataSet
            self.collectionView?.emptyDataSetSource = self
            self.collectionView?.emptyDataSetDelegate = self
        }
    }
    
    

    // FUNCTION - Stylize and set title of UINavigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Photos & Videos"
        }
        
        // Configure UINavigationBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: DZNEmptyDataSet
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.allAssets.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💩\nAccess to your Photos are currently denied."
        let font = UIFont(name: "AvenirNext-Medium", size: 30)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.black,
            NSFontAttributeName: font!]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        // Title for button
        let str = "Allow Access"
        let font = UIFont(name: "AvenirNext-Demibold", size: 15)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1),
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            switch status{
            case .authorized:
                print("Authorized")
                // Fetch Assets
                self.fetchAssets()
                
                break
            case .denied:
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Photos Access Denied",
                                                              message: "Please allow Redplanet access your Photos.")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.layer.masksToBounds = true
                }
                
                // Add settings button
                dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    // Show Settings
                    UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                }))
                
                // Cancel
                dialogController.cancelButtonStyle = { (button,height) in
                    button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.setTitle("CANCEL", for: [])
                    return true
                }
                dialogController.show(in: self)
                break
            default:
                break;
            }
        })
    }
    

    // MARK: UIViewLifeCycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize UINavigationBar
        configureView()
        // MARK: - RPExtensions; Create corner radius
        self.navigationController?.view.roundAllCorners(sender: navigationController?.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch Assets
        fetchAssets()
        
        // Add tap method to scroll to top
        let scrollTap = UITapGestureRecognizer(target: self, action: #selector(scrollToTop))
        scrollTap.numberOfTapsRequired = 1
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        self.navigationController?.navigationBar.addGestureRecognizer(scrollTap)
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView!.addSubview(refresher)
        
        // MARK: - TRMosaicLayout
        let mosaicLayout = TRMosaicLayout()
        mosaicLayout.delegate = self
        collectionView!.collectionViewLayout = mosaicLayout
        
        // Register NIBS
        collectionView!.register(UINib(nibName: "CollectionCell", bundle: nil), forCellWithReuseIdentifier: "CollectionCell")
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
    
    // MARK: - UIImagePickerController Delegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Dismiss and show NewMedia
        self.imagePicker.dismiss(animated: true) {
            // Instantiate NewMedia and pass IMAGE or VIDEO to NewMedia
            let newMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "newMediaVC") as! NewMedia
            newMediaVC.selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage
            newMediaVC.selectedURL = info[UIImagePickerControllerMediaURL] as? URL
            if info[UIImagePickerControllerMediaType] as! NSString == kUTTypeImage {            // IMAGE
                newMediaVC.mediaType = "image"
            } else if info[UIImagePickerControllerMediaType] as! NSString == kUTTypeMovie {     // VIDEO
                newMediaVC.mediaType = "video"
            }
            self.navigationController?.pushViewController(newMediaVC, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dimiss
        imagePicker.dismiss(animated: true, completion: nil)
    }

    // MARK: - UICollectionView Data Source Methods
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.allAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
        
        // Set bounds
        cell.contentView.frame = cell.contentView.frame
        cell.assetPreview.frame = cell.contentView.frame
        // Configure contentMode
        cell.assetPreview.contentMode = .scaleAspectFill
        
        // MARK: - PHImageRequestOptions; Call synchronously to return high quality assets
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
                                                cell.assetPreview.image = img
                                                
                                                // Configure Assets's design depending on mediaType
                                                if self.allAssets[indexPath.row].mediaType == .image {
                                                    cell.assetPreview.layer.cornerRadius = 2.00
                                                    cell.assetPreview.clipsToBounds = true
                                                } else {
                                                    cell.assetPreview.makeCircular(forView: cell.assetPreview, borderWidth: 0, borderColor: UIColor.clear)
                                                }
        }
    
        return cell
    }

    // MARK: - UICollectionView Delegate Method
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Instantiate NewMedia
        let newMediaVC = self.storyboard?.instantiateViewController(withIdentifier: "newMediaVC") as! NewMedia
        newMediaVC.mediaAsset = self.allAssets[indexPath.item]
        if self.allAssets[indexPath.item].mediaType == .image {
            newMediaVC.mediaType = "image"
        } else if self.allAssets[indexPath.item].mediaType == .video {
            newMediaVC.mediaType = "video"
        }
        // Push to VC
        self.navigationController?.pushViewController(newMediaVC, animated: true)
    }
}

/*
 MARK: - Library Extension; TRMosaicLayoutDelegate Methods
 */
extension Library: TRMosaicLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath: IndexPath) -> TRMosaicCellType {
        // I recommend setting every third cell as .Big to get the best layout
        return indexPath.item % 3 == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: TRMosaicLayout, insetAtSection: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func heightForSmallMosaicCell() -> CGFloat {
        return (UIScreen.main.bounds.size.width/3)
    }
}
