//
//  RPCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class RPCamera: UIViewController, UINavigationControllerDelegate {
    
    
    
    // Initialize CameraManager
    let cameraManager = CameraManager()
    
    // Variable to determine camera face
    // By default, back camera loads
    var frontBack = "back"
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet weak var switchCamera: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageTaken: UIImageView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to take photo
    func takePhoto(sender: UIButton) {
        print("FIRED HERE")
        // Set output mode
        cameraManager.cameraOutputMode = .stillImage
        // Capture photo
        cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
            
            if self.captureButton.image(for: .normal) == UIImage(named: "Unchecked Circle-100") {
                if self.frontBack == "front" {
                    // Flip image
                    let flippedImage = UIImage(cgImage: image as! CGImage, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                    self.imageTaken.isHidden = false
                    self.imageTaken.image = flippedImage
                    
                } else {
                    
                    // Check whether front or back
                    self.imageTaken.isHidden = false
                    self.imageTaken.image = image
                }
                
            } else {
                
            }

        })
        
    }
    
    
    // Function to record video
    func recordVideo(sender: UIButton) {
        print("FIRED THERE")
        /*
        cameraManager.cameraOutputMode = cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic ? CameraOutputMode.stillImage : CameraOutputMode.videoWithMic
        switch (cameraManager.cameraOutputMode) {
        case .stillImage:
            self.captureButton.isSelected = false
            self.captureButton.backgroundColor = UIColor.green
            sender.setTitle("Image", for: UIControlState())
        case .videoWithMic, .videoOnly:
            sender.setTitle("Video", for: UIControlState())
        }
        */
    }
    
    
    
    // Function to switch camera
    func changeCamera(sender: UIButton) {
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.front ? CameraDevice.back : CameraDevice.front
    }
    
    
    // Function to handle flash
    func controlFlash(sender: UIButton) {
        switch (cameraManager.changeFlashMode()) {
        case .off:
            sender.setTitle("Flash Off", for: UIControlState())
        case .on:
            sender.setTitle("Flash On", for: UIControlState())
        case .auto:
            sender.setTitle("Flash Auto", for: UIControlState())
        }
    }
    
    
    
    
    
    
    // Add Camera
    fileprivate func addCameraToView() {
        cameraManager.addPreviewLayerToView(cameraView, newCameraOutputMode: CameraOutputMode.videoWithMic)
        cameraManager.showErrorBlock = { [weak self] (erTitle: String, erMessage: String) -> Void in
            
            let alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (alertAction) -> Void in  }))
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }

    
    
    
    // Hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }

    
    
    
    // Function to reload data
    func reload() -> String {
        // Set frontBack
        frontBack = "back"
        
        // Show flashButton
        self.flashButton.isHidden = false
        
        // Show switchCameraButton
        self.switchCamera.isHidden = false
        
        // Change button title
        self.captureButton.setImage(UIImage(named: "Unchecked Circle-100"), for: .normal)
        
        
        // Hide imageTaken
        self.imageTaken.isHidden = true
        
        // Hide retake button
        self.retakeButton.isHidden = true
        
        // Hide Save button
        self.saveButton.isHidden = true
        
        // Reload view
        self.viewDidLoad()
        
        return frontBack
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide imageTake
        self.imageTaken.isHidden = true
        
        // Add method taps
        let takePhoto = UITapGestureRecognizer(target: self, action: #selector(self.takePhoto))
        takePhoto.numberOfTapsRequired = 1
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(takePhoto)
        
        let switchTap = UITapGestureRecognizer(target: self, action: #selector(self.changeCamera))
        switchTap.numberOfTapsRequired = 1
        self.switchCamera.isUserInteractionEnabled = true
        self.switchCamera.addGestureRecognizer(switchTap)
        
        
        // Add camera view
        addCameraToView()
        
        // Add case:
        // by default, camera is to capture photos
        cameraManager.cameraOutputMode = .stillImage
        
        print(cameraManager.cameraOutputMode)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        self.navigationController!.setNavigationBarHidden(true, animated: false)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Resume session
        cameraManager.resumeCaptureSession()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide navigation bar
        self.navigationController!.setNavigationBarHidden(true, animated: false)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop session
        cameraManager.stopCaptureSession()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    
    
}
