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
    
    // MARK: - Constants
    
    let cameraManager = CameraManager()
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet weak var switchCamera: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageTaken: UIImageView!
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to take photo
    func takePhoto(sender: UIButton) {
        switch (cameraManager.cameraOutputMode) {
        case .stillImage:
            cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
                if let errorOccured = error {
                    self.cameraManager.showErrorBlock("Error occurred", errorOccured.localizedDescription)
                } else {
//                    let vc: ImageViewController? = self.storyboard?.instantiateViewController(withIdentifier: "ImageVC") as? ImageViewController
//                    if let validVC: ImageViewController = vc {
//                        if let capturedImage = image {
//                            validVC.image = capturedImage
//                            self.navigationController?.pushViewController(validVC, animated: true)
//                        }
//                    }
                    
                    
                    
                    if let capturedImage = image {
                        self.imageTaken.isHidden = false
                        self.imageTaken.image = capturedImage
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                }
            })
        case .videoWithMic, .videoOnly:
//            sender.isSelected = !sender.isSelected
//            sender.setTitle(" ", for: UIControlState.selected)
//            sender.backgroundColor = sender.isSelected ? UIColor.red : UIColor.green
            if sender.isSelected {
                cameraManager.startRecordingVideo()
            } else {
                cameraManager.stopVideoRecording({ (videoURL, error) -> Void in
                    if let errorOccured = error {
                        self.cameraManager.showErrorBlock("Error occurred", errorOccured.localizedDescription)
                    }
                })
            }
        }
        
        
        
    }
    
    
    // Function to record video
    func recordVideo(sender: UIButton) {
        cameraManager.cameraOutputMode = cameraManager.cameraOutputMode == CameraOutputMode.videoWithMic ? CameraOutputMode.stillImage : CameraOutputMode.videoWithMic
        switch (cameraManager.cameraOutputMode) {
        case .stillImage:
//            self.captureButton.isSelected = false
            self.captureButton.backgroundColor = UIColor.green
            sender.setTitle("Image", for: UIControlState())
        case .videoWithMic, .videoOnly:
            sender.setTitle("Video", for: UIControlState())
        }
    }
    
    
    
    // Function to switch camera
    func switchCamera(sender: UIButton) {
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.front ? CameraDevice.back : CameraDevice.front
        switch (cameraManager.cameraDevice) {
        case .front:
            sender.setTitle("Front", for: UIControlState())
        case .back:
            sender.setTitle("Back", for: UIControlState())
        }
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

    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide imageTake
        self.imageTaken.isHidden = true
        
        // Add method taps
        let takePhoto = UITapGestureRecognizer(target: self, action: #selector(self.takePhoto))
        takePhoto.numberOfTapsRequired = 1
        self.captureButton.isUserInteractionEnabled = true
        self.captureButton.addGestureRecognizer(takePhoto)
        
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
