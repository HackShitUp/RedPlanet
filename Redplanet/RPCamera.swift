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
        let stillVC = self.storyboard?.instantiateViewController(withIdentifier: "stillVC") as! CapturedStill
        stillVC.stillImage = photo
        self.navigationController?.pushViewController(stillVC, animated: false)
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
        let focusView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        focusView.makeCircular(forView: focusView, borderWidth: 0, borderColor: UIColor.clear)
        focusView.backgroundColor = UIColor.randomColor()
        focusView.image = UIImage(named: "Camera")
        focusView.center = point
        view.addSubview(focusView)
        // Animate focusView
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }, completion: { (success) in
                focusView.removeFromSuperview()
            })
        })
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
    
    // FUNCTION - Trigger location
    func triggerLocation() {
        // MARK: - CoreLocation
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    
    // FUNCTION - Authorize user's location
    func authorizeLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            self.triggerLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
        // THIS might get a bit annoying
            
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Location Access Denied",
                                                          message: "Please enable Location access so you can share Moments with geo-filters and help us find your friends better!")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = true
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.layer.masksToBounds = true
            }
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "Settings", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
                // Show Settings
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            
            // Cancel
            dialogController.cancelButtonStyle = { (button,height) in
                button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determine LaunchPreferences
        if UserDefaults.standard.bool(forKey: "launchOnCamera") == false {
            self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        }
        
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
    
    
    
    
    
    /******************************************************************************************
     // MARK: - OpenWeatherMap.org API
     *******************************************************************************************/
    open func getWeather(lat: CLLocationDegrees, lon: CLLocationDegrees) {
        
        // MARK: - OpenWeatherMap API
        URLSession.shared.dataTask(with: URL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=0abf9dff54ea3ccb6561c3574557594c")!,
                                   completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                                    if error != nil {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - RPHelpers
                                        let rpHelpers = RPHelpers()
                                        rpHelpers.showError(withTitle: "Network Error")
                                        return
                                    }
                                    do  {
                                        // Traverse JSON data to "Mutable Containers"
                                        let json = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                                        
                                        // Optionally chain NSDictionary value to prevent from crashing...
                                        if let main = (json as AnyObject).value(forKey: "main") as? NSDictionary {
                                            let kelvin = main["temp"] as! Double
                                            let farenheit = (kelvin * 1.8) - 459.67
                                            let celsius = kelvin - 273.15
                                            let both = "\(Int(farenheit))°F\n\(Int(celsius))°C"
                                            // Append Temperature as String
                                            temperature.append(both)
                                        }
                                        
                                    } catch let error {
                                        print(error.localizedDescription as Any)
                                        // MARK: - RPHelpers
                                        let rpHelpers = RPHelpers()
                                        rpHelpers.showError(withTitle: "Network Error")
                                    }
        }) .resume()
    }
    
    
    
    /*
     MARK: - CoreLocation Delegate Methods
     (1) Append Altitude: CLLocationDistance
     (2) Append Geolocation: CLPlacemark
     (3) Append Weather: String
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Clear global arrays in "CapturedStill.swift"
        let capturedStill = CapturedStill()
        capturedStill.clearArrays()
        
        // (1) CLLocationDistance
        altitudeFence.append(locations[0].altitude)
        
        // MARK: - CLGeocoder; Reverse engineer coordinates, and get the address
        geoLocation.reverseGeocodeLocation(locations[0]) {
            (placemarks: [CLPlacemark]?, error: Error?) in
            if error == nil {
                if placemarks!.count > 0 {
                    let pm = placemarks![0]
                    // Save PFGeoPoint
                    let geoPoint = PFGeoPoint(latitude: pm.location!.coordinate.latitude, longitude: pm.location!.coordinate.longitude)
                    PFUser.current()!["location"] = geoPoint
                    PFUser.current()!.saveInBackground()
                    
                    if currentGeoFence.isEmpty {
                        
                        // (2) Append Geolocation --> CLPlacemark
                        currentGeoFence.append(pm)
                        
                        // (3) Append Weather --> String
                        // MARK: - OpenWeatherMap API
                        self.getWeather(lat: pm.location!.coordinate.latitude, lon: pm.location!.coordinate.longitude)
                        
                        
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
