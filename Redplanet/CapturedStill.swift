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

// UIImage to hold captured photo
var stillImage = [UIImage]()

class CapturedStill: UIViewController, UINavigationControllerDelegate, CLImageEditorDelegate {
    
    
    @IBOutlet weak var stillPhoto: PFImageView!
    @IBOutlet weak var leaveButton: UIButton!
    @IBAction func dismissVC(_ sender: Any) {
        // Remove last
        stillImage.removeLast()
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
        
        UIImageWriteToSavedPhotosAlbum(self.stillPhoto.image!, self, nil, nil)

    }
    
    @IBOutlet weak var editButton: UIButton!
    @IBAction func editButton(_ sender: Any) {
        // If it's a Moment...
        // Disable rotate, crop, and resizing options
        if chatCamera == false {
            // Moment
            // Present CLImageEditor
            let editor = CLImageEditor(image: self.stillPhoto.image!)
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
            let editor = CLImageEditor(image: self.stillPhoto.image!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            self.navigationController?.navigationBar.tintColor = UIColor.black
            self.navigationController?.pushViewController(editor!, animated: false)
        }
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
        
        if chatCamera == false {
            // Moment
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["byUser"] = PFUser.current()!
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["contentType"] = "itm"
            newsfeeds["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.stillPhoto.image!, 0.5)!)
            newsfeeds.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
                    // Send Notification
                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Re-enable buttons
                    self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
                    
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
            chat["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.stillPhoto.image!, 0.5)!)
            chat["read"] = false
            chat.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set image
        self.stillPhoto.image = stillImage.last!

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide enavigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
