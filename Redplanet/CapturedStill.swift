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

import OneSignal
import SDWebImage
import SVProgressHUD
import SwipeNavigationController


// Array to hold user's location
var currentGeoFence = [CLPlacemark]()
var temperature = [String]()


/*
 UIViewController class that allows users to filter and edit their photo-moments before sharing them. When red arrow button is tapped,
 this class pushes to "ShareWith.swift" for sharing options
 */

class CapturedStill: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate, SwipeNavigationControllerDelegate {
    
    // MARK: - Class Variable
    var stillImage: UIImage?

    // MARK: - SnapSliderFilters
    let filterView = SNSlider(frame: UIScreen.main.bounds)
    var data:[SNFilter] = []
    
    // MARK: - InstaCaptionContainer
    let captionContainer = RPCaptionView(frame: UIScreen.main.bounds)
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
            UIImageWriteToSavedPhotosAlbum(SNUtils.screenShot(self.stillPhoto)!, self, nil, nil)
            // MARK: - SVProgressHUD
            SVProgressHUD.setFont(UIFont(name: "AvenirNext-Demibold", size: 12))
            SVProgressHUD.showSuccess(withStatus: "Saved Photo!")
        })
    }
    
    @IBOutlet weak var drawButton: UIButton!
    @IBAction func draw(_ sender: Any) {
        // Disable filterView
        self.filterView.isUserInteractionEnabled = false
        self.completeButton.isHidden = false
        self.undoButton.isHidden = false
    }
    
    @IBOutlet weak var textButton: UIButton!
    @IBAction func text(_ sender: Any) {
        self.wakeInstaCaptionContainer()
    }
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func continueButton(_ sender: Any) {
        // MOMENT
        if chatCamera == false {
            // Create PFObject
            let itmPhoto = PFObject(className: "Posts")
            itmPhoto["byUser"] = PFUser.current()!
            itmPhoto["byUsername"] = PFUser.current()!.username!
            itmPhoto["contentType"] = "itm"
            itmPhoto["saved"] = false
            itmPhoto["textPost"] = self.captionContainer.textView.text
            itmPhoto["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
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
            chats["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
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
            clearArrays()
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // MARK: - SwipeNavigationController
            self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        }
 
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
    
    
    // FUNCTION - Clear arrays
    open func clearArrays() {
        currentGeoFence.removeAll(keepingCapacity: false)
        temperature.removeAll(keepingCapacity: false)
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
        
        // Enable interaction with stillPhoto for filterView
        self.stillPhoto.isUserInteractionEnabled = true
        // Set textButton title
        self.textButton.setTitle("Aa", for: .normal)

        // MARK: - InstaCaptionContainer
        self.captionContainer.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(wakeInstaCaptionContainer))
        
        // MARK: - SnapSliderFilters
        self.setupSlider()

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
            self.filterView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let buttons = [leaveButton,
                       saveButton,
                       textButton,
                       completeButton] as [Any]
        
        for b in buttons {
            let buttonView = (b as AnyObject) as! UIView
            UIView.animate(withDuration: 0.3,
                               animations: {
                                buttonView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            },
                               completion: { _ in
                                UIView.animate(withDuration: 0.3) {
                                    buttonView.transform = .identity
                                }
            })
        }
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
    
    
    
    // MARK: - InstaCaptionContainer; Function to "wake up" InstaCaptionContainer and bring to front...
    func wakeInstaCaptionContainer() {
        self.captionContainer.configurate()
        self.filterView.addSubview(self.captionContainer)
//        _ = self.captionContainer.becomeFirstResponder()
    }
    
    
    // FUNCTION - Setup SnapSliderFilters
    func setupSlider() {
        // Setup slider
        self.stillPhoto.image = self.stillImage!
        self.createData(self.stillImage!)
        self.filterView.dataSource = self
        self.filterView.isUserInteractionEnabled = true
        self.filterView.isMultipleTouchEnabled = true
        self.filterView.isExclusiveTouch = false
        self.filterView.addGestureRecognizer(tapGesture)
        self.stillPhoto.addSubview(filterView)
        self.filterView.reloadData()
    }
    
    
    //MARK: Functions
    fileprivate func createData(_ image: UIImage) {

        // Configure TIME and DAY
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayOfWeek = dayFormatter.string(from: Date())
        
        // I TIME STAMP
        let time = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height/3))
        time.font = UIFont(name: "AvenirNext-Demibold", size: 60)
        time.textColor = UIColor.white
        time.layer.applyShadow(layer: time.layer)
        time.text = "\(timeFormatter.string(from: NSDate() as Date))"
        time.textAlignment = .center
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        time.layer.render(in: UIGraphicsGetCurrentContext()!)
        let timeStamp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // II DAY
        let day = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height/3))
        day.font = UIFont(name: "GillSans-Bold", size: 60)
        day.textColor = UIColor.white
        day.layer.applyShadow(layer: day.layer)
        day.text = "\(dayOfWeek)"
        day.textAlignment = .center
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        day.layer.render(in: UIGraphicsGetCurrentContext()!)
        let dayStamp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // III RED FILTER
        let red = UIView()
        red.backgroundColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        red.alpha = 0.25
        red.frame = self.view.bounds
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        red.layer.render(in: UIGraphicsGetCurrentContext()!)
        let redFilter = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        
        // IV "Me, Myself, and I"
        let me = UIImageView(frame: self.view.bounds)
        me.contentMode = .scaleAspectFill
        if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            me.sd_setImage(with: URL(string: proPic.url!))
        } else {
            me.image = UIImage(named: "GenderNeutralUser")
        }
        me.alpha = 0.25
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        me.layer.render(in: UIGraphicsGetCurrentContext()!)
        let meFilter = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        
        /*
         (0) OG Photo
         (1) Instant
         (2) Chrome
         (3) Halftone
         (4) Noir
         
         (5) Red
         (6) Time
         (7) Day
         
         (8) CITY
         (9) TEMP
         (10) ME
         (11)
         (12)
        */
        
        var rpFilters = ["nil",
                         "CIPhotoEffectInstant",
                         "CIPhotoEffectChrome",
                         "CIPhotoEffectNoir",
                         "CICMYKHalftone"]
        
        // Append data accordingly
        if currentGeoFence.isEmpty || temperature.isEmpty {
        // GEOLOCATION DISABLED ==================================================
            // Append filters
            rpFilters.append(contentsOf:
                            ["nil",
                            "nil",
                            "nil",
                            "nil"])
            SNFilter.filterIdentities.append(contentsOf: rpFilters)
            self.data = SNFilter.generateFilters(SNFilter(frame: self.view.frame, withImage: image), filters: SNFilter.filterIdentities)
            // Red
            self.data[5].addSticker(SNSticker(frame: self.view.bounds, image: redFilter!, atZPosition: 0))
            // Time
            self.data[6].addSticker(SNSticker(frame: CGRect(x: 0, y: self.view.bounds.height-self.view.bounds.height/3, width: self.view.bounds.width, height: self.view.bounds.height), image: timeStamp!, atZPosition: 0))
            // Day
            self.data[7].addSticker(SNSticker(frame: CGRect(x: 0, y: self.view.bounds.height-self.view.bounds.height/3, width: self.view.bounds.width, height: self.view.bounds.height), image: dayStamp!, atZPosition: 0))
            // Profile Photo
            self.data[10].addSticker(SNSticker(frame: self.view.bounds, image: meFilter!, atZPosition: 0))
            
        } else {
        // GEOLOCATION ENABLED ===================================================

            // IV AREA: "City, State"
            let city = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height/3))
            city.textColor = UIColor.white
            city.backgroundColor = UIColor.clear
            city.textAlignment = .center
            city.lineBreakMode = .byWordWrapping
            city.numberOfLines = 0
            // Manipulate font size of CLPlacemark's name attribute
            let formattedString = NSMutableAttributedString()
            _ = formattedString.bold("\(currentGeoFence.last!.name!.uppercased())", withFont: UIFont(name: "AvenirNext-Bold", size: 30)).normal("\n\(currentGeoFence.last!.locality!), \(currentGeoFence.last!.administrativeArea!)", withFont: UIFont(name: "AvenirNext-Bold", size: 21))
            city.attributedText = formattedString
            city.layer.applyShadow(layer: city.layer)
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            city.layer.render(in: UIGraphicsGetCurrentContext()!)
            let cityStamp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // V TEMERPATURE
            let temp = UILabel(frame: self.view.bounds)
            temp.font = UIFont(name: "Futura-Bold", size: 50)
            temp.textColor = UIColor.white
            temp.textAlignment = .center
            temp.numberOfLines = 0
            temp.text = temperature.last!
            temp.layer.applyShadow(layer: temp.layer)
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            temp.layer.render(in: UIGraphicsGetCurrentContext()!)
            let tempFilter = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // Append filters
            rpFilters.append(contentsOf: ["nil",
                                          "nil",
                                          "nil",
                                          "nil",
                                          "nil",
                                          "nil"])
            SNFilter.filterIdentities.append(contentsOf: rpFilters)
            self.data = SNFilter.generateFilters(SNFilter(frame: self.view.frame, withImage: image), filters: SNFilter.filterIdentities)
            // Red
            self.data[5].addSticker(SNSticker(frame: self.view.bounds, image: redFilter!, atZPosition: 0))
            // Time
            self.data[6].addSticker(SNSticker(frame: CGRect(x: 0, y: self.view.bounds.height-self.view.bounds.height/3, width: self.view.bounds.width, height: self.view.bounds.height), image: timeStamp!, atZPosition: 0))
            // Day
            self.data[7].addSticker(SNSticker(frame: CGRect(x: 0, y: self.view.bounds.height-self.view.bounds.height/3, width: self.view.bounds.width, height: self.view.bounds.height), image: dayStamp!, atZPosition: 0))
            // Location
            self.data[8].addSticker(SNSticker(frame: CGRect(x: 0, y: self.view.bounds.height-self.view.bounds.height/3, width: self.view.bounds.width, height: self.view.bounds.height), image: cityStamp!, atZPosition: 0))
            // Temperature
            self.data[9].addSticker(SNSticker(frame: self.view.bounds, image: tempFilter!, atZPosition: 0))
            // Profile Photo
            self.data[10].addSticker(SNSticker(frame: self.view.bounds, image: meFilter!, atZPosition: 0))
        }
    }

    // UPDATE NEW PICTURE
    fileprivate func updatePicture(_ newImage: UIImage) {
        createData(newImage)
        self.filterView.reloadData()
    }

}


//MARK: - Extension SNSlider DataSource
/*
 MARK: - CapturedStill Extension; SNSliderDataSource Method
 Used to configure image data when processing filters
 */
extension CapturedStill: SNSliderDataSource {
    
    func numberOfSlides(_ slider: SNSlider) -> Int {
        return data.count
    }
    
    func slider(_ slider: SNSlider, slideAtIndex index: Int) -> SNFilter {
        return data[index]
    }
    
    func startAtIndex(_ slider: SNSlider) -> Int {
        return 0
    }
}


