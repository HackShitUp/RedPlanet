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

import SwipeNavigationController
import OneSignal
import SDWebImage

// UIImage to hold captured photo
var stillImages = [UIImage]()

class CapturedStill: UIViewController, UINavigationControllerDelegate, SwipeViewDelegate, SwipeViewDataSource {
    
    // MARK: - SNTextField
    let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    let tapGesture = UITapGestureRecognizer()
    
    // MARK: - SwipeView
    @IBOutlet weak var filterView: SwipeView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var stillPhoto: PFImageView!
    @IBOutlet weak var leaveButton: UIButton!
    @IBAction func dismissVC(_ sender: Any) {
        print("FIRED")
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
            newsfeeds["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
            newsfeeds.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Clear arrray
                    stillImages.removeAll(keepingCapacity: false)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Send Notification
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                    
                    // Show bottom
                    self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Clear arrray
                    stillImages.removeAll(keepingCapacity: false)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Send Notification
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                    
                    
                }
            })

            
        } else {
            // Chat
            let chat = PFObject(className: "Chats")
            chat["sender"] = PFUser.current()!
            chat["senderUsername"] = PFUser.current()!.username!
            chat["receiver"] = chatUserObject.last!
            chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chat["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(SNUtils.screenShot(self.stillPhoto)!, 0.5)!)
            chat["read"] = false
            chat.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
                    // Send Push Notification to user
                    // Handle optional chaining
                    if chatUserObject.last!.value(forKey: "apnsId") != nil {
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
                    }
                    
                    // Make false
                    chatCamera = false
                    
                    // Reload chats
                    NotificationCenter.default.post(name: rpChat, object: nil)
                    
                    // Pop 2 view controllers
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
                    // Reload chats
                    NotificationCenter.default.post(name: rpChat, object: nil)
                    
                    // Pop 2 view controllers
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
                }
            }
            
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set image
        self.stillPhoto.image = stillImages.last!
        
        // Add photo to stillPhoto
        self.stillPhoto.addSubview(self.filterView)
        
        // Enable UIImageView for SnapSliderFilters
        self.stillPhoto.isUserInteractionEnabled = true

        // MARK: - SNTextField
        setupTextField()
        tapGesture.addTarget(self, action: #selector(handleTap))

        // MARK:- SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowRightViewController = false
        self.containerSwipeNavigationController?.shouldShowLeftViewController = false
        self.containerSwipeNavigationController?.shouldShowBottomViewController = false
        
        // Hide buttons
        self.undoButton.isHidden = true
        self.completeButton.isHidden = true
        
        // MARK: - SwipeView
        self.filterView.delegate = self                 // delegate
        self.filterView.dataSource = self               // dataSource
        self.filterView.isPagingEnabled = true          // stifle scroll at index
        self.filterView.isWrapEnabled = true            // reset to index[0]
        self.filterView.bounces = true                  // bounce

        // Add shadows for buttons && bring view to front (last line)
        let buttons = [self.saveButton,
                       self.textButton,
                       self.drawButton,
                       self.leaveButton,
                       self.completeButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
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
    
    // MARK: - SwipeView
    func numberOfItems(in swipeView: SwipeView) -> Int {
        //return the total number of items in the carousel
        return 5
    }
    
    func swipeView(_ swipeView: SwipeView, viewForItemAt index: Int, reusing view: UIView) -> UIView? {
        
        view.addGestureRecognizer(tapGesture)
        
        if index == 0 {
            view.subviews.forEach({ $0.removeFromSuperview() })
            view.backgroundColor = UIColor.clear
        } else if index == 1 {
            view.subviews.forEach({ $0.removeFromSuperview() })
            // Configure time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let time = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            time.font = UIFont(name: "AvenirNextCondensed-Demibold", size: 70)
            time.textColor = UIColor.white
            time.layer.shadowColor = UIColor.black.cgColor
            time.layer.shadowOffset = CGSize(width: 1, height: 1)
            time.layer.shadowRadius = 3
            time.layer.shadowOpacity = 0.5
            time.text = "\(timeFormatter.string(from: NSDate() as Date))"
            time.textAlignment = .center
            UIGraphicsBeginImageContextWithOptions(self.stillPhoto.frame.size, false, 0.0)
            time.layer.render(in: UIGraphicsGetCurrentContext()!)
            view.backgroundColor = UIColor.clear
            view.addSubview(time)
        } else if index == 2 {
            view.subviews.forEach({ $0.removeFromSuperview() })
            view.backgroundColor = UIColor(patternImage: UIImage(named: "HardLight")!)
        } else if index == 3 {
            view.subviews.forEach({ $0.removeFromSuperview() })
            view.backgroundColor = UIColor(patternImage: UIImage(named: "Cotton")!)
        } else if index == 4 {
            view.subviews.forEach({ $0.removeFromSuperview() })
            
            let openGLContext = EAGLContext(api: .openGLES2)
            let context = CIContext(eaglContext: openGLContext!)
            let cgImage = stillImages.last!.cgImage
            let coreImage = CIImage(cgImage: cgImage!)
            
            let filter = CIFilter(name: "CIComicEffect")
            filter?.setValue(coreImage, forKey: kCIInputImageKey)
//            filter?.setValue(1, forKey: kCIInputIntensityKey)
            var result: UIImage?
            if let output = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
                let cgimgresult = context.createCGImage(output, from: output.extent)
                result = UIImage(cgImage: cgimgresult!)
            }
            
            // 7 - set filtered image to array
            self.view.backgroundColor = UIColor(patternImage: result!)
            
        }

        return view
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView) -> CGSize {
        return swipeView.frame.size
    }
    
    
    
    // MARK: - SNTextField
    fileprivate func setupTextField() {
        self.view.addSubview(textField)
        self.tapGesture.delegate = self
        self.filterView.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardTypeChanged(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }

}


//MARK: - Extension Gesture Recognizer Delegate and touch Handler for TextField
extension CapturedStill: UIGestureRecognizerDelegate {
    func handleTap() {
        self.textField.handleTap()
    }
}
