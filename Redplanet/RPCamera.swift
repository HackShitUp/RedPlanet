//
//  RPCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import SwiftyCam

// Bool to determine whether camera was accessed from Chats
var chatCamera: Bool = false

class RPCamera: SwiftyCamViewController, SwiftyCamViewControllerDelegate, UINavigationControllerDelegate {
    
    // Bool to determine media type
    var camMedia = "photo"
    
    var count = 10

    
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    

    func SwiftyCamDidTakePhoto(_ photo: UIImage) {
        // Append photo
        stillImage.append(photo)
        // Perform segue
        let stillVC = self.storyboard?.instantiateViewController(withIdentifier: "stillVC") as! CapturedStill
        self.navigationController?.pushViewController(stillVC, animated: false)
    }
    
    func SwiftyCamDidBeginRecordingVideo() {
        print("Did Begin Recording")
        // Show progress and begin counting
        DispatchQueue.main.async {
            self.view.bringSubview(toFront: self.progressView)
        }
        // Call function
        countDown()
    }
    
    func SwiftyCamDidFinishRecordingVideo() {
        print("Did finish Recording")
    }
    
    func SwiftyCamDidFinishProcessingVideoAt(_ url: URL) {
        print(url.path)
        
        // MARK: - Periscope Video View Controller
//        let videoViewController = VideoViewController(videoURL: url)
//        self.navigationController?.present(videoViewController, animated: false, completion: nil)
        capturedURL.append(url)
        // Push VC
        let capturedVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "capturedVideoVC") as! CapturedVideo
        self.navigationController?.pushViewController(capturedVideoVC, animated: true)
        
    }
    
    func SwiftyCamDidFocusAtPoint(focusPoint: CGPoint) {
        print(focusPoint)
    }
    
    func SwiftyCamDidChangeZoomLevel(zoomLevel: CGFloat) {
        print(zoomLevel)
    }
    
    func SwiftyCamDidSwitchCameras(camera: SwiftyCamViewController.CameraSelection) {
        // Rotate icon
        UIView.animate(withDuration: 0.5) { () -> Void in
            
            self.swapCameraButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            
            self.swapCameraButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
        }, completion: nil)
    }
    
    
    
    // leave vc
    func dismissVC() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to toggle flash
    func toggleFlash(sender: Any) {
        flashEnabled = !flashEnabled
        
        if flashEnabled == true {
            flashButton.setImage(UIImage(named: "Thunder"), for: .normal)
        } else {
            flashButton.setImage(UIImage(named: "Lightning Bolt-96"), for: .normal)
        }
    }
    
    // Function to countdown for video
    func countDown() {
        if (count > 0) {
            DispatchQueue.main.async {
                self.count = 0
                self.progressView.progress = Float(self.count/10)
//                self.progressView.setProgress(Float(self.count/10), animated: true)
//                print(self.count)
                
//                self.progressView.progress = Float(Int(self.count/15))
//                self.count -= 1
            }

        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set delegate for camera view
        cameraDelegate = self
        // Set delegate for camera button
        captureButton.delegate = self
        // Set video duration and length
        kMaximumVideoDuration = 10.0
        
        // Bring buttons to front
        self.view.bringSubview(toFront: self.captureButton)
        self.view.bringSubview(toFront: self.flashButton)
        self.view.bringSubview(toFront: self.swapCameraButton)
        self.view.bringSubview(toFront: self.leaveButton)
        
        var _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countDown), userInfo: nil, repeats: false)
        
        // Tap button to take photo
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        captureTap.numberOfTapsRequired = 1
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(captureTap)
        
        // Hold button to take record video
        let holdRecord = UILongPressGestureRecognizer(target: self, action: #selector(startVideoRecording))
        holdRecord.minimumPressDuration = 10.00
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(holdRecord)
        
        // Swap between cameras
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(switchCamera))
        doubleTap.numberOfTapsRequired = 2
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(doubleTap)
        
        // Tap button to swap between cameras
        let swapTap = UITapGestureRecognizer(target: self, action: #selector(switchCamera))
        swapTap.numberOfTapsRequired = 1
        self.swapCameraButton.isUserInteractionEnabled = true
        self.swapCameraButton.addGestureRecognizer(swapTap)
        
        // Tap for flash configuration
        let flashTap = UITapGestureRecognizer(target: self, action: #selector(toggleFlash))
        flashTap.numberOfTapsRequired = 1
        self.flashButton.isUserInteractionEnabled = true
        self.flashButton.addGestureRecognizer(flashTap)
        
        // Tap to leave
        let leaveTap = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        leaveTap.numberOfTapsRequired = 1
        self.leaveButton.isUserInteractionEnabled = true
        self.leaveButton.addGestureRecognizer(leaveTap)
    
        // Swipe left to leave
        let leaveSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissVC))
        leaveSwipe.direction = .right
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(leaveSwipe)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
