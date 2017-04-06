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

/*
 Extension to apply Shadow to icons
 */
extension CALayer {
    func applyShadow(layer: CALayer?) {
        layer!.shadowColor = UIColor.black.cgColor
        layer!.shadowOffset = CGSize(width: 1, height: 1)
        layer!.shadowRadius = 3
        layer!.shadowOpacity = 0.5
    }
}


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

    @IBAction func showLibraryUI(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .left)
    }
    
    @IBAction func showMainUI(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
    }
    
    @IBAction func showTextUI(_ sender: Any) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .right)
    }
    
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
            self.swapCameraButton.setImage(UIImage(named: "Switch Camera-100"), for: .normal)
        } else if camera == .front {
            isRearCam = false
            self.swapCameraButton.setImage(nil, for: .normal)
            self.swapCameraButton.setTitle("😎", for: .normal)
        }
    }
    
    
    
    @IBAction func swapCamera(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        flashEnabled = !flashEnabled
        
        if flashEnabled == true {
            flashButton.setImage(UIImage(named: "Thunder"), for: .normal)
        } else {
            flashButton.setImage(UIImage(named: "Lightning Bolt-96"), for: .normal)
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
                
//                print("ALL PLACEMARKS: \(placemarks!)\n\n")
                
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
    
    // Leave VC
    func showProfileUI() {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .top)
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
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.view.bringSubview(toFront: self.captureButton)
        }
        
        // Make homeButton circular
        self.homeButton.layer.cornerRadius = self.homeButton.frame.size.width/2
        self.homeButton.clipsToBounds = true
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
        configureView()
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
