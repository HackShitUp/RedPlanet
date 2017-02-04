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

class CapturedStill: UIViewController, UINavigationControllerDelegate, CLImageEditorDelegate {
    
    // MARK: SnapSliderFilters
    fileprivate let slider = SNSlider(frame: CGRect(origin: CGPoint.zero, size: SNUtils.screenSize))
    fileprivate let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    fileprivate let tapGesture = UITapGestureRecognizer()
    fileprivate var data:[SNFilter] = []

    
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
    
    @IBOutlet weak var editButton: UIButton!
    @IBAction func editButton(_ sender: Any) {
        if chatCamera == false {
            // Moment
            // Present CLImageEditor
            let editor = CLImageEditor(image: SNUtils.screenShot(self.stillPhoto)!)
            // Disable tools: rotate, clip, and resize
            let rotateTool = editor?.toolInfo.subToolInfo(withToolName: "CLRotateTool", recursive: false)
            let cropTool = editor?.toolInfo.subToolInfo(withToolName: "CLClippingTool", recursive: false)
            let resizeTool = editor?.toolInfo.subToolInfo(withToolName: "CLResizeTool", recursive: false)
            rotateTool?.available = false
            cropTool?.available = false
            resizeTool?.available = false
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.pushViewController(editor!, animated: false)
        } else {
            // CHAT
            // Present CLImageEditor
            let editor = CLImageEditor(image: SNUtils.screenShot(self.stillPhoto)!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.pushViewController(editor!, animated: false)
        }
    }
    
    @IBOutlet weak var textButton: UIButton!
    @IBAction func text(_ sender: Any) {
        self.handleTap()
    }
    
    
    // MARK: - CLImageEditorDelegate
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Append image
        stillImages.append(image)
        // MARK: - SnapSliderFilters
        setupSlider()
        setupTextField()
        tapGesture.addTarget(self, action: #selector(handleTap))
        
        // Pop VC
        _ = editor.navigationController?.popViewController(animated: false)
    }
    
    // Cancel editing
    func imageEditorDidCancel(_ editor: CLImageEditor!) {
        // Dismiss VC
        editor.dismiss(animated: false, completion: nil)
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
        
        // MARK: - SnapSliderFilters
        setupSlider()
        setupTextField()
        tapGesture.addTarget(self, action: #selector(handleTap))
        
        // Enable UIImageView for SnapSliderFilters
        self.stillPhoto.isUserInteractionEnabled = true
        
        // MARK:- SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowRightViewController = false
        self.containerSwipeNavigationController?.shouldShowLeftViewController = false
        self.containerSwipeNavigationController?.shouldShowBottomViewController = false
        
        // Hide buttons
        self.editButton.isHidden = true
        self.undoButton.isHidden = true
        self.completeButton.isHidden = true
        
//        let completeTap = UITapGestureRecognizer(target: self, action: #selector(completeJot))
//        completeTap.numberOfTapsRequired = 1
//        self.completeButton.isUserInteractionEnabled = true
//        self.completeButton.addGestureRecognizer(completeTap)
        
//        let undoTap = UITapGestureRecognizer(target: self, action: #selector(completeJot))
//        undoTap.numberOfTapsRequired = 1
//        self.undoButton.isUserInteractionEnabled = true
//        self.undoButton.addGestureRecognizer(undoTap)
        
        // Add shadows for buttons && bring view to front (last line)
        let buttons = [self.saveButton,
                       self.textButton,
                       self.editButton,
                       self.leaveButton,
                       self.completeButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.shadowColor = UIColor.black.cgColor
            (b as AnyObject).layer.shadowOffset = CGSize(width: 1, height: 1)
            (b as AnyObject).layer.shadowRadius = 3
            (b as AnyObject).layer.shadowOpacity = 0.5
            self.view.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.stillPhoto.bringSubview(toFront: (b as AnyObject) as! UIView)
            self.slider.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(textField)
        UIView.setAnimationsEnabled(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIView.setAnimationsEnabled(true)
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
    
    //MARK: Setup
    fileprivate func setupSlider() {
        // Setup slider
        self.stillPhoto.image = stillImages.last!
        self.createData(self.stillPhoto.image!)
        self.slider.dataSource = self
        self.slider.isUserInteractionEnabled = true
        self.slider.isMultipleTouchEnabled = true
        self.slider.isExclusiveTouch = false
        self.stillPhoto.addSubview(slider)
        self.slider.reloadData()
    }
    
    fileprivate func setupTextField() {
        self.slider.addSubview(textField)
        self.tapGesture.delegate = self
        self.slider.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardTypeChanged(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    //MARK: Functions
    fileprivate func createData(_ image: UIImage) {

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
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Add filter
        self.data = SNFilter.generateFilters(SNFilter(frame: self.slider.frame, withImage: image), filters: SNFilter.filterNameList)
        self.data[1].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.stillPhoto.frame.size.width, height: self.stillPhoto.frame.size.height), image: img!, atZPosition: 0))
        self.data[2].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.stillPhoto.frame.size.width, height: self.stillPhoto.frame.size.height), image: UIImage(named: "HardLight")!, atZPosition: 2))
        self.data[3].addSticker(SNSticker(frame: CGRect(x: 0, y: 0, width: self.stillPhoto.frame.size.width, height: self.stillPhoto.frame.size.height), image: UIImage(named: "Cotton")!, atZPosition: 2))
    }
    
    fileprivate func updatePicture(_ newImage: UIImage) {
        createData(newImage)
        slider.reloadData()
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


