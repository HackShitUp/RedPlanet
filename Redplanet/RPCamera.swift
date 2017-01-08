//
//  RPCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import SwiftyCam

class RPCamera: SwiftyCamViewController, SwiftyCamViewControllerDelegate, UINavigationControllerDelegate {
    
    // Bool to determine media type
    var camMedia = "photo"
    
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var capturedMoment: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    

    func SwiftyCamDidTakePhoto(_ photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
        
        self.view.bringSubview(toFront: self.downloadButton)
        self.view.bringSubview(toFront: self.retakeButton)
        
        self.capturedMoment.isHidden = false
        self.view.bringSubview(toFront: self.capturedMoment)
        self.capturedMoment.image = photo
    }
    
    func SwiftyCamDidBeginRecordingVideo() {
        print("Did Begin Recording")
    }
    
    func SwiftyCamDidFinishRecordingVideo() {
        print("Did finish Recording")
    }
    
    func SwiftyCamDidFinishProcessingVideoAt(_ url: URL) {
        print(url.path)
        
        // MARK: - Periscope Video View Controller
        let videoViewController = VideoViewController(videoURL: url)
        self.navigationController?.present(videoViewController, animated: false, completion: nil)
    }
    
    func SwiftyCamDidFocusAtPoint(focusPoint: CGPoint) {
        print(focusPoint)
    }
    
    func SwiftyCamDidChangeZoomLevel(zoomLevel: CGFloat) {
        print(zoomLevel)
    }
    
    func SwiftyCamDidSwitchCameras(camera: SwiftyCamViewController.CameraSelection) {
        print(camera)
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
    
    // Function to save media
    func saveMedia(sender: Any) {
        if camMedia == "photo" {
            UIView.animate(withDuration: 0.5) { () -> Void in
                
                self.downloadButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                
                self.downloadButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
            
            UIImageWriteToSavedPhotosAlbum(self.capturedMoment.image!, self, nil, nil)
        } else {
            // Save video later
        }
    }
    
    // Function to retake
    func retake(sender: Any) {
        
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
        self.view.bringSubview(toFront: self.downloadButton)
        self.view.bringSubview(toFront: self.retakeButton)
        
        // Hide imageview
        self.capturedMoment.isHidden = true
        
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
        swapTap.numberOfTapsRequired = 2
        self.swapCameraButton.isUserInteractionEnabled = true
        self.swapCameraButton.addGestureRecognizer(swapTap)
        
        // Tap for flash configuration
        let flashTap = UITapGestureRecognizer(target: self, action: #selector(toggleFlash))
        flashTap.numberOfTapsRequired = 1
        self.flashButton.isUserInteractionEnabled = true
        self.flashButton.addGestureRecognizer(flashTap)
        
        // Tap to save photo
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(saveMedia))
        saveTap.numberOfTapsRequired = 1
        self.downloadButton.isUserInteractionEnabled = true
        self.downloadButton.addGestureRecognizer(saveTap)
        
        // Retake button
        let retakeTap = UITapGestureRecognizer(target: self, action: #selector(retake))
        retakeTap.numberOfTapsRequired = 1
        self.retakeButton.isUserInteractionEnabled = true
        self.retakeButton.addGestureRecognizer(retakeTap)
    
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
