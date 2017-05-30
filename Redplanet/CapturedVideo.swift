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
import VIMVideoPlayer

class CapturedVideo: UIViewController, SwipeNavigationControllerDelegate {
//, SwipeViewDelegate, SwipeViewDataSource {
    
    // MARK: - Class Configuration Variables
    var capturedURL: URL?
    
    // MARK: - VIMVideoPlayer
    var vimPlayerView: VIMVideoPlayerView!
    // MARK: - SubtleVolume
    var subtleVolume: SubtleVolume!
    
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveVideo(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.capturedURL!)
        }) { (saved: Bool, error: Error?) in
            if saved {
                DispatchQueue.main.async(execute: {
                    UIView.animate(withDuration: 0.5) { () -> Void in
                        self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    }
                    UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                        self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 2))
                    }, completion: nil)
                })
            } else {
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showProgress(withTitle: "Saving video...")
            }
        }
    }
    
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func share(_ sender: Any) {
        // MARK: - HEAP
        Heap.track("SharedMoment", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"])
        // Disable button
        self.continueButton.isUserInteractionEnabled = false
        // POST
        if chatCamera == false {
            postVideo()
        } else {
        // CHATS
            sendVideoChat()
        }
    }
    
    
    // FUNCTION - Post video
    func postVideo() {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        // Create temporary URL path to store video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // Compress video
        compressVideo(inputURL: self.capturedURL!, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                rpHelpers.showError(withTitle: "An unknown error occurred...")
            case .waiting:
                rpHelpers.showProgress(withTitle: "Compressing video...")
            case .exporting:
                rpHelpers.showProgress(withTitle: "Exporting video...")
            case .completed:
                do {
                    // Traverse file URL to Data()
                    let videoData = try Data(contentsOf: compressedURL)
                    
                    // Create PFObject
                    let video = PFObject(className: "Posts")
                    video["byUser"] = PFUser.current()!
                    video["byUsername"] = PFUser.current()!.username!
                    video["videoAsset"] = PFFile(name: "video.mp4", data: videoData)
                    video["contentType"] = "itm"
                    video["saved"] = false
                    // Re-enable button
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Execute in main thread to minimize wait time...
                    DispatchQueue.main.async(execute: {
                        // Pause VIMPlayerView's AVPlayer
                        self.vimPlayerView.player?.pause()
                        // Append PFObject
                        shareWithObject.append(video)
                        let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                        self.navigationController?.pushViewController(shareWithVC, animated: true)
                    })
                    
                } catch let error {
                    print(error.localizedDescription as Any)
                    rpHelpers.showError(withTitle: "Failed to compress video...")
                }
            case .failed:
                rpHelpers.showError(withTitle: "Failed to compress video...")
            case .cancelled:
                rpHelpers.showError(withTitle: "Cancelled video compression...")
            }
        }
    }
    
    
    // FUNCTION - Send video chat...
    func sendVideoChat() {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        // Create temporary URL path to store video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // Compress video
        compressVideo(inputURL: self.capturedURL!, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                rpHelpers.showError(withTitle: "An unknown error occurred...")
            case .waiting:
                rpHelpers.showProgress(withTitle: "Compressing video...")
            case .exporting:
                rpHelpers.showProgress(withTitle: "Exporting video...")
            case .completed:
                do {
                    // Traverse file URL to Data()
                    let videoData = try Data(contentsOf: compressedURL)
                    
                    // Create PFObject, and save
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = chatUserObject.last!
                    chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
                    chats["read"] = false
                    chats["saved"] = false
                    chats["videoAsset"] = PFFile(name: "video.mp4", data: videoData)
                    chats["contentType"] = "itm"
                    chats.saveInBackground()
                    // Re-enable button
                    self.continueButton.isUserInteractionEnabled = true

                    // Execute in main thread to minimize wait time...
                    DispatchQueue.main.async(execute: {
                        // Pause VIMPlayerView's AVPlayer
                        self.vimPlayerView.removeFromSuperview()
                        /*
                         MARK: - RPHelpers
                         Helper to update <ChatsQueue>
                         Helper to send push notification
                        */
                        let rpHelpers = RPHelpers()
                        rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                        rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                        // Re-enable buttons
                        self.continueButton.isUserInteractionEnabled = true
                        // Set bool to false
                        chatCamera = false
                        // Reload data
                        NotificationCenter.default.post(name: rpChat, object: nil)
                        // MARK: - SwipeNavigationController
                        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
                    })
                } catch let error {
                    print(error.localizedDescription as Any)
                    rpHelpers.showError(withTitle: "Failed to compress video...")
                }
            case .failed:
                rpHelpers.showError(withTitle: "Failed to compress video...")
            case .cancelled:
                rpHelpers.showError(withTitle: "Cancelled video compression...")
            }
        }
    }
    
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        // Pop View Controller
        if position == .bottom {
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        // Delegate
    }
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        // Hide UINavigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SubtleVolume
        subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 3)
        subtleVolume.animation = .fadeIn
        subtleVolume.barTintColor = UIColor.black
        subtleVolume.barBackgroundColor = UIColor.white
        self.view.addSubview(subtleVolume)
        
        // Execute code if url array is NOT empty
        if self.capturedURL != nil {
            
            // MARK: - VIMVideoPlayer
            vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
            vimPlayerView.player.isLooping = true
            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimPlayerView.player.setURL(self.capturedURL!)
            vimPlayerView.player.play()
            self.view.addSubview(vimPlayerView)
        
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.delegate = self
            self.containerSwipeNavigationController?.shouldShowRightViewController = false
            self.containerSwipeNavigationController?.shouldShowLeftViewController = false
            self.containerSwipeNavigationController?.shouldShowCenterViewController = false
            self.containerSwipeNavigationController?.shouldShowBottomViewController = false

            // UITapGestureRecognizer method to toggle volume
            let muteTap = UITapGestureRecognizer(target: self, action: #selector(configureVolume))
            muteTap.numberOfTapsRequired = 1
            self.muteButton.isUserInteractionEnabled = true
            self.muteButton.addGestureRecognizer(muteTap)
            
            // UILongPressGestureRecognizer method to play and pause
            let playPausePress = UILongPressGestureRecognizer(target: self, action: #selector(togglePlayPause))
            playPausePress.minimumPressDuration = 0.15
            vimPlayerView.isUserInteractionEnabled = true
            vimPlayerView.addGestureRecognizer(playPausePress)
            
            // Add shadows to buttons and bring to front of view
            let buttons = [self.muteButton,
                           self.exitButton,
                           self.saveButton,
                           self.continueButton] as [Any]
            for b in buttons {
                // MARK: - RPExtension
                (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer)
                self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            }
            // Bring subtleVolume to front
            self.view.bringSubview(toFront: subtleVolume)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }
}



// MARK: - CapturedVideo Extensions; used to manage video asset
extension CapturedVideo {
    // FUNCTION - Toggle volume on/off
    func configureVolume() {
        switch self.vimPlayerView.player.isMuted {
        case true:
            // VOLUME OFF
            DispatchQueue.main.async(execute: {
                self.vimPlayerView.player.isMuted = false
                self.muteButton.setImage(UIImage(named: "VolumeOn"), for: .normal)
            })
        case false:
            // VOLUME ON
            DispatchQueue.main.async(execute: {
                self.vimPlayerView.player.isMuted = true
                self.muteButton.setImage(UIImage(named: "VolumeOff"), for: .normal)
            })
        }
    }
    
    // FUNCTION - Play and pause video
    func togglePlayPause() {
        if self.vimPlayerView.player.isPlaying {
            self.vimPlayerView.player.pause()
        } else {
            self.vimPlayerView.player.play()
        }
    }
    
    // FUNCTION - Compress video file (open to process video before view loads...)
    func compressVideo(inputURL: URL, outputURL: URL, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        DispatchQueue.main.async {
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
    }
}
