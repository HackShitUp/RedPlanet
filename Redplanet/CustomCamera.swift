//
//  CustomCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

class CustomCamera: UIViewController, CLImageEditorDelegate {

    // todo::
    // (1) add front face flash
    // (2) add front face focus
    // (3) pinch to zoom back camera
    // (3a) pinch to zoom front camera
    
    
    
    // Variable to determine camera face
    // By default, back camera loads
    var frontBack = "back"
    
    // Custom Camera
    // AVFoundation
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // UIView for front facing camera flash
    let flashView = UIView()
    
    @IBOutlet weak var collectionView: UICollectionView!

    // Outlets
    @IBOutlet weak var retakeButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var imageTaken: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    
    
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveButton(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.5) { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
        
        UIImageWriteToSavedPhotosAlbum(self.imageTaken.image!, self, nil, nil)
    }

    
    @IBAction func exit(_ sender: AnyObject) {
        // Dismiss Camera
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func retake(_ sender: AnyObject) {
        // Call function to reload data
        reload()
    }
    
    @IBOutlet weak var flashButton: UIButton!
    @IBAction func flash(_ sender: UIButton) {
        
        if sender.image(for: .normal) == UIImage(named: "Lightning Bolt-96") {
            // Turn flash ON
            flashButton.setImage(UIImage(named: "Thunder"), for: .normal)
            let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            if (device?.hasFlash)! {
                do {
                    try device?.lockForConfiguration()
                    device?.flashMode = .on
                    
                    if (device?.flashMode == .on) {
                        device?.flashMode = .on
                        
                    } else {
                        do {
                            try device?.setTorchModeOnWithLevel(1.0)
                        } catch {
                            print(error)
                        }
                        device?.flashMode = .on
                    }
                    device?.unlockForConfiguration()
                    
                    
                } catch {
                    print(error)
                }
            }
            
        } else {
            // Turn flash OFF
            flashButton.setImage(UIImage(named: "Lightning Bolt-96"), for: .normal)
            let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            if (device?.hasFlash)! {
                do {
                    try device?.lockForConfiguration()
                    device?.flashMode = .on
                    
                    if (device?.flashMode == .on) {
                        device?.flashMode = .off
                        
                    } else {
                        do {
                            try device?.setTorchModeOnWithLevel(1.0)
                        } catch {
                            print(error)
                        }
                        device?.flashMode = .on
                    }
                    device?.unlockForConfiguration()
                    
                    
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBAction func switchCamera(_ sender: AnyObject) {
        // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
        if frontBack == "back" {
            frontBack = "front"
            self.flashButton.isHidden = true
            // Reload data
            self.viewDidLoad()
        } else {
            frontBack = "back"
            self.flashButton.isHidden = false
            // Reload data
            self.viewDidLoad()
        }
    }
    

    
    @IBAction func didTakePhoto(_ sender: UIButton) {
        
        if sender.image(for: .normal) == UIImage(named: "Unchecked Circle-100") {
            
            if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
                // ...
                // Code for photo capture goes here...
                stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                    // ...
                    // Process the image data (sampleBuffer) here to get an image file we can put in our captureImageView
                    
                    if sampleBuffer != nil {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                        let dataProvider = CGDataProvider(data: imageData as! CFData)
                        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)
                        
                        // Check whether the camera is the front or the back
                        // If front, flip the image once photo is captured and add flash
                        // FRONT CAMERA
                        if self.frontBack == "front" {
                            // Flip image
                            let flippedImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.leftMirrored)
                            self.imageTaken.isHidden = false
                            self.imageTaken.image = flippedImage
                            
                            // Set Front flash??
                            // Currently not working... :/
                            /*
                             if self.flashButton.imageForState(.Normal) == UIImage(named: "FilledFlash100") {
                             self.flashScreen()
                             }
                             */
                            
                        } else {
                            // BACK CAMERA
                            // Don't flip image
                            let normalImage = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                            self.imageTaken.isHidden = false
                            self.imageTaken.image = normalImage
                        }
                        
                        
                        
                        // Hide flashButton
                        self.flashButton.isHidden = true
                        
                        // Hide switchCameraButton
                        self.switchCameraButton.isHidden = true
                        
                        // Change button's title
                        self.captureButton.setImage(UIImage(named: "UsePhoto"), for: .normal)
                        
                        
                        
                        
                        // Show retake button
                        self.retakeButton.isHidden = false
                        
                        // Show save Button
                        self.saveButton.isHidden = false
                    }
                    
                    
                })
            }
        }
        
        if sender.image(for: .normal) == UIImage(named: "UsePhoto") {
            
            // Clear arrays
//            mediaAssets.removeAll(keepCapacity: false)
//            imageAssets.removeAll(keepCapacity: false)
            
            // Append image
//            imageAssets.append(self.imageTaken.image!)
            
            // set mediaType
//            mediaType = "photo"
            
            // Push to next ShareMedia view controller
            //            let shareVC = self.storyboard?.instantiateViewControllerWithIdentifier("shareMedia") as! ShareMedia
            //            self.navigationController!.pushViewController(shareVC, animated: true)
            //            self.presentViewController(shareVC, animated: true, completion: nil)
            // Perform segueue
//            self.performSegueWithIdentifier("shareMedia", sender: self)
            
            
            
            editPhoto()
        }
        
    }
    
    
    // CLImageEditor
    func editPhoto() {
        let editor = CLImageEditor(image: self.imageTaken.image!)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    
    func imageEditor(editor: CLImageEditor, didFinishEdittingWithImage image: UIImage) {
        self.imageTaken.image = image
        editor.dismiss(animated: true, completion: nil)
    }
    
    
    
    // Mimic front flash
    // Release UIView with alpha
    // To brighten up front camera
    func flashScreen() {
        flashView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        flashView.alpha = 1.0
        flashView.backgroundColor = UIColor.white
        UIScreen.main.brightness = 1 // turn brightness all the way up
        UIApplication.shared.keyWindow?.addSubview(flashView)
        
        // Remove after 3 seconds
        let timer = Timer.scheduledTimer(timeInterval: TimeInterval(0.3), target: self, selector: #selector(removeFlash), userInfo: nil, repeats: false)
    }
    
    func removeFlash() {
        flashView.removeFromSuperview()
    }
    

    
    // Swipe for filters
    func filterSwipe(sender: AnyObject) {
//        let context = CIContext(options: nil)
//        
//        // Create an image to filter
//        let inputImage = CIImage(image: imageTaken.image!)
//        
//        // Create a random color to pass to a filter
//        let randomColor = [kCIInputAngleKey: (Double(arc4random_uniform(314)) / 100)]
//        
//        // Apply a filter to the image
//        let filteredImage = inputImage!.imageByApplyingFilter("CIHueAdjust", withInputParameters: randomColor)
//        
//        // Render the filtered image
//        let renderedImage = context.createCGImage(filteredImage, fromRect: imageTaken.frame)
//        
//        // Reflect the change back in the interface
//        imageTaken.image = UIImage(CGImage: renderedImage!)
//        imageTaken.clipsToBounds = true
    }
    
    
    // Function to reload data
    func reload() -> String {
        // Set frontBack
        frontBack = "back"
        
        // Show flashButton
        self.flashButton.isHidden = false
        
        // Show switchCameraButton
        self.switchCameraButton.isHidden = false
        
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
    
    
    // Touch to focus camera
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let screenSize = previewView.bounds.size
        if let touchPoint = touches.first {
            let x = touchPoint.location(in: previewView).y / screenSize.height
            let y = 1.0 - touchPoint.location(in: previewView).x / screenSize.width
            let focusPoint = CGPoint(x: x, y: y)
            
            if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
                
                do {
                    try device.lockForConfiguration()
                    
                    device.focusPointOfInterest = focusPoint
                    //device.focusMode = .ContinuousAutoFocus
                    device.focusMode = .autoFocus
                    //device.focusMode = .Locked
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                }
                catch {
                    // just ignore
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Double tap to switch cameras
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(switchCamera))
        doubleTap.numberOfTapsRequired = 2
        self.previewView.isUserInteractionEnabled = true
        self.previewView.addGestureRecognizer(doubleTap)
        
        // Set frame sizes
        self.previewView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        self.imageTaken.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        // Hide UIImageView()
        self.imageTaken.isHidden = true
        
        // Hide retake button
        self.retakeButton.isHidden = true
        
        // Hide save button
        self.saveButton.isHidden = true
        
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSessionPresetHigh
        
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            var captureDevice:AVCaptureDevice
            
            for device in videoDevices!{
                let device = device as! AVCaptureDevice
                if frontBack == "front" {
                    if device.position == AVCaptureDevicePosition.front {
                        captureDevice = device
                        input = try AVCaptureDeviceInput(device: captureDevice)
                        break
                    }
                } else {
                    if device.position == AVCaptureDevicePosition.back {
                        captureDevice = device
                        input = try AVCaptureDeviceInput(device: captureDevice)
                        break
                    }
                }
            }
            
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            // ...
            // The remainder of the session setup will go here...
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        }
        
        if session!.canAddOutput(stillImageOutput) {
            session!.addOutput(stillImageOutput)
            // ...
            // Configure the Live Preview here...
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewView.layer.addSublayer(videoPreviewLayer!)
        session!.startRunning()
        
        videoPreviewLayer!.frame = previewView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
//        self.navigationController!.setNavigationBarHidden(true, animated: false)
        // Hide tabBarController
//        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide navigation bar
//        self.navigationController!.setNavigationBarHidden(true, animated: false)
        // Hide tabBarController
//        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
