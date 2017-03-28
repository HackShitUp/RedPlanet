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

import SVProgressHUD
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
    
    // Timer for recording videos
    var time: Float = 0.0
    var timer: Timer?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var captureButton: SwiftyCamButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var newTextButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!

    
    // MARK: - SwiftyCam Delegate Methods
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
            self.rpUserProPic.isHidden = true
            self.progressView.setProgress(0, animated: false)
            self.progressView.isHidden = false
            self.view.bringSubview(toFront: self.progressView)
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.countDown), userInfo: nil, repeats: false)
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        self.libraryButton.isHidden = false
        self.homeButton.isHidden = false
        self.newTextButton.isHidden = false
        self.rpUserProPic.isHidden = false
        self.progressView.isHidden = true
        timer?.invalidate()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        DispatchQueue.main.async {
            capturedURLS.append(url)
            let capturedVideoVC = self.storyboard?.instantiateViewController(withIdentifier: "capturedVideoVC") as! CapturedVideo
            self.navigationController?.pushViewController(capturedVideoVC, animated: false)
        }
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
        } else if camera == .front {
            isRearCam = false
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
                                    
                    if cityState.isEmpty {
                        cityState.append("\(pm.locality!), \(pm.administrativeArea!)")

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
        
        
        
        // Save user's location to server
        if PFUser.current() != nil && PFUser.current()!.value(forKey: "location") != nil {
            PFGeoPoint.geoPointForCurrentLocation(inBackground: {
                (geoPoint: PFGeoPoint?, error: Error?) in
                if error == nil {
                    PFUser.current()!.setValue(geoPoint, forKey: "location")
                    PFUser.current()!.saveInBackground()
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
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
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
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
            let alert = UIAlertController(title: "Location Access Disabled",
                                                     message: "To share Moments with location-based filters, and help your friends find you better, please allow Redplanet to access your location!",
                                                     preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            let settings = UIAlertAction(title: "Settings", style: .default) { (action) in
                if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url as URL)
                }
            }
            
            alert.addAction(settings)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
            
        default:
            break;
        }
    }
    
    
    // Function to countdown timer when recording video
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
        if chatCamera == true {
            _ = self.navigationController?.popViewController(animated: false)
        } else {
            self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        }
    }
    
    // Push to Library
    func showLibrary() {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .left)
    }
    
    // Push to New Text Post
    func newTP() {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .right)
    }

    // Function to configure view
    func configureView() {
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .lightContent
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.containerSwipeNavigationController?.shouldShowRightViewController = true
        self.containerSwipeNavigationController?.shouldShowLeftViewController = true
        self.containerSwipeNavigationController?.shouldShowBottomViewController = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        
        // Authorization
        authorizeLocation()
        
        // Set profile photo
        if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
            self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
            self.rpUserProPic.layer.borderColor = UIColor.white.cgColor
            self.rpUserProPic.layer.borderWidth = 0.75
            self.rpUserProPic.clipsToBounds = true
            // MARK: - SDWebImage
            self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
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
        
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
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
        let buttons = [self.rpUserProPic,
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
            self.view.bringSubview(toFront: self.captureButton)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
}
