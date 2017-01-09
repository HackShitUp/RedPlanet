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
    
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    

    func SwiftyCamDidTakePhoto(_ photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
        print(photo)
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
