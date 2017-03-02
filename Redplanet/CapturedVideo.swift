//
//  CapturedVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
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
import SCRecorder

// Video URL
var capturedURLS = [URL]()

class CapturedVideo: UIViewController, SwipeNavigationControllerDelegate, SCRecorderDelegate, SwipeViewDelegate, SwipeViewDataSource {
    
    // MARK: - SCRecorder
    var player: SCPlayer!
    
    // MARK: - SwipeView
    @IBOutlet weak var swipeView: SwipeView!
    
    // Compressed URL
    var smallVideoData: NSData?
    
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
        if !capturedURLS.isEmpty {
            capturedURLS.removeLast()
        }
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveVideo(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: capturedURLS.last!)
        }) { (saved: Bool, error: Error?) in
            if saved {
                
                UIView.animate(withDuration: 0.5) { () -> Void in
                    
                    self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
                }
                
                UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                    
                    self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
                }, completion: nil)
                
            } else {
                
            }
        }
    }
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func share(_ sender: Any) {
        
        // Disable button
        self.continueButton.isUserInteractionEnabled = false
        
    

//        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
//        let outputPath = "\(documentsPath).mp4"
//        let outputURL = URL(fileURLWithPath: outputPath)
//        
//        let asset = AVAsset(url: capturedURLS.last!)
//        let exportSession = SCAssetExportSession()
//        exportSession.inputAsset = asset
//        exportSession.outputUrl = outputURL
//        exportSession.outputFileType = AVFileTypeMPEG4
//        exportSession.videoConfiguration.filter = SCFilter(ciFilterName: "CIPhotoEffectMono")
//        exportSession.videoConfiguration.preset = SCPresetHighestQuality
//        exportSession.shouldOptimizeForNetworkUse = true
//        exportSession.exportAsynchronously { 
//            if exportSession.error == nil {
//                do {
//                    let fileData = try Data(contentsOf: outputURL)
//                    print("EXPORTED??\(outputURL)\n\(fileData)\n\n\n")
//                    
//                } catch {
//                    
//                }
//                
//            } else {
//                print(exportSession.error?.localizedDescription as Any)
//            }
//        }
        
        if chatCamera == false {
            // Save to Newsfeeds
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["videoAsset"] = PFFile(name: "video.mp4", data: smallVideoData as! Data)
            newsfeeds["contentType"] = "itm"
            newsfeeds["saved"] = false
            newsfeeds.saveInBackground()
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Clear array
            capturedURLS.removeAll(keepingCapacity: false)
            // Reload data and push to bottom
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            }
            
        } else {
            // Send Chats
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chats["read"] = false
            chats["videoAsset"] = PFFile(name: "video.mp4", data: smallVideoData as! Data)
            chats.saveInBackground()
            
            // MARK: - HEAP
            Heap.track("SharedMoment", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Send Push Notification to user
            // Handle optional chaining
            if chatUserObject.last!.value(forKey: "apnsId") != nil {
                // Handle optional chaining
                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                    // MARK: - OneSignal
                    // Send push notification
                    OneSignal.postNotification(
                        ["contents":
                            ["en": "from \(PFUser.current()!.username!.uppercased())"],
                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                         "ios_badgeType": "Increase",
                         "ios_badgeCount": 1
                        ]
                    )
                }
            }
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Set bool to false
            chatCamera = false
            // Reload chats
            NotificationCenter.default.post(name: rpChat, object: nil)
            // Pop 2 view controllers
            let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
            self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
        }
    }
    
    // Function to mute and turn volume on
    func setMute() {
        // MUTE
        if self.player.isMuted == false && self.muteButton.image(for: .normal) == UIImage(named: "VolumeOn") {
            self.player.isMuted = true
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "Mute"), for: .normal)
            }
        } else if self.player.isMuted == true && self.muteButton.image(for: .normal) == UIImage(named: "Mute") {
            // VOLUME ON
            self.player.isMuted = false
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "VolumeOn"), for: .normal)
            }
        }
    }

    // Compress video
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        if position == .bottom {
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        //
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide statusBar
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        
        // MARK: - SwipeView
        self.swipeView.delegate = self
        self.swipeView.dataSource = self
        self.swipeView.isPagingEnabled = true
        self.swipeView.isUserInteractionEnabled = true
        print("Number of pages: \(self.swipeView.numberOfPages)")
        
        // Set Audio
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                            with: [.duckOthers, .defaultToSpeaker])
        } catch {
            print("[SwiftyCam]: Failed to set background audio preference")
        }
        
        
        // Execute if array isn't empty
        if !capturedURLS.isEmpty {
            DispatchQueue.main.async {
                let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
                self.compressVideo(inputURL: capturedURLS.last!, outputURL: compressedURL) { (exportSession) in
                    guard let session = exportSession else {
                        return
                    }
                    switch session.status {
                    case .unknown:
                        break
                    case .waiting:
                        break
                    case .exporting:
                        break
                    case .completed:
                        // Enable buttons
                        self.continueButton.isUserInteractionEnabled = true
                        guard let compressedData = NSData(contentsOf: compressedURL) else {
                            return
                        }
                        self.smallVideoData = compressedData
                    case .failed:
                        break
                    case .cancelled:
                        break
                    }
                }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Execute code if url array is NOT empty
        if !capturedURLS.isEmpty {
            
            // MARK: - SCRecorder
            self.player = SCPlayer()
            self.player.setItemBy(capturedURLS.last!)
            self.player.loopEnabled = true
            self.player.play()
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.bounds
            self.view.layer.addSublayer(playerLayer)
            self.view.addSubview(self.swipeView)
//            let filterView = SCFilterImageView(frame: self.view.bounds)
//            filterView.filter = SCFilter(ciFilterName: "CIPhotoEffectMono")
//            self.player.scImageView = filterView
//            self.view.addSubview(filterView)
            
            
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.shouldShowRightViewController = false
            self.containerSwipeNavigationController?.shouldShowLeftViewController = false
            self.containerSwipeNavigationController?.shouldShowBottomViewController = false
            self.containerSwipeNavigationController?.delegate = self

            // Mute and Volume-On
            let muteTap = UITapGestureRecognizer(target: self, action: #selector(setMute))
            muteTap.numberOfTapsRequired = 1
            self.muteButton.isUserInteractionEnabled = true
            self.muteButton.addGestureRecognizer(muteTap)
            
            // Add shadows to buttons and bring to front of view
            let buttons = [self.muteButton,
                           self.exitButton,
                           self.saveButton,
                           self.continueButton] as [Any]
            for b in buttons {
                (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
                (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
                (b as AnyObject).layer.shadowRadius = 3
                (b as AnyObject).layer.shadowOpacity = 0.5
                self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                self.swipeView.bringSubview(toFront: (b as AnyObject) as! UIView)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }
    
    

    
    // MARK: - SwipeView DataSource
    
    func numberOfItems(in swipeView: SwipeView!) -> Int {
        return 4
    }
    
    func swipeView(_ swipeView: SwipeView!, viewForItemAt index: Int, reusing view: UIView!) -> UIView! {
        
        
        if index == 0 {
            
        } else if index == 1 {
            view.backgroundColor = UIColor(patternImage: UIImage(named: "Cotton")!)
        } else if index == 2 {
            view.backgroundColor = UIColor(patternImage: UIImage(named: "HardLight")!)
        } else if index == 3 {
            //            let filterView = SCFilterImageView(frame: self.view.bounds)
            //            filterView.filter = SCFilter(ciFilterName: "CIPhotoEffectInstant")
            //            self.player.scImageView = filterView
            //            view.addSubview(filterView)
        } else {
            //            let filterView = SCFilterImageView(frame: self.view.bounds)
            //            filterView.filter = SCFilter(ciFilterName: "CIPhotoEffectMono")
            //            self.player.scImageView = filterView
            //            view.addSubview(filterView)
        }
        
        return view
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView!) -> CGSize {
        return self.view.bounds.size
    }

    func swipeViewDidScroll(_ swipeView: SwipeView!) {
        print("SCROLLED")
    }
    
    
}
