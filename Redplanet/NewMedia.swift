//
//  NewMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import Photos

import Parse
import ParseUI
import Bolts

import OneSignal
import SwipeNavigationController

class NewMedia: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Class Variables
    var mediaType = String()
    var mediaAsset: PHAsset?
    // data passed via UIImagePickerController
    var mediaURL: URL?
    var selectedImage: UIImage?
    
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var textPost: UITextView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editAction(_ sender: Any) {
    }
    @IBAction func back(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func moreAction(_ sender: Any) {
    }
    
    
    // FUNCTION - Play Video
    func playVideo() {
        
    }
    
    // FUNCTION - Zoom into Photo
    func zoomPhoto() {
        
    }
    
    // FUNCTION - Stylize UINavigationBar
    func configureView() {
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: navBarFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            if mediaType == "image" {
                self.title = "New Photo"
                self.textPost.text! = "Say something about this photo..."
                // MARK: - RPExtensions
                self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
            } else {
                self.title = "New Video"
                self.textPost.text! = "Say something about this video..."
                // MARK: - RPExtensions
                self.mediaPreview.makeCircular(forView: self.mediaPreview, borderWidth: 0.5, borderColor: UIColor.white)
            }
        }
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - UIView Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureView()
        // NOT via UIImagePickerController
        if self.mediaAsset != nil {
            // Set PHImageRequestOptions
            let imageOptions = PHImageRequestOptions()
            imageOptions.deliveryMode = .highQualityFormat
            imageOptions.resizeMode = .exact
            imageOptions.isSynchronous = true
            let targetSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
            // Fetch PHImageManager
            PHImageManager.default().requestImage(for: self.mediaAsset!,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: nil) {
                                                    (img, _) -> Void in
                                                    self.mediaPreview.image = img
            }
        } else {
        // Via UIImagePickerController
            // PHOTO
            if selectedImage != nil {
                self.mediaPreview.image = selectedImage
            } else {
            // VIDEO
                let player = AVPlayer(url: self.mediaURL!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.mediaPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.mediaPreview.contentMode = .scaleAspectFit
                self.mediaPreview.layer.addSublayer(playerLayer)
            }
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }
    



}
