//
//  Library.swift
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

import SwipeNavigationController

class Library: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, CAPSPageMenuDelegate {
    
    
    // Initilialize pageMenu
    var pageMenu : CAPSPageMenu?
    
    // Initialize image picker
    var imagePicker: UIImagePickerController!
    
    @IBAction func backButton(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func chooseVia(_ sender: Any) {
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
            print("Photo selected")
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
            print("Video selected")
            
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
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
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
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize title
        configureView()
        
        // Array to keep track of controllers in page menu
        var controllerArray : [UIViewController] = []
        
        // Create variables for all view controllers you want to put in the
        // page menu, initialize them, and add each to the controller array.
        // (Can be any UIViewController subclass)
        // Make sure the title property of all view controllers is set
        let photosVC = self.storyboard!.instantiateViewController(withIdentifier: "libPhotosVC") as! LibPhotos
        photosVC.roofedNavigator = self.navigationController
        photosVC.title = "Photos"
        controllerArray.append(photosVC)
        
        let videosVC = self.storyboard?.instantiateViewController(withIdentifier: "libVideosVC") as! LibVideos
        videosVC.roofedNavigator = self.navigationController
        videosVC.title = "Videos"
        controllerArray.append(videosVC)
        
        // Customize page menu to your liking (optional) or use default settings by sending nil for 'options' in the init
        // Example:
        let parameters: [CAPSPageMenuOption] = [
            .menuItemSeparatorWidth(0.0),
            .useMenuLikeSegmentedControl(true),
            .menuHeight(self.navigationController!.navigationBar.frame.size.height),
            .selectionIndicatorColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)),
            .scrollMenuBackgroundColor(UIColor.white),
            .selectedMenuItemLabelColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)),
            .menuItemFont(UIFont(name: "AvenirNext-Medium", size: 17.00)!),
            .unselectedMenuItemLabelColor(UIColor.black)
        ]
        
        // Initialize page menu with controller array, frame, and optional parameters
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRect(x: 0.0, y: 0.00, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
        
        // Lastly add page menu as subview of base view controller view
        // or use pageMenu controller in you view hierachy as desired
        self.view.addSubview(pageMenu!.view)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
