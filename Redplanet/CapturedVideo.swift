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

class CapturedVideo: UIViewController {
//, SwipeViewDelegate, SwipeViewDataSource {
    
    // MARK: - Class Configuration Variables
    var capturedURL: URL?
    
    // MARK: - VIMVideoPlayer
    var vimPlayerView: VIMVideoPlayerView!
    
    // Compressed URL
    var smallVideoData: NSData?
    
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
        // Dismiss VC
        self.dismiss(animated: false) {
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        }
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveVideo(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.capturedURL!)
        }) { (saved: Bool, error: Error?) in
            if saved {
                
                UIView.animate(withDuration: 0.5) { () -> Void in
                    self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
                }
                
                UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                    self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
                }, completion: nil)
                
            } else {
                
            }
        }
    }
    
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func share(_ sender: Any) {
        
        // Disable button
        self.continueButton.isUserInteractionEnabled = false

        if chatCamera == false {
            // Save to Newsfeeds
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["videoAsset"] = PFFile(name: "video.mp4", data: smallVideoData! as Data)
            newsfeeds["contentType"] = "itm"
            newsfeeds["saved"] = false
            newsfeeds.saveInBackground()
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Reload data and push to bottom
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
                self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            }

        } else {
            
            // MARK: - HEAP
            Heap.track("SharedMoment", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"])
            
            // Send Chats
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chats["read"] = false
            chats["saved"] = false
            chats["videoAsset"] = PFFile(name: "video.mp4", data: smallVideoData! as Data)
            chats["contentType"] = "itm"
            chats.saveInBackground()
            
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
            // Push to bottom
            DispatchQueue.main.async {
                self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            }
        }
    }
    
    // Function to mute and turn volume on
    func setMute() {
        if self.vimPlayerView.player.isMuted == false && self.muteButton.image(for: .normal) == UIImage(named: "VolumenOn") {
        // VOLUME OFF
            self.vimPlayerView.player.isMuted = true
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "VolumeOff"), for: .normal)
            }
        } else if self.vimPlayerView.player.isMuted == true && self.muteButton.image(for: .normal) == UIImage(named: "VolumeOff") {
        // VOLUME ON
            self.vimPlayerView.player.isMuted = false
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide statusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()

        // Execute if array isn't empty
        if self.capturedURL != nil {
            DispatchQueue.main.async {
                let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
                self.compressVideo(inputURL: self.capturedURL!, outputURL: compressedURL) { (exportSession) in
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
        if self.capturedURL != nil {
            
            // MARK: - VIMVideoPlayer
            vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
            vimPlayerView.player.isLooping = true
            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimPlayerView.player.setURL(self.capturedURL!)
            vimPlayerView.player.play()
            self.view.addSubview(vimPlayerView)
        
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.shouldShowRightViewController = false
            self.containerSwipeNavigationController?.shouldShowLeftViewController = false
            self.containerSwipeNavigationController?.shouldShowCenterViewController = false
            self.containerSwipeNavigationController?.shouldShowBottomViewController = false

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
                // MARK: - RPExtension
                (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer)
                self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            }
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
