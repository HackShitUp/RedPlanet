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
// Bool to determine camera side
var isRearCam: Bool?

class RPCamera: SwiftyCamViewController, SwiftyCamViewControllerDelegate, UINavigationControllerDelegate {
    
    var time: Float = 0.0
    var timer: Timer?
    
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var newTextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        DispatchQueue.main.async {
            stillImages.append(photo)
            let stillVC = self.storyboard?.instantiateViewController(withIdentifier: "stillVC") as! CapturedStill
            self.navigationController?.pushViewController(stillVC, animated: false)
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {

        DispatchQueue.main.async {
            self.libraryButton.isHidden = true
            self.homeButton.isHidden = true
            self.newTextButton.isHidden = true
            self.progressView.setProgress(0, animated: false)
            self.progressView.isHidden = false
            self.view.bringSubview(toFront: self.progressView)
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.countDown), userInfo: nil, repeats: false)
        }
    }
    
    func countDown() {
        // Edit
        DispatchQueue.main.async {
            self.time += 1
            self.progressView.setProgress(10/self.time, animated: true)
            if self.time >= 10 {
                self.timer!.invalidate()
            }
        }
    }
    
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        self.libraryButton.isHidden = false
        self.homeButton.isHidden = false
        self.newTextButton.isHidden = false
        self.progressView.isHidden = true
        timer?.invalidate()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // Append url
        capturedURLS.append(url)
        // Push VC
        let capturedVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "capturedVideoVC") as! CapturedVideo
        self.navigationController?.pushViewController(capturedVideoVC, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
//        print(focusPoint)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
//        print(zoomLevel)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        if camera == .rear {
            isRearCam = true
        } else if camera == .front {
            isRearCam = false
        }
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
    
    // Leave VC
    func dismissVC() {
        if chatCamera == true && doShow == false {
            _ = self.navigationController?.popViewController(animated: false)
        } else if chatCamera == false && doShow == false {
            doShow = false
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
    
    // Push to Library
    func showLibrary() {
        // Push to library
        let library = self.storyboard?.instantiateViewController(withIdentifier: "photoLibraryVC") as! Library
        self.navigationController!.pushViewController(library, animated: true)
    }
    
    // Push to New Text Post
    func newTP() {
        // Load New TextPost
        let newTP = self.storyboard?.instantiateViewController(withIdentifier: "newTextPost") as! NewTextPost
        self.navigationController?.pushViewController(newTP, animated: true)
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.view.backgroundColor = UIColor.black
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable View and buttons
        self.view.isUserInteractionEnabled = false
        self.libraryButton.isEnabled = false
        self.homeButton.isEnabled = false
        self.newTextButton.isEnabled = false
        
        // MARK: - SwiftyCam
        // Set delegate for camera view
        cameraDelegate = self
        // Set delegate to record video
        captureButton.delegate = self
        // Set video duration and length
        maximumVideoDuration = 10.00
        // Set tap to focus
        tapToFocus = true
        // Double tap to switch camera
        doubleTapCameraSwitch = true
        // Allow background music
        allowBackgroundAudio = true
        // Add boost
        lowLightBoost = true
        
        // Set bool
        isRearCam = true
        
        // Tap button to take photo
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        captureTap.numberOfTapsRequired = 1
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(captureTap)
        
        // Hold button to take record video
        let holdRecord = UILongPressGestureRecognizer(target: self, action: #selector(startVideoRecording))
        holdRecord.minimumPressDuration = 1.50
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(holdRecord)
        
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
        self.homeButton.isUserInteractionEnabled = true
        self.homeButton.addGestureRecognizer(leaveTap)
        
        // Tap to go to library
        let libTap = UITapGestureRecognizer(target: self, action: #selector(showLibrary))
        libTap.numberOfTapsRequired = 1
        self.libraryButton.isUserInteractionEnabled = true
        self.libraryButton.addGestureRecognizer(libTap)
        
        // Tap to crete new text post
        let tpTap = UITapGestureRecognizer(target: self, action: #selector(newTP))
        tpTap.numberOfTapsRequired = 1
        self.newTextButton.isUserInteractionEnabled = true
        self.newTextButton.addGestureRecognizer(tpTap)
        
        // Bring buttons to front
        let buttons = [self.captureButton,
                       self.flashButton,
                       self.swapCameraButton,
                       self.libraryButton,
                       self.homeButton,
                       self.newTextButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
        
        // Enable view
        self.view.isUserInteractionEnabled = true
        self.homeButton.isEnabled = true
        self.libraryButton.isEnabled = true
        self.homeButton.isEnabled = true
        self.newTextButton.isEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
