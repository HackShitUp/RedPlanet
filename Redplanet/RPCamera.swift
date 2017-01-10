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
    var time: Float = 0.0
    var timer: Timer?
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
        // Show progress and begin counting
        DispatchQueue.main.async {
            self.progressView.isHidden = false
            self.view.bringSubview(toFront: self.progressView)
//            self.timer = Timer.scheduledTimer(timeInterval: 0.50, target: self, selector: #selector(self.countDown), userInfo: nil, repeats: false)
//            UIView.animate(withDuration: 10, animations: { () -> Void in
//                self.progressView.setProgress(1, animated: true)
//            })
        }
    }
    
//    func countDown() {
//        DispatchQueue.main.async {
//            self.time += 1.0
//            self.progressView.setProgress(0, animated: false)
//            self.progressView.setProgress(10/self.time, animated: true)
//            if self.time > 10 {
//                self.timer!.invalidate()
//            }
//        }
//    }
    
    
    func SwiftyCamDidFinishRecordingVideo() {
        // Remove progress
        self.progressView.isHidden = true
    }
    
    func SwiftyCamDidFinishProcessingVideoAt(_ url: URL) {
        // Append url
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
