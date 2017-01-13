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


import jot
import OneSignal


// UIImage to hold captured photo
var stillImages = [UIImage]()

class CapturedStill: UIViewController, UINavigationControllerDelegate, CLImageEditorDelegate, JotViewControllerDelegate {
    
    
    // MARK: SnapSliderFilters
    fileprivate let slider = SNSlider(frame: CGRect(origin: CGPoint.zero, size: SNUtils.screenSize))
    fileprivate let textField = SNTextField(y: SNUtils.screenSize.height/2, width: SNUtils.screenSize.width, heightOfScreen: SNUtils.screenSize.height)
    fileprivate let tapGesture = UITapGestureRecognizer()
    fileprivate var data:[SNFilter] = []
    
    // MARK: - jot
    var jotViewController: JotViewController!
    
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var stillPhoto: PFImageView!
    @IBOutlet weak var leaveButton: UIButton!
    @IBAction func dismissVC(_ sender: Any) {
        // Remove last
        stillImages.removeLast()
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveButton(_ sender: Any) {
        // Save photo
        UIView.animate(withDuration: 0.5) { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
        }, completion: nil)
        
        UIImageWriteToSavedPhotosAlbum(SNUtils.screenShot(self.stillPhoto)!, self, nil, nil)
    }
    
    @IBOutlet weak var editButton: UIButton!
    @IBAction func editButton(_ sender: Any) {
        // DRAWING
        initializeJot()
        switchToDrawMode()
        self.jotViewController.drawingColor = UIColor.magenta
    }
    
    @IBOutlet weak var textButton: UIButton!
    @IBAction func text(_ sender: Any) {
        initializeJot()
    }
    
    
    // MARK: - jot
    func switchToDrawMode() {
        self.jotViewController.state = .drawing
    }
    
    func switchToTextMode() {
        self.jotViewController.state = .text
    }
    
    func switchToTextEditMode() {
        self.jotViewController.state = .editingText
    }
    
    // Custom function to initize JOT
    func initializeJot() {
        
        // Disable slider?

        self.jotViewController = JotViewController()
        self.jotViewController.delegate = self
        self.addChildViewController(self.jotViewController)
        self.stillPhoto.addSubview(self.jotViewController.view)
        self.jotViewController.didMove(toParentViewController: self)
        self.jotViewController.view.frame = self.view.frame

    }
    
    // Function to undo
    func undoJot() {
        
    }
    
    func completeJot() {
        print("TAPPED HERE")
        // Set image
        self.stillPhoto.image = SNUtils.screenShot(self.stillPhoto)!
        // Remove jot
        self.jotViewController.view.removeFromSuperview()
        
    }
    
    
    // MARK: - CLImageEditorDelegate
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.stillPhoto.image = image
        
        // Dismiss VC
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
                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Clear arrray
                    stillImages.removeAll(keepingCapacity: false)
                    
                    // Re-enable buttons
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Send Notification
                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
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
                                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
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

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide enavigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set image
        self.stillPhoto.image = stillImages.last!

        // Add tap method for configuration method
//        tapGesture.addTarget(self, action: #selector(handleTap))
        tapGesture.addTarget(self, action: #selector(initializeJot))
        setupSlider()
        setupTextField()
        self.stillPhoto.isUserInteractionEnabled = true
        
        // Add tap methods for undo and complete
        // Undo button
        let undoTap = UITapGestureRecognizer(target: self, action: #selector(undoJot))
        undoTap.numberOfTapsRequired = 1
        self.undoButton.isUserInteractionEnabled = true
        self.undoButton.addGestureRecognizer(undoTap)
        // Done button
        let doneTap = UITapGestureRecognizer(target: self, action: #selector(completeJot))
        doneTap.numberOfTapsRequired = 1
        self.completeButton.isUserInteractionEnabled = true
        self.completeButton.addGestureRecognizer(doneTap)
        
        
        // Add shadows for...
        // 1) Save button
        self.saveButton.layer.shadowColor = UIColor.black.cgColor
        self.saveButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.saveButton.layer.shadowRadius = 5
        self.saveButton.layer.shadowOpacity = 1.0
        // 2) Text button
        self.textButton.layer.shadowColor = UIColor.black.cgColor
        self.textButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.textButton.layer.shadowRadius = 5
        self.textButton.layer.shadowOpacity = 1.0
        // 3) Edit button
        self.editButton.layer.shadowColor = UIColor.black.cgColor
        self.editButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.editButton.layer.shadowRadius = 5
        self.editButton.layer.shadowOpacity = 1.0
        
        // Bring buttons to front
        self.view.bringSubview(toFront: self.completeButton)
        self.view.bringSubview(toFront: self.leaveButton)
        self.view.bringSubview(toFront: self.continueButton)
        self.view.bringSubview(toFront: self.undoButton)
        self.view.bringSubview(toFront: self.editButton)
        self.view.bringSubview(toFront: self.textButton)
        self.view.bringSubview(toFront: self.saveButton)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(super.didReceiveMemoryWarning())
    }
    
    //MARK: Setup
    fileprivate func setupSlider() {
        // Setup slider
        self.createData(stillImages.last!)
        self.slider.dataSource = self
        self.slider.isUserInteractionEnabled = true
        self.slider.isMultipleTouchEnabled = true
        self.slider.isExclusiveTouch = false
        self.stillPhoto.addSubview(slider)
        self.slider.reloadData()
    }
    
    fileprivate func setupTextField() {
        // Add it to the photo
        self.stillPhoto.addSubview(textField)
        self.tapGesture.delegate = self
        self.slider.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self.textField, selector: #selector(SNTextField.keyboardTypeChanged(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    
    //MARK: Functions
    fileprivate func createData(_ image: UIImage) {
        self.data = SNFilter.generateFilters(SNFilter(frame: self.slider.frame, withImage: image), filters: SNFilter.filterNameList)
        self.data[1].addSticker(SNSticker(frame: CGRect(x: 195, y: 30, width: 90, height: 90), image: UIImage(named: "Checked Filled-100")!))
        self.data[2].addSticker(SNSticker(frame: CGRect(x: 30, y: 100, width: 250, height: 250), image: UIImage(named: "Newsfeed(1)")!))
        self.data[3].addSticker(SNSticker(frame: CGRect(x: 20, y: 00, width: 140, height: 140), image: UIImage(named: "Chat Filled-50")!))
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


