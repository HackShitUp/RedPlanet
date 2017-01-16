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

import Parse
import ParseUI
import Bolts

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
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func share(_ sender: Any) {
        
        // Disable button
        self.continueButton.isUserInteractionEnabled = false
        
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
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
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
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
                }
                
            }
        }
        

    }

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

                print("CP: \(compressedData.bytes)")
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
        
        // Disable button
        self.continueButton.isUserInteractionEnabled = false

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
        
        // Bring buttons to front
        self.view.bringSubview(toFront: self.exitButton)
        self.view.bringSubview(toFront: self.continueButton)
        self.view.bringSubview(toFront: self.muteButton)
        
        // Add shadows to buttons
        let buttons = [self.muteButton,
                       self.exitButton,
                       self.continueButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
        }
        
        
        
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
