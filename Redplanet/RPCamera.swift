//
//  RPCamera.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreLocation

import Parse
import ParseUI
import Bolts

import SwiftyCam
import SwipeNavigationController
import SDWebImage

// Bool to determine whether camera was accessed from Chats
var chatCamera: Bool = false
// Bool to determine camera side
var isRearCam: Bool?

class RPCamera: SwiftyCamViewController, SwiftyCamViewControllerDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate {
    
    // MARK: - CoreLocation
    let manager = CLLocationManager()
    let geoLocation = CLGeocoder()

    // MARK: - SegmentedProgressBar
    var spb: SegmentedProgressBar!
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var newTextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!

    // MARK: - SwipeNavigationController
    @IBAction func showLibraryUI(_ sender: Any) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .left)
    }
    
    // MARK: - SwipeNavigationController
    @IBAction func showMainUI(_ sender: Any) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
    }
    
    // MARK: - SwipeNavigationController
    @IBAction func showTextUI(_ sender: Any) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .right)
    }
    
    // MARK: - SwipeNavigationController
    func showProfileUI() {
        let currentUserVC = self.storyboard?.instantiateViewController(withIdentifier: "currentUserVC") as! CurrentUser
        self.navigationController?.pushViewController(currentUserVC, animated: true)
    }
    
    // MARK: - SwiftyCam Delegate Methods
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        stillImages.append(photo)
        let stillVC = self.storyboard?.instantiateViewController(withIdentifier: "stillVC") as! CapturedStill
        self.navigationController?.pushViewController(stillVC, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        self.libraryButton.isHidden = true
        self.homeButton.isHidden = true
        self.newTextButton.isHidden = true
        self.rpUserProPic.isHidden = true
        
        // MARK: - SegmentedProgressBar
        spb = SegmentedProgressBar(numberOfSegments: 1, duration: 10)
        spb.frame = CGRect(x: 8, y: UIApplication.shared.statusBarFrame.height, width: self.view.frame.width - 16, height: 4)
        spb.topColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        spb.padding = 5
        self.view.addSubview(spb)
        spb.startAnimation()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        self.libraryButton.isHidden = false
        self.homeButton.isHidden = false
        self.newTextButton.isHidden = false
        self.rpUserProPic.isHidden = false
        // MARK: - SegmentedProgressBar
        self.spb.isPaused = true
        self.spb.removeFromSuperview()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        capturedURLS.append(url)
        let capturedVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "capturedVideoVC") as! CapturedVideo
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
            self.swapCameraButton.setTitle("😜", for: .normal)
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

    // Function to configure view
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
        self.containerSwipeNavigationController?.shouldShowTopViewController = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        
        // Authorization
        authorizeLocation()
        
        // Set profile photo
        if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - RPExtensions
            self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.50, borderColor: UIColor.white)
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
        
        // MARK: - RPHelpers
        self.homeButton.makeCircular(forView: self.homeButton, borderWidth: 2, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
        
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

        // Tap to show ProfileUI
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(showProfileUI))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // Bring buttons to front
        let buttons = [self.rpUserProPic,
                       self.flashButton,
                       self.swapCameraButton,
                       self.libraryButton,
                       self.homeButton,
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
        // Set statusBar
        UIApplication.shared.statusBarStyle = .lightContent
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
