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

// Video URL
var capturedURLS = [URL]()

class CapturedVideo: UIViewController, PlayerDelegate {
    
    // Initializae Player
    var player: Player!
    
    // Compressed URL
    var smallVideoData: NSData?
    
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
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
        
        // Check if it's for Chats
        if chatCamera == false {
            // Save to Newsfeeds
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["videoAsset"] = PFFile(name: "video.mp4", data: smallVideoData as! Data)
            newsfeeds["contentType"] = "itm"
            newsfeeds.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                    print("FIRED")
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Clear array
                    capturedURLS.removeAll(keepingCapacity: false)
                    
                    DispatchQueue.main.async {
                        // Send Notification
                        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                        
                        doShow = true
                        let libNav = self.storyboard?.instantiateViewController(withIdentifier:"left") as! UINavigationController
                        let camNav = self.storyboard?.instantiateViewController(withIdentifier:"mid") as! UINavigationController
                        let masterTab = self.storyboard?.instantiateViewController(withIdentifier: "theMasterTab") as! MasterTab
                        masterTab.tabBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                        let newTPNav = self.storyboard?.instantiateViewController(withIdentifier:"right") as! UINavigationController
                        let snapContainer = SnapContainerViewController.containerViewWith(libNav,
                                                                                          middleVC: camNav,
                                                                                          rightVC: newTPNav,
                                                                                          topVC: nil,
                                                                                          bottomVC: masterTab)
                        UIApplication.shared.keyWindow?.rootViewController = snapContainer
                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Clear array
                    capturedURLS.removeAll(keepingCapacity: false)
                    
                    DispatchQueue.main.async {
                        
                        // Send Notification
                        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                        
                        doShow = true
                        let libNav = self.storyboard?.instantiateViewController(withIdentifier:"left") as! UINavigationController
                        let camNav = self.storyboard?.instantiateViewController(withIdentifier:"mid") as! UINavigationController
                        let masterTab = self.storyboard?.instantiateViewController(withIdentifier: "theMasterTab") as! MasterTab
                        masterTab.tabBar.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                        let newTPNav = self.storyboard?.instantiateViewController(withIdentifier:"right") as! UINavigationController
                        let snapContainer = SnapContainerViewController.containerViewWith(libNav,
                                                                                          middleVC: camNav,
                                                                                          rightVC: newTPNav,
                                                                                          topVC: nil,
                                                                                          bottomVC: masterTab)
                        UIApplication.shared.keyWindow?.rootViewController = snapContainer
                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    }
                    
                }
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
            chats.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
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
                    
                    // Make false
                    chatCamera = false
                    
                    // Reload chats
                    NotificationCenter.default.post(name: rpChat, object: nil)
                    
                    // Pop 2 view controllers
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);

                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
                    // Reload chats
                    NotificationCenter.default.post(name: rpChat, object: nil)
                    
                    // Pop 2 view controllers
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
                }
            })
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
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Compress Video berfore viewDidLoad()
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        compressVideo(inputURL: capturedURLS.last!, outputURL: compressedURL) { (exportSession) in
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
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // Function to Play & Pause
    func control() {
        if self.player.playbackState == .paused {
            self.player.playFromCurrentTime()
        } else if self.player.playbackState == .playing {
            self.player.pause()
        }
    }
    
    // Function to mute and turn volume on
    func setMute() {
        if self.player.muted == false && self.muteButton.image(for: .normal) == UIImage(named: "VolumeOn") {
            // MUTE
            self.player.muted = true
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "Mute"), for: .normal)
            }
        } else if self.player.muted == true && self.muteButton.image(for: .normal) == UIImage(named: "Mute") {
            // VOLUME ON
            self.player.muted = false
            DispatchQueue.main.async {
                self.muteButton.setImage(UIImage(named: "VolumeOn"), for: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Player
        self.player = Player()
        self.player.delegate = self
        self.player.view.frame = self.view.bounds
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParentViewController: self)
        self.player.setUrl(capturedURLS.last!)
        self.player.fillMode = "AVLayerVideoGravityResizeAspect"
        self.player.playFromBeginning()
        self.player.playbackLoops = true
        
        // Add tap methods for..
        // Pause and Play
        let controlTap = UITapGestureRecognizer(target: self, action: #selector(control))
        controlTap.numberOfTapsRequired = 1
        self.player.view.isUserInteractionEnabled = true
        self.player.view.addGestureRecognizer(controlTap)
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
        }
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
