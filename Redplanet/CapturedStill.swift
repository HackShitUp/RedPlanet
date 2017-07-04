//
//  CapturedStill.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

import Parse
import ParseUI
import Bolts

import GPUImage
import OneSignal
import SDWebImage
import SVProgressHUD
import SwipeView
import SwipeNavigationController


// Array to hold user's location
var currentGeoFence = [CLPlacemark]()
var altitudeFence = [CLLocationDistance]()
var temperature = [String]()

/*
 UIViewController class that allows users to filter and edit their photo-moments before sharing them. When red arrow button is tapped,
 this class pushes to "ShareWith.swift" for sharing options
 */

class CapturedStill: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate, SwipeNavigationControllerDelegate, SwipeViewDataSource, SwipeViewDelegate {
    
    // MARK: - Class Variable
    var stillImage: UIImage?
    
    // Create GPUImageFilters, Filtered UIImages, and UIImageView for filter
    var filters = [Any]()
    var filteredImages = [UIImage]()
    
    // MARK: - SwipeView
    @IBOutlet weak var swipeView: SwipeView!
    
    // MARK: - RPCaptionView
    var rpCaptionView: RPCaptionView!
    let textView = UITextView(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height/2))
    let tapGesture = UITapGestureRecognizer()
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var stillPhoto: PFImageView!
    @IBOutlet weak var leaveButton: UIButton!
    
    @IBAction func dismissVC(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveButton(_ sender: Any) {
        DispatchQueue.main.async(execute: {
            // Save photo
            UIImageWriteToSavedPhotosAlbum(RPUtilities.screenShot(self.view)!, self, nil, nil)
            // MARK: - SVProgressHUD
            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
            SVProgressHUD.showSuccess(withStatus: "Saved Photo!")
        })
    }
    
    @IBOutlet weak var drawButton: UIButton!
    @IBAction func draw(_ sender: Any) {
        // Disable filterView
        self.completeButton.isHidden = false
        self.undoButton.isHidden = false
    }
    
    @IBOutlet weak var textButton: UIButton!
    @IBAction func text(_ sender: Any) {
        self.wakeCaptionView()
    }
    
    // FUNCTION - Clear arrays
    open func clearArrays() {
        currentGeoFence.removeAll(keepingCapacity: false)
        altitudeFence.removeAll(keepingCapacity: false)
        temperature.removeAll(keepingCapacity: false)
    }

    // FUNCTION - Show or Hide UIButtons with Animations and pass to completionHandler whether all buttons ARE hidden...
    func configureButtonState(shouldHide: Bool, completionHandler: @escaping (_ completed: Bool) -> ()) {
        let buttons = [leaveButton,
                       saveButton,
                       textButton,
                       continueButton] as [Any]
        
        for b in buttons {
            let buttonView = (b as AnyObject) as! UIView
            UIView.animate(withDuration: 0.3, animations: {
                            buttonView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                            buttonView.isHidden = shouldHide
            }, completion: { _ in UIView.animate(withDuration: 0.3) {
                                buttonView.transform = .identity
                            }
            })
        }
        
        completionHandler(true)
    }
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func continueButton(_ sender: Any) {
        // Configure button states
        self.configureButtonState(shouldHide: true) { (success: Bool) in
            // Execute Saving to Server if completionHandler returns true
            if success == true {

                // MOMENT
                if chatCamera == false {
                    // Create PFObject
                    let itmPhoto = PFObject(className: "Posts")
                    itmPhoto["byUser"] = PFUser.current()!
                    itmPhoto["byUsername"] = PFUser.current()!.username!
                    itmPhoto["contentType"] = "itm"
                    itmPhoto["saved"] = false
                    itmPhoto["textPost"] = self.rpCaptionView.textView.text
                    itmPhoto["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(RPUtilities.screenShot(self.view)!, 0.5)!)
                    // Show ShareWith View Controller
                    shareWithObject.append(itmPhoto)
                    let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                    self.navigationController?.pushViewController(shareWithVC, animated: true)
                    
                } else {
                // CHATS
                    // Disable button
                    self.continueButton.isUserInteractionEnabled = false
                    
                    let chats = PFObject(className: "Chats")
                    chats["sender"] = PFUser.current()!
                    chats["senderUsername"] = PFUser.current()!.username!
                    chats["receiver"] = chatUserObject.last!
                    chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
                    chats["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(RPUtilities.screenShot(self.view)!, 0.5)!)
                    chats["contentType"] = "itm"
                    chats["read"] = false
                    chats["saved"] = false
                    chats.saveInBackground()
                    
                    // MARK: - RPHelpers; update ChatsQueue and send push notification
                    let rpHelpers = RPHelpers()
                    rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                    rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                    
                    // Reload data
                    NotificationCenter.default.post(name: rpChat, object: nil)
                    // Make false
                    chatCamera = false
                    // Clear arrrays
                    self.clearArrays()
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    // MARK: - SwipeNavigationController
                    self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
                }
            }
        }
    }
    
    
    // FUNCTION - Apply mask
    func applyMask(maskRect: CGRect, newXPosition: CGFloat) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        var rect = maskRect
//        rect.origin.x = newXPosition
//        rect.origin.x = newXPosition/swipeView.frame.width
//        rect.origin.x = newXPosition * swipeView.frame.width
        print(newXPosition)
        path.addRect(rect)
        maskLayer.path = path
        self.swipeView.layer.mask = maskLayer
//        self.swipeView.currentItemView.layer.mask = maskLayer
//        self.view.layer.mask = maskLayer
    }
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        // Pop View Controller
        if position == .bottom {
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        // Delegate
    }
    
    // MARK: - SwipeView Data Source Methods
    func numberOfItems(in swipeView: SwipeView!) -> Int {
        // Add 2 for Time and Day filters
        return self.filteredImages.count
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView!) -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    func swipeView(_ swipeView: SwipeView!, viewForItemAt index: Int, reusing view: UIView!) -> UIView! {
        let filteredImageView = UIImageView(frame: self.view.frame)
        filteredImageView.contentMode = .scaleAspectFill
        filteredImageView.image = filteredImages[index]
        return filteredImageView
    }
    
    // MARK: - SwipeView Delegate Methods
    func swipeViewDidScroll(_ swipeView: SwipeView!) {
        // CONTENTOFFSET
        let currentFrame = swipeView.currentItemView.convert(swipeView.currentItemView.frame, from: self.swipeView)
        let newFrameWithIndex = currentFrame.origin.x/swipeView.frame.size.width - CGFloat(swipeView.numberOfItems - 1)
        let svContentOffset = newFrameWithIndex * swipeView.frame.width
        
        // Position Of Page at Index
        let indexPosition = swipeView.frame.width * CGFloat(swipeView.currentItemIndex - 1) + swipeView.frame.width

        // Get newX
        let newX = svContentOffset - indexPosition
        applyMask(maskRect: swipeView.frame, newXPosition: newX)
    }
    
    func swipeViewDidEndDecelerating(_ swipeView: SwipeView!) {
        // TODO
    }
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - GPUImage; Sharpen Image immediately
        let sharpenFilter = GPUImageSharpenFilter()
        let filteredImage = sharpenFilter.image(byFilteringImage: self.stillImage!)
        self.stillImage = filteredImage
        
        // Set image
        self.stillPhoto.image = self.stillImage
        // Generate filters
        self.generateFilters(filteredImage!)
        
        // Enable interaction with stillPhoto for filterView
        self.stillPhoto.isUserInteractionEnabled = true
        // Set textButton title
        self.textButton.setTitle("Aa", for: .normal)

        // MARK: - RPCaptionView
        rpCaptionView = RPCaptionView(frame: CGRect(x: 0, y: 53, width: self.view.frame.size.width, height: self.view.frame.size.height/2))
        rpCaptionView.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(wakeCaptionView))

        // MARK:- SwipeNavigationController
        self.containerSwipeNavigationController?.delegate = self
        self.containerSwipeNavigationController?.shouldShowRightViewController = false
        self.containerSwipeNavigationController?.shouldShowLeftViewController = false
        self.containerSwipeNavigationController?.shouldShowBottomViewController = false
        
        // Hide buttons
        self.undoButton.isHidden = true
        self.completeButton.isHidden = true
        self.drawButton.isHidden = true

        // Add shadows for buttons && bring view to front (last line)
        let buttons = [self.saveButton,
                       self.textButton,
                       self.leaveButton,
                       self.completeButton] as [Any]
        for b in buttons {
            // MARK: - RPExtensions
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer)
            self.stillPhoto.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.swipeView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure button states
        configureButtonState(shouldHide: false) { (Bool) in }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearArrays()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(super.didReceiveMemoryWarning())
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    
    // MARK: - RPCaptionView; Function to "wake up" RPCaptionView and bring to front...
    func wakeCaptionView() {
        self.swipeView.addSubview(self.rpCaptionView)
        _ = self.rpCaptionView.becomeFirstResponder()
    }
    
    // MARK: - GPUImage
    // FUNCTION - Generate Filters
    func generateFilters(_ image: UIImage) {
        // Clear array
        self.filteredImages.removeAll(keepingCapacity: false)
        
        if isRearCam! == false {
            // MARK: - GPUImage; Append GPUImageFilters to filters
            self.filters.append(contentsOf: [GPUImageMedianFilter(),
                                             GPUImageToonFilter(),
                                             GPUImagePinchDistortionFilter(),
                                             GPUImageStretchDistortionFilter(),
                                             GPUImageBulgeDistortionFilter()])
        } else {
            // MARK: - GPUImage; Append GPUImageFilters to filters
            self.filters.append(contentsOf: [GPUImageMedianFilter(),
                                             GPUImageMonochromeFilter(),
                                             GPUImageToonFilter()])
        }
        
        // Configure TIME and DAY
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayOfWeek = dayFormatter.string(from: Date())
        
        // TIME FILTER
        let time = UILabel(frame: self.view.frame)
        time.font = UIFont(name: "Futura-Medium", size: 65)
        time.textColor = UIColor.white
        time.text = "\(timeFormatter.string(from: NSDate() as Date))"
        time.textAlignment = .center
        // MARK: - RPExtensions
        time.layer.applyShadow(layer: time.layer)
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        time.layer.render(in: UIGraphicsGetCurrentContext()!)
        let timeFilter = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // DAY FILTER
        let day = UILabel(frame: self.view.frame)
        day.font = UIFont(name: "Avenir-Black", size: 50)
        day.textColor = UIColor.white
        day.text = "\(dayOfWeek)"
        day.textAlignment = .center
        // MARK: - RPExtensions
        day.layer.applyShadow(layer: day.layer)
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        day.layer.render(in: UIGraphicsGetCurrentContext()!)
        let dayFilter = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Append Time and Day filters
        self.filters.append(contentsOf: ["nil", "nil"])
        
        // MARK: - GPUImage; Filter and process images
        for index in 0..<self.filters.count {
            if let gpuFilter = self.filters[index] as? GPUImageFilter {
                let filteredImage = gpuFilter.image(byFilteringImage: image)
                self.filteredImages.append(filteredImage!)
            }
        }
        
        self.filteredImages.append(timeFilter!)
        self.filteredImages.append(dayFilter!)
        
        
        // GEOLOCATION IS NOT DISABLED
        if !currentGeoFence.isEmpty || !temperature.isEmpty || !altitudeFence.isEmpty {
            // LOCATION FILTER
            let city = UILabel(frame: self.view.frame)
            city.textColor = UIColor.white
            city.backgroundColor = UIColor.clear
            city.textAlignment = .center
            city.lineBreakMode = .byWordWrapping
            city.numberOfLines = 0
            // Manipulate font size of CLPlacemark's name attribute
            let formattedString = NSMutableAttributedString()
            _ = formattedString
                .bold("\(currentGeoFence.last!.name!.uppercased())", withFont: UIFont(name: "AvenirNext-Bold", size: 21))
                .normal("\n\(currentGeoFence.last!.locality!), \(currentGeoFence.last!.administrativeArea!)", withFont: UIFont(name: "AvenirNext-Bold", size: 30))
            city.attributedText = formattedString
            // MARK: - RPExtensions
            city.layer.applyShadow(layer: city.layer)
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            city.layer.render(in: UIGraphicsGetCurrentContext()!)
            let cityFilter = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // TEMPERATURE FILTER
            let temperatureLabel = UILabel(frame: self.view.frame)
            temperatureLabel.textColor = UIColor.white
            temperatureLabel.textAlignment = .center
            temperatureLabel.numberOfLines = 0
            // Get Fahrenheit and Celsius Temperatures
            // °F\n\(Int(celsius))°C"
            let fahrenheit = temperature.last!.components(separatedBy: "\n").first!.replacingOccurrences(of: "°F", with: "")
            let celsius = temperature.last!.components(separatedBy: "\n").last!.replacingOccurrences(of: "°C", with: "")
            // Manipulate font size of temperature
            let tempFormattedString = NSMutableAttributedString()
            _ = tempFormattedString
                .bold("\(fahrenheit)", withFont: UIFont(name: "Futura-Bold", size: 60))
                .normal("°F", withFont: UIFont(name: "Futura-Bold", size: 30))
                .bold("\n\(celsius)", withFont: UIFont(name: "Futura-Bold", size: 30))
                .normal("°C", withFont: UIFont(name: "Futura-Bold", size: 21))
            temperatureLabel.attributedText = tempFormattedString
            // MARK: - RPExtensions
            temperatureLabel.layer.applyShadow(layer: temperatureLabel.layer)
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            temperatureLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
            let tempFilter = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // ALTITUDE FILTER
            let altitudeLabel = UILabel(frame: self.view.frame)
            altitudeLabel.textColor = UIColor.white
            altitudeLabel.textAlignment = .center
            altitudeLabel.numberOfLines = 0
            // Manipulate font size of altitude filter
            let altitudeFormattedString = NSMutableAttributedString()
            _ = altitudeFormattedString
                .bold("\(round(altitudeFence.last!/0.3048))", withFont: UIFont(name: "Futura-Medium", size: 60))
                .normal(" ft", withFont: UIFont(name: "Futura-Bold", size: 30))
                .bold("\n\(round(altitudeFence.last!))", withFont: UIFont(name: "Futura-Medium", size: 30))
                .normal(" m", withFont: UIFont(name: "Futura-Bold", size: 21))
            altitudeLabel.attributedText = altitudeFormattedString
            // MARK: - RPExtensions
            altitudeLabel.layer.applyShadow(layer: altitudeLabel.layer)
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            altitudeLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
            let altitudeFilter = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Append Time and Day filters
            self.filters.append(contentsOf: ["nil", "nil", "nil"])
            
            // MARK: - GPUImage; Filter and process images
            for index in 0..<self.filters.count {
                if let gpuFilter = self.filters[index] as? GPUImageFilter {
                    let filteredImage = gpuFilter.image(byFilteringImage: image)
                    self.filteredImages.append(filteredImage!)
                }
            }
            
            self.filteredImages.append(cityFilter!)
            self.filteredImages.append(tempFilter!)
            self.filteredImages.append(altitudeFilter!)
        }
        
        // MARK: - SwipeView
        swipeView.dataSource = self
        swipeView.delegate = self
        swipeView.isWrapEnabled = true
    }

    
}
