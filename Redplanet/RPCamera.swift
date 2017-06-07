//
//  RPCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreLocation
import MediaPlayer

import Parse
import ParseUI
import Bolts

import SwiftyCam
import SwipeNavigationController
import SDWebImage

// Boolean to determine whether camera was accessed from Chats
var chatCamera: Bool = false
// Boolean to determine camera side; used for SnapSliderFilters to process filters efficiently
var isRearCam: Bool?


/*
 Class that adopts the SwiftyCamViewController (open-source). If the user taps the camera button (photo-moment), this class
 pushes to "CapturedStill.swift". Otherwise, if the user holds onto the camera button (video-moment), this class pushes to
 "CapturedVideo.swift"
 */


class RPCamera: SwiftyCamViewController, SwiftyCamViewControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate {
    
    // MARK: - CoreLocation
    let manager = CLLocationManager()
    let geoLocation = CLGeocoder()

    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    // MARK: - SubtleVolume
    var subtleVolume: SubtleVolume!
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var newTextButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!

    @IBAction func searchAction(_ sender: Any) {
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! Search
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    // MARK: - SwipeNavigationController
    @IBAction func showLibraryUI(_ sender: Any) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .left)
    }
    
    // MARK: - SwipeNavigationController
    @IBAction func showTextUI(_ sender: Any) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .right)
    }
    
    // MARK: - SwipeNavigationController
    func showMainUI() {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
    }

    // MARK: - SwiftyCam Delegate Methods
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        DispatchQueue.main.async(execute: {
            let stillVC = self.storyboard?.instantiateViewController(withIdentifier: "stillVC") as! CapturedStill
            stillVC.stillImage = photo
            self.navigationController?.pushViewController(stillVC, animated: false)
        })
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        // Hide UIButtons
        self.libraryButton.isHidden = true
        self.newTextButton.isHidden = true
        self.rpUserProPic.isHidden = true
        self.searchButton.isHidden = true
        self.flashButton.isHidden = true
        self.swapCameraButton.isHidden = true
        
        // MARK: - SegmentedProgressBar
        spb = SegmentedProgressBar(numberOfSegments: 1, duration: 10)
        spb.frame = CGRect(x: 8, y: UIApplication.shared.statusBarFrame.height, width: self.view.frame.width - 16, height: 4)
        spb.topColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        spb.padding = 5
        self.view.addSubview(spb)
        spb.startAnimation()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        // MARK: - SegmentedProgressBar
        self.spb.isPaused = true
        self.spb.removeFromSuperview()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // Show UIButtons
        self.libraryButton.isHidden = false
        self.newTextButton.isHidden = false
        self.rpUserProPic.isHidden = false
        self.searchButton.isHidden = false
        self.flashButton.isHidden = false
        self.swapCameraButton.isHidden = false
        
        let capturedVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "capturedVideoVC") as! CapturedVideo
        capturedVideoVC.capturedURL = url
        self.navigationController?.pushViewController(capturedVideoVC, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        // Tapped preview layer
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        // Zoom level changed
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        if camera == .rear {
            isRearCam = true
            self.swapCameraButton.setImage(UIImage(named: "SwapCamera"), for: .normal)
        } else if camera == .front {
            isRearCam = false
            self.swapCameraButton.setImage(nil, for: .normal)
            self.swapCameraButton.setImage(UIImage(named: "Stickers"), for: .normal)
        }
    }
    
    @IBAction func swapCamera(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        flashEnabled = !flashEnabled
        if flashEnabled == true {
            flashButton.setImage(UIImage(named: "FlashOn"), for: .normal)
        } else {
            flashButton.setImage(UIImage(named: "FlashOff"), for: .normal)
        }
    }
    
    
    // MARK: - CoreLocation Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        // MARK: - CLGeocoder
        // Reverse engineer coordinates, and get address
        geoLocation.reverseGeocodeLocation(location) {
            (placemarks: [CLPlacemark]?, error: Error?) in
            if error == nil {
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    // Save PFGeoPoint
                    let geoPoint = PFGeoPoint(latitude: pm.location!.coordinate.latitude, longitude: pm.location!.coordinate.longitude)
                    PFUser.current()!["location"] = geoPoint
                    PFUser.current()!.saveInBackground()
                    
                    if currentGeoFence.isEmpty {
                        // Append: CLPlacemark
                        currentGeoFence.append(pm)
                        
                        // MARK: - RPHelpers; Get weather data
                        let rpHelpers = RPHelpers()
                        _ = rpHelpers.getWeather(lat: pm.location!.coordinate.latitude, lon: pm.location!.coordinate.longitude)
                        
                        // MARK: - CLLocationManager
                        manager.stopUpdatingLocation()
                    } else {
                        // End queues
                        self.geoLocation.cancelGeocode()
                        // MARK: - CLLocationManager
                        manager.stopUpdatingLocation()
                    }
                }
            } else {
                print("Reverse geocoderfailed with error: \(error?.localizedDescription as Any)")
                if (error?.localizedDescription as Any) as! String == "The operation couldn’t be completed. (kCLErrorDomain error 2.)" {
                    // End queues
                    self.geoLocation.cancelGeocode()
                    // MARK: - CLLocationManager
                    manager.stopUpdatingLocation()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager:\(manager) didFailWithError:\(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // Trigger location
            self.triggerLocation()
        }
    }
    
    // Function to trigger location
    func triggerLocation() {
        // MARK: - CoreLocation
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    
    // Function to authorize user's location
    func authorizeLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            self.triggerLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
        // THIS might get a bit annoying
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Location Access Disabled",
                                                          message: "To share Moments with location-based filters, and help your friends find you better, please allow Redplanet to access your location.")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.layer.masksToBounds = true
            }
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // Show Settings
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url as URL)
                }
            }))
            
            // Cancel
            dialogController.cancelButtonStyle = { (button,height) in
                button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.setTitle("LATER", for: [])
                return true
            }
            
            dialogController.show(in: self)
            
        default:
            break;
        }
    }

    // FUNCTION - Configure View
    func configureView() {
        // Configure UIStatusBar
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Hide UINavigationBar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // MRK: - RPHelpers
        self.view.roundAllCorners(sender: self.view)
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowRightViewController = true
        self.containerSwipeNavigationController?.shouldShowLeftViewController = true
        self.containerSwipeNavigationController?.shouldShowBottomViewController = true
    }

    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        
        // Authorization
        authorizeLocation()
        
        // Set Profile Photo
        if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - RPExtensions
            self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0, borderColor: UIColor.clear)
            // MARK: - SDWebImage
            self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        // MARK: - SwiftyCam
        // Set delegate for camera view
        self.cameraDelegate = self
        // Set delegate to record video
        self.captureButton.delegate = self
        // Set video duration and length
        self.maximumVideoDuration = 10.00
        // Set tap to focus
        self.tapToFocus = true
        // Double tap to switch camera
        self.doubleTapCameraSwitch = true
        // Allow background music
        self.allowBackgroundAudio = true
        // Add boost
        self.lowLightBoost = true
        
        // MARK: - SnapSliderFilters
        // Set bool so images aren't flipped and reloaded
        if currentCamera == .front {
            isRearCam = false
        } else {
            isRearCam = true
        }
        
        // Hide buttons if camera is via Chats...
        if chatCamera == true {
            newTextButton.isHidden = true
            libraryButton.isHidden = true
        } else {
            self.libraryButton.isHidden = false
            self.newTextButton.isHidden = false
        }
        
        // Tap button to take photo
        let captureTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        captureTap.numberOfTapsRequired = 1
        captureButton.isUserInteractionEnabled = true
        captureButton.addGestureRecognizer(captureTap)
        
        // Hold button to take record video
        let holdRecord = UILongPressGestureRecognizer(target: self, action: #selector(startVideoRecording))
        holdRecord.minimumPressDuration = 1.50
        captureButton.isUserInteractionEnabled = true
        captureButton.addGestureRecognizer(holdRecord)

        // Tap to show ProfileUI
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showMainUI))
        proPicTap.numberOfTapsRequired = 1
        rpUserProPic.isUserInteractionEnabled = true
        rpUserProPic.addGestureRecognizer(proPicTap)
        
        // Bring buttons to front
        let buttons = [self.rpUserProPic,
                       self.flashButton,
                       self.searchButton,
                       self.swapCameraButton,
                       self.libraryButton,
                       self.newTextButton] as [Any]
        for b in buttons {
            // MARK: - RPHelpers
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.view.bringSubview(toFront: self.captureButton)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - SwiftyCam
        // Set delegate for camera view
        self.cameraDelegate = self
        // Set delegate to record video
        self.captureButton.delegate = self
        // Set video duration and length
        self.maximumVideoDuration = 10.00
        // Set tap to focus
        self.tapToFocus = true
        // Double tap to switch camera
        self.doubleTapCameraSwitch = true
        // Allow background music
        self.allowBackgroundAudio = true
        // Add boost
        self.lowLightBoost = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // MARK: - SubtleVolume
        subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        subtleVolume.delegate = self
        self.view.addSubview(subtleVolume)
        
        // Configure UIStatusBar
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
        
        // Change background color
        self.navigationController?.view.backgroundColor = UIColor.black

        // Set UIView animations
        UIView.setAnimationsEnabled(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
}



/*
 MARK: - RPCamera Extension; SubtleVolumeDelegate Method
 Used to manipulate iOS device hardware by allowing users to capture photos/videos with the volume button
 TODO:: INCOMPLETE!
 */
extension RPCamera: SubtleVolumeDelegate {
    
    func subtleVolume(_ subtleVolume: SubtleVolume, willChange value: Float) {
        // TOOD::
    }

    func subtleVolume(_ subtleVolume: SubtleVolume, didChange value: Float) {
        // self.takePhoto()
    }
}
