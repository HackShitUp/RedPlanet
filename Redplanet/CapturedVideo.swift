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

// Video URL
var capturedURLS = [URL]()

class CapturedVideo: UIViewController, SwipeNavigationControllerDelegate, SwipeViewDelegate, SwipeViewDataSource {
    
    // MARK: - RPVideoPlayer
    var rpVideoPlayer: RPVideoPlayerView!
    
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
//            print("VIDEODATA: \(smallVideoData)\n")
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
            // Clear array
            capturedURLS.removeAll(keepingCapacity: false)
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
            // Clear array
            capturedURLS.removeAll(keepingCapacity: false)
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
        // MUTE
        if self.rpVideoPlayer.muted == false && self.muteButton.image(for: .normal) == UIImage(named: "VolumeOn") {
            self.rpVideoPlayer.muted = true
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "VolumeOff"), for: .normal)
            }
        } else if self.rpVideoPlayer.muted == true && self.muteButton.image(for: .normal) == UIImage(named: "VolumeOff") {
        // VOLUME ON
            self.rpVideoPlayer.muted = false
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
    

    // MARK: - SwipeView DataSource
    func numberOfItems(in swipeView: SwipeView) -> Int {
        //return the total number of items in the carousel
        return 4
    }
    
    func swipeView(_ swipeView: SwipeView, viewForItemAt index: Int, reusing view: UIView) -> UIView? {
        /*
        if index == 0 {
            view.alpha = 1.0
            view.backgroundColor = UIColor.clear
        } else if index == 1 {
            // Configure time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let time = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            time.font = UIFont(name: "AvenirNextCondensed-Demibold", size: 70)
            time.textColor = UIColor.white
            time.layer.shadowColor = UIColor.black.cgColor
            time.layer.shadowOffset = CGSize(width: 1, height: 1)
            time.layer.shadowRadius = 3
            time.layer.shadowOpacity = 0.5
            time.text = "\(timeFormatter.string(from: NSDate() as Date))"
            time.textAlignment = .center
            UIGraphicsBeginImageContextWithOptions(self.view.frame.size, false, 0.0)
            time.layer.render(in: UIGraphicsGetCurrentContext()!)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            view.alpha = 1.0
            view.backgroundColor = UIColor(patternImage: img!)
        } else if index == 2 {
            view.alpha = 0.1
            view.backgroundColor = UIColor.red
        } else if index == 3 {
            view.alpha = 0.1
            view.backgroundColor = UIColor.yellow
        }
        */
        return view
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView) -> CGSize {
        return self.swipeView.bounds.size
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide statusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Set Audio
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord,
                                                            with: [.duckOthers, .mixWithOthers])
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
            
            // MARK: - RPVideoPlayerView
            rpVideoPlayer = RPVideoPlayerView(frame: self.view.bounds)
            rpVideoPlayer.setupVideo(videoURL: capturedURLS.last!)
            rpVideoPlayer.playbackLoops = true
            self.view.addSubview(rpVideoPlayer)
            
            // MARK: - SwipeView
            self.swipeView.delegate = self
            self.swipeView.dataSource = self
            self.swipeView.alignment = .center
            self.swipeView.itemsPerPage = 1
            self.swipeView.isPagingEnabled = true
            self.swipeView.truncateFinalPage = false
            self.view.addSubview(self.swipeView)
        
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.shouldShowRightViewController = false
            self.containerSwipeNavigationController?.shouldShowLeftViewController = false
            self.containerSwipeNavigationController?.shouldShowBottomViewController = false
            self.containerSwipeNavigationController?.shouldShowTopViewController = false
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
                // MARK: - RPExtension
                (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer)
                self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
                self.swipeView.bringSubview(toFront: (b as AnyObject) as! UIView)
                self.swipeView.bringSubview(toFront: rpVideoPlayer)
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
