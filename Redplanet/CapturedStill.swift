//
//  CapturedStill.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import OneSignal
import SDWebImage
import SwipeNavigationController

// UIImage to hold captured photo
var stillImages = [UIImage]()
// User's city and state
var cityState = [String]()


extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 0.50)
    }
}

class CapturedStill: UIViewController, UINavigationControllerDelegate, SwipeNavigationControllerDelegate {
    
    // MARK: - SnapSliderFilters
    let filterView = SNSlider(frame: UIScreen.main.bounds)
    let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    let tapGesture = UITapGestureRecognizer()
    var data:[SNFilter] = []
    
    var label: UILabel!
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var stillPhoto: PFImageView!
    @IBOutlet weak var leaveButton: UIButton!
    
    @IBAction func dismissVC(_ sender: Any) {
        // Remove last
        if !stillImages.isEmpty {
            stillImages.removeLast()
        }
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveButton(_ sender: Any) {
        DispatchQueue.main.async {
            // Save photo
            UIView.animate(withDuration: 0.5) { () -> Void in
                self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            }
            UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
            UIImageWriteToSavedPhotosAlbum(SNUtils.screenShot(self.stillPhoto)!, self, nil, nil)
        }
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
        self.handleTap()
    }
    
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func continueButton(_ sender: Any) {
        // Disable button
        self.continueButton.isUserInteractionEnabled = false
        
        if chatCamera == false {
            // Moment
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["contentType"] = "itm"
            newsfeeds["saved"] = false
            newsfeeds["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
            newsfeeds.saveInBackground()
            
            // MARK: - HEAP
            Heap.track("SharedMoment", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Clear arrray
            stillImages.removeAll(keepingCapacity: false)
            // Send Notification
            NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
            // Show bottom
            self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            
        } else {
            // Chat
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chats["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
            chats["mediaType"] = "itm"
            chats["read"] = false
            chats.saveInBackground()
            
            // Send Push Notification to user
            // Handle optional chaining
            // Handle optional chaining
            if chatUserObject.last!.value(forKey: "apnsId") != nil {
                // MARK: - OneSignal
                // Send push notification
                OneSignal.postNotification(
                    ["contents":
                        ["en": "from \(PFUser.current()!.username!.uppercased())"],
                     "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                     "ios_badgeType": "Increase",
                     "ios_badgeCount": 1
                    ]
                )
            }
            
            // Re-enable buttons
            self.continueButton.isUserInteractionEnabled = true
            // Make false
            chatCamera = false
            // Clear arrray
            stillImages.removeAll(keepingCapacity: false)
            // Reload data
            NotificationCenter.default.post(name: rpChat, object: nil)
            // Push to bottom
            DispatchQueue.main.async {
                self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
            }
        }
    }
    
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        if position == .bottom {
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
        // Delegate
    }

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

        // MARK: - SnapSliderFilters
        self.setupSlider()
        self.setupTextField()
        tapGesture.addTarget(self, action: #selector(handleTap))

        // MARK:- SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowRightViewController = false
        self.containerSwipeNavigationController?.shouldShowLeftViewController = false
        self.containerSwipeNavigationController?.shouldShowBottomViewController = false
        self.containerSwipeNavigationController?.delegate = self
        
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
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.stillPhoto.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.filterView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stillImages.removeAll(keepingCapacity: false)
        NotificationCenter.default.removeObserver(textField)
        UIView.setAnimationsEnabled(true)
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
    
    
    func setupSlider() {
        // Setup slider
        self.stillPhoto.image = stillImages.last!
        self.createData(stillImages.last!)
        self.filterView.dataSource = self
        self.filterView.isUserInteractionEnabled = true
        self.filterView.isMultipleTouchEnabled = false
        self.filterView.isExclusiveTouch = false
        self.stillPhoto.addSubview(filterView)
        self.filterView.reloadData()
    }
    
    
    //MARK: Functions
    fileprivate func createData(_ image: UIImage) {
        
        // (1) Configure time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        let time = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        time.font = UIFont(name: "Futura-Medium", size: 70)
        time.textColor = UIColor.white
        time.layer.shadowColor = UIColor.black.cgColor
        time.layer.shadowOffset = CGSize(width: 1, height: 1)
        time.layer.shadowRadius = 3
        time.layer.shadowOpacity = 0.5
        time.text = "\(timeFormatter.string(from: NSDate() as Date))"
        time.textAlignment = .center
        UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
        time.layer.render(in: UIGraphicsGetCurrentContext()!)
        let timeStamp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Clear filters
        SNFilter.filterIdentities.removeAll(keepingCapacity: false)
        
        // Append data accordingly
        if cityState.isEmpty {
        // GEOLOCATION ENABLED
            let filterAS =  ["nil",
                             "nil",
                             "nil",
                             "nil",
                             "CIPhotoEffectNoir",
                             "CICMYKHalftone",
                             "CIPhotoEffectInstant",
                             "CIPhotoEffectChrome"]
            SNFilter.filterIdentities.append(contentsOf: filterAS)
            // Add filter
            self.data = SNFilter.generateFilters(SNFilter(frame: self.view.frame, withImage: image), filters: SNFilter.filterIdentities)
            self.data[1].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: timeStamp!, atZPosition: 0))
            self.data[2].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: UIImage(named: "Dope")!, atZPosition: 2))
            self.data[3].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: UIImage(named: "Red")!, atZPosition: 2))
        } else {
        // GEOLOCATION DISABLED
            // (2) Configure City, State
            let city = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height/6))
            city.font = UIFont(name: "AvenirNextCondensed-Medium", size: 40)
            city.textColor = UIColor.white
            city.backgroundColor = UIColor.randomColor()
            city.text = "\(cityState.last!)"
            city.textAlignment = .center
            city.lineBreakMode = .byWordWrapping
            city.numberOfLines = 0
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            city.layer.render(in: UIGraphicsGetCurrentContext()!)
            let cityStamp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let filterBS = ["nil",
                            "nil",
                            "nil",
                            "nil",
                            "nil",
                            "CIPhotoEffectNoir",
                            "CICMYKHalftone",
                            "CIPhotoEffectInstant",
                            "CIPhotoEffectChrome"]
            SNFilter.filterIdentities.append(contentsOf: filterBS)
            // Add filter
            self.data = SNFilter.generateFilters(SNFilter(frame: self.view.frame, withImage: image), filters: SNFilter.filterIdentities)
            self.data[1].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: timeStamp!, atZPosition: 0))
            self.data[2].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: cityStamp!, atZPosition: 0))
            self.data[3].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: UIImage(named: "Dope")!, atZPosition: 2))
            self.data[4].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height), image: UIImage(named: "Red")!, atZPosition: 2))
        }
        
    }// end creating data
    
    // UPDATE NEW PICTURE
    fileprivate func updatePicture(_ newImage: UIImage) {
        createData(newImage)
        self.filterView.reloadData()
    }
    
    // MARK: - SNTextField
    fileprivate func setupTextField() {
        self.tapGesture.delegate = self
        self.filterView.addSubview(textField)
        self.filterView.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardTypeChanged(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
}


//MARK: - Extension SNSlider DataSource
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

//MARK: - Extension Gesture Recognizer Delegate and touch Handler for TextField
extension CapturedStill: UIGestureRecognizerDelegate {
    func handleTap() {
        self.textField.handleTap()
    }
}

