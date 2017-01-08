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
    
    
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var capturedMoment: UIImageView!
    

    func SwiftyCamDidTakePhoto(_ photo: UIImage) {
        // Called when takePhoto() is called or if a SwiftyCamButton initiates a tap gesture
        // Returns a UIImage captured from the current session
        
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
        self.navigationController?.present(videoViewController, animated: true, completion: nil)
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

        cameraDelegate = self
        captureButton.delegate = self
        kMaximumVideoDuration = 10.0
        
        // Enable interaction
        self.capturedMoment.isUserInteractionEnabled = true
        // Bring button to front
        self.view.bringSubview(toFront: self.captureButton)
        
        // Hide imageview
        self.capturedMoment.isHidden = true
        
        // Tap button to take photo
        let oneTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        oneTap.numberOfTapsRequired = 1
        self.captureButton.addGestureRecognizer(oneTap)
        
        // Double tap to swap camera
        let twoTap = UITapGestureRecognizer(target: self, action: #selector(switchCamera))
        twoTap.numberOfTapsRequired = 2
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(twoTap)
        
        // Hold button to take record video
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(startVideoRecording))
        longPress.minimumPressDuration = 10.00
        self.captureButton.addGestureRecognizer(longPress)
        
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
