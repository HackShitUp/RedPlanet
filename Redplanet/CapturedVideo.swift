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
    
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func share(_ sender: Any) {
        
        // Disable button
        self.continueButton.isUserInteractionEnabled = false
        
        print("CAPTURED URL: \(capturedURLS.last!)")
        
        // Traverse url to Data
        let tempImage = capturedURLS.last! as NSURL?
        _ = tempImage?.relativePath
        let videoData = NSData(contentsOfFile: (tempImage?.relativePath!)!)

        print("File size before compression: \(Double(videoData!.length/1048576)) mb")
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
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
                
                 // Save to Newsfeeds
                 let newsfeeds = PFObject(className: "Newsfeeds")
                 newsfeeds["username"] = PFUser.current()!.username!
                 newsfeeds["byUser"] = PFUser.current()!
                 newsfeeds["videoAsset"] = PFFile(name: "video.mp4", data: compressedData as Data)
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
                
                
            case .failed:
                break
            case .cancelled:
                break
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
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bring buttons to front
        self.view.bringSubview(toFront: self.exitButton)
        self.view.bringSubview(toFront: self.continueButton)

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
        
        // Add tap method
//        let controlTap = UITapGestureRecognizer(target: self, action: #selector(self.player.playFromCurrentTime))
//        controlTap.numberOfTapsRequired = 1
//        self.view.isUserInteractionEnabled = true
//        self.view.addGestureRecognizer(controlTap)
        
        // Bring buttons to front
        self.view.bringSubview(toFront: self.exitButton)
        self.view.bringSubview(toFront: self.continueButton)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
