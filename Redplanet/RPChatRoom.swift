//
//  RPChatRoom.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

import Parse
import ParseUI
import Bolts

import OneSignal
import SDWebImage

// Global variable to hold user's object and username for chats
var chatUserObject = [PFObject]()
var chatUsername = [String]()

// Add Notification to reload data
let rpChat = Notification.Name("rpChat")


/*
 UIViewController class that shows the chats sent to, and or received by the current user and the last value of the global array noted
 above, "chatUserObject". The query checks for any chats sent between the 2 users in descending order (recent to latest), and reverses
 the objects to display the messages from oldest to recent.
 
 The following criteria for messages to be fetched are:
 • Less than 24 hours since the time they were sent.
 • Saved
 
 The class binds the data in "RPChatRoomCell.swift" and "RPChatMediaCell.swift" and their respective UITableViewCells in Storyboard. The
 former class is presented when the chat was solely a message, and the latter class is presented when the chat stores a file (ie: photo).
 
 This class refers to the <Chats> class in the database and distinguishes between which UITableViewCell to show (mentioned previously) via
 the object/row's attribute or column, <contentType> and whether the value, <Message> is undefined or not.
 */

class RPChatRoom: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {
    
    // Variable to hold messageObjects
    var messageObjects = [PFObject]()
    var skipped = [PFObject]()
    // Keyboard frame
    var keyboard = CGRect()
    // Refresher
    var refresher: UIRefreshControl!
    // Set pipeline
    var page: Int = 50
    // Variable to hold UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var innerView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var stickersButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func backButton(_ sender: AnyObject) {
        
        // Reset UITabBarController's UITabBar configurations
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isTranslucent = false
        
        // Set bool
        chatCamera = false
        // Clear arrays
        chatUserObject.removeLast()
        chatUsername.removeLast()
        // Pop view controller
        if self.navigationController?.viewControllers.count == 3 {
            let viewControllers = self.navigationController!.viewControllers as [UIViewController]
            _ = self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
        } else {
            // Pop view controller
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func moreButton(_ sender: Any) {
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)",
                                                      message: "Chats")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Add photo
        dialogController.imageHandler = { (imageView) in
            if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        imageView.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else {
                imageView.image = UIImage(named: "GenderNeutralUser")
            }
            imageView.contentMode = .scaleAspectFill
            return true //must return true, otherwise image won't show.
        }
        
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
            button.layer.masksToBounds = true
        }
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.setTitle("CANCEL", for: [])
            return true
        }
        // Visit Profile button
        dialogController.addAction(AZDialogAction(title: "Visit Profile", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Appned user's object
            otherObject.append(chatUserObject.last!)
            // Append user's username
            otherName.append(chatUsername.last!)
            // Push VC
            let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
            self.navigationController?.pushViewController(otherVC, animated: true)
        }))
        
        // Report Button
        dialogController.addAction(AZDialogAction(title: "Report", handler: { (dialog) -> (Void) in
            
            let alert = UIAlertController(title: "Report",
                                          message: "Please provide your reason for reporting \(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)",
                preferredStyle: .alert)
            
            let report = UIAlertAction(title: "Report", style: .destructive) {
                [unowned self, alert] (action: UIAlertAction!) in
                
                let answer = alert.textFields![0]
                
                // REPORTED
                let report = PFObject(className: "Reported")
                report["byUsername"] = PFUser.current()!.username!
                report["byUser"] = PFUser.current()!
                report["toUsername"] = chatUsername.last!
                report["toUser"] = chatUserObject.last!
                report["forObjectId"] = chatUserObject.last!.objectId!
                report["reason"] = answer.text!
                report.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved report: \(report)")

                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Successfully Reproted \(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)")
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error")
                    }
                })
            }
            
            
            let cancel = UIAlertAction(title: "Cancel",
                                       style: .cancel,
                                       handler: nil)
            
            
            alert.addTextField(configurationHandler: nil)
            alert.addAction(report)
            alert.addAction(cancel)
            alert.view.tintColor = UIColor.black
            dialog.present(alert, animated: true, completion: nil)
        }))
        
        // Block Button
        dialogController.addAction(AZDialogAction(title: "Block", handler: { (dialog) -> (Void) in
            // (1) Block
            let block = PFObject(className: "Blocked")
            block["byUser"] = PFUser.current()!
            block["byUsername"] = PFUser.current()!.username!
            block["toUser"] = chatUserObject.last!
            block["toUsername"] = chatUsername.last!.uppercased()
            block.saveInBackground()
            
            // (2) Delete Follower/Following
            let follower = PFQuery(className: "FollowMe")
            follower.whereKey("follower", equalTo: PFUser.current()!)
            follower.whereKey("following", equalTo: chatUserObject.last!)
            let following = PFQuery(className: "FollowMe")
            following.whereKey("follower", equalTo: chatUserObject.last!)
            following.whereKey("following", equalTo: PFUser.current()!)
            let follow = PFQuery.orQuery(withSubqueries: [follower, following])
            follow.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    PFObject.deleteAll(inBackground: objects!, block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showSuccess(withTitle: "Successfully Blocked \(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)")

                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showError(withTitle: "Network Error")
                        }
                    })
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })

        }))
        
        
        // Show
        dialogController.show(in: self)
    }
    
    @IBAction func showLibrary(_ sender: Any) {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            switch status{
            case .authorized:
                // AUTHORIZED
                // Run in main thread or else it crashes...?
                DispatchQueue.main.async {
                    // Change the font and size of nav bar text
                    if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
                        let navBarAttributesDictionary: [String: AnyObject]? = [
                            NSForegroundColorAttributeName: UIColor.black,
                            NSFontAttributeName: navBarFont
                        ]
                        self.imagePicker.navigationBar.titleTextAttributes = navBarAttributesDictionary
                    }
                    self.imagePicker.navigationController?.navigationBar.whitenBar(navigator: self.imagePicker.navigationController)
                    self.imagePicker.view.roundTopCorners(sender: self.imagePicker.view)
                    self.present(self.imagePicker, animated: true, completion: nil)                    
                }

            case .denied:
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Photos Access Denied",
                                                              message: "Please allow Redplanet access your Photos.")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.layer.borderColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1).cgColor
                    button.backgroundColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1)
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
                    button.tintColor = UIColor(red: 0.74, green: 0.06, blue: 0.88, alpha: 1.0)
                    button.setTitle("CANCEL", for: [])
                    return true
                }
                dialogController.show(in: self)
            default:
                break;
            }
        })
    }
    
    @IBAction func showCamera(_ sender: Any) {
        chatCamera = true
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func showStickers(_ sender: Any) {
        let rpPopUpVC = RPPopUpVC()
        let stickersVC = self.storyboard?.instantiateViewController(withIdentifier: "stickersVC") as! Stickers
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: stickersVC)
        self.present(rpPopUpVC, animated: true, completion: nil)
    }

    // FUNCTION - Compress Video
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    
    // FUNCTION - Refresh data
    func refresh() {
        // End refresher
        self.refresher.endRefreshing()
        // Query Chats
        fetchChats()
    }

    // FUNCTION - Fetch Chats
    func fetchChats() {
        
        // Begin UIRefreshControl
        self.refresher?.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        self.refresher?.beginRefreshing()
        
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKeys(["receiver", "sender"])
        chats.order(byDescending: "createdAt")
        chats.limit = self.page
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                
                // Clear arrays
                self.messageObjects.removeAll(keepingCapacity: false)
                self.skipped.removeAll(keepingCapacity: false)
                
                for object in objects!.reversed() {
                    // Ephemeral Chat
                    let components : NSCalendar.Unit = .hour
                    let difference = (Calendar.current as NSCalendar).components(components, from: object.createdAt!, to: Date(), options: [])
                    // Append objects that have not yet expired AND are saved...
                    if difference.hour! < 24 || object.value(forKey: "saved") as! Bool == true {
                        self.messageObjects.append(object)
                    } else {
                        self.skipped.append(object)
                    }
                }
                
                // Save Read Receipt for lastChat IF the receiver is the current user
                if self.messageObjects.count != 0 && (self.messageObjects.last!.value(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    self.messageObjects.last!["read"] = true
                    self.messageObjects.last!.saveInBackground()
                }
        
                // Reload data and scroll to bottom in main thread if messageObjects isn't empty
                if self.messageObjects.count > 0 {
                    DispatchQueue.main.async(execute: {
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: IndexPath(row: self.messageObjects.count - 1, section: 0), at: .bottom, animated: true)
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
                // End UIRefreshControl
                self.refresher?.endRefreshing()
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        })
    }
    
    @IBAction func sendChat(_ sender: Any) {
        if self.textView.text!.isEmpty {
            // Resign first responder
            self.textView.resignFirstResponder()
        } else {
            // Track when chat was sent
            Heap.track("SentChat", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            // Clear text to prevent sending again and set constant before sending for better UX
            let chatText = self.textView.text!
            // Clear chat
            self.textView.text!.removeAll()

            // Reset UI
            self.resetView()
            
            // Send to Chats
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chats["Message"] = chatText
            chats["read"] = false
            chats["saved"] = false
            chats.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                    // MARK: - RPHelpers; update ChatsQueue, and send push notification
                    let rpHelpers = RPHelpers()
                    rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                    rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                    
                    // Append new PFObject and reload UITableView instead of re-querying data
                    self.messageObjects.append(chats)
                    
                    // Reload data and scroll to bottom in main thread if messageObjects isn't empty
                    if self.messageObjects.count > 0 {
                        DispatchQueue.main.async(execute: {
                            self.tableView.reloadData()
                            self.tableView.scrollToRow(at: IndexPath(row: self.messageObjects.count - 1, section: 0), at: .bottom, animated: true)
                        })
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error - Chat Failed to Send")
                }
            }
        }
    }
    
    // FUNCTION - Reset UI
    func resetView() {
        DispatchQueue.main.async {
            // Get difference to reset UI
            let difference = self.textView.frame.size.height - self.textView.contentSize.height
            
            // Redefine frame of UITextView; textView
            self.textView.frame.origin.y = self.textView.frame.origin.y + difference
            self.textView.frame.size.height = self.textView.contentSize.height
        }
    }

    // FUNCTION - Send Screenshot notification
    func sendScreenshot() {
        // MARK: - RPHelpers; send push notification
        let rpHelpers = RPHelpers()
        rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "screenshot the conversation!")
    }
    
    // FUNCTION - Stylize navigationBar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21) {
            let navBarAttributesDictionary = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: navBarFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)"
        }
        // Extension: UINavigationBar Normalization && hide UITabBar
        self.navigationController?.navigationBar.normalizeBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.tabBarController?.tabBar.isTranslucent = true
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Disable done button
        editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = false
        // Dismiss CLImageEditor
        editor.dismiss(animated: true) {
            
            // Send to Chats
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chats["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(image, 0.5)!)
            chats["contentType"] = "ph"
            chats["read"] = false
            chats["saved"] = false
            chats.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                    // MARK: - RPHelpers; update ChatsQueue, show success, and push notification
                    let rpHelpers = RPHelpers()
                    rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                    rpHelpers.showSuccess(withTitle: "Sent")
                    rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                    
                    // Re-enable done button
                    editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
                    
                    // Clear UITextView
                    self.textView.text!.removeAll()
                    // Dismiss view controller
                    self.dismiss(animated: true, completion: {
                        // Append new PFObject and reload UITableView instead of re-querying data
                        self.messageObjects.append(chats)
                        
                        // Reload data and scroll to bottom in main thread if messageObjects isn't empty
                        if self.messageObjects.count > 0 {
                            DispatchQueue.main.async(execute: {
                                self.tableView.reloadData()
                                self.tableView.scrollToRow(at: IndexPath(row: self.messageObjects.count - 1, section: 0), at: .bottom, animated: true)
                            })
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // Dismiss view controller
                    self.dismiss(animated: true, completion: {
                        // Re-enable done button
                        editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
                    })
                }
            }
        }
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Query Chats
        fetchChats()
        // Set bool
        chatCamera = false
        // Add observers
        self.createObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UITableView
        self.tableView.estimatedRowHeight = 80
        self.tableView.tableFooterView = UIView()
        
        // Add long press method to UITableView
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(chatOptions))
        hold.minimumPressDuration = 0.40
        self.tableView.isUserInteractionEnabled = true
        self.tableView.addGestureRecognizer(hold)
        
        // Configure UIButtons; photosButton and stickersButton
        // MARK: - RPExtensions
        photosButton.backgroundColor = UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1)
        photosButton.roundAllCorners(sender: self.photosButton)
        stickersButton.backgroundColor = UIColor.white
        stickersButton.makeCircular(forView: self.stickersButton, borderWidth: 2, borderColor: UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1))
        
        // Configure sendButton UIButton
        let sendImage = UIImage(cgImage: UIImage(named: "SentFilled")!.cgImage!, scale: 1, orientation: .rightMirrored)
        self.sendButton.setImage(sendImage, for: .normal)
        
        // Configure UITextView
        // MARK: - RPHelpers
        self.textView.roundAllCorners(sender: self.textView)
        self.textView.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.textView.layer.borderWidth = 1
        self.textView.clipsToBounds = true
        self.textView.text = "Share your message..."
        self.textView.textColor = UIColor.lightGray
        
        
        // MARK: - UIImagePickerController
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.whitenBar(navigator: imagePicker.navigationController)

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refresher)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Resign UITextView
        self.textView.resignFirstResponder()
        // Remove observers
        self.removeObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    
    // MARK: - UIKeyboard Notification Observers
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        // Add observer for screenshots
        NotificationCenter.default.addObserver(self, selector: #selector(sendScreenshot),
                                               name: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchChats), name: rpChat, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            // If table view's origin is 0
            if self.tableView!.frame.origin.y == 0 {
                // Move UITableView (tableView), UITextView (textView), and UIView (innerView) up
                self.tableView.frame.origin.y -= self.keyboard.height
                self.innerView.frame.origin.y -= self.keyboard.height
                self.textView.frame.origin.y -= self.keyboard.height
                
                // Scroll to the bottom
                if self.messageObjects.count > 0 {
                    let bot = CGPoint(x: 0, y: self.tableView!.contentSize.height - self.tableView!.bounds.size.height)
                    self.tableView.setContentOffset(bot, animated: false)
                }
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        if self.tableView!.frame.origin.y != 0 {
            // Move UITableView (tableView), UITextView (textView), and UIView (innerView) down
            self.tableView.frame.origin.y += self.keyboard.height
            self.innerView.frame.origin.y += self.keyboard.height
            self.textView.frame.origin.y += self.keyboard.height
        }
    }
    
    // MARK: - UITextView Delegate Methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView.textColor == UIColor.lightGray {
            self.textView.text = ""
            self.textView.textColor = UIColor.black
            
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "is typing...")
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        
        // Disable sendButton if there's no text...
        let spacing = CharacterSet.whitespacesAndNewlines
        if !textView.text.trimmingCharacters(in: spacing).isEmpty {
            self.sendButton.isEnabled = true
        } else {
            self.sendButton.isEnabled = false
        }
        
        // INCREASE UITextView Height
        if textView.contentSize.height > textView.frame.size.height && textView.frame.height < 140 {
            
            // Get difference of frame height
            let difference = textView.contentSize.height - textView.frame.size.height
            
            // Redefine frame of UITextView; textView
            // Subtract 1 for UITextView's height because of the 1 point top margin constraint in Storyboard
            textView.frame.origin.y = textView.frame.origin.y - difference
            textView.frame.size.height = textView.contentSize.height

            // Move UITableView up
            self.tableView.frame.origin.y -= difference
            
        } else if textView.contentSize.height < textView.frame.size.height {
        // DECREASE UITextView Height
            
            // Get difference to deduct
            let difference = textView.frame.size.height - textView.contentSize.height

            // Redefine frame of UITextView; textView
            textView.frame.origin.y = textView.frame.origin.y + difference
            textView.frame.size.height = textView.contentSize.height

            // Move UITableView down
            self.tableView!.frame.origin.y += difference
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    // MARK: - UIImagePickercontroller Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // IMAGE
        if (info[UIImagePickerControllerMediaType] as! NSString) == kUTTypeImage {
            // Disable editing if it's a photo
            self.imagePicker.allowsEditing = false
            // Selected image
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            // Dismiss
            self.imagePicker.dismiss(animated: true, completion: nil)
            
            // MARK: - CLImageEditor
            let editor = CLImageEditor(image: image)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
            tool?.title = "Emoji"
            self.present(editor!, animated: true, completion: nil)
            
        } else if (info[UIImagePickerControllerMediaType] as! NSString) == kUTTypeMovie {
            // VIDEO
            // Enable editing if it's a video
            self.imagePicker.allowsEditing = true
            // Create temporary URL path to store video
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            // Compress video
            compressVideo(inputURL: (info[UIImagePickerControllerMediaURL] as! URL), outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    return
                }
                switch session.status {
                case .unknown:
                    rpHelpers.showError(withTitle: "Unknown Error...")
                case .waiting:
                    rpHelpers.showProgress(withTitle: "Compressing Video...")
                case .exporting:
                    rpHelpers.showProgress(withTitle: "Exporting Video...")
                case .completed:
                    do {
                        let videoData = try Data(contentsOf: compressedURL)
                        // Create PFObject
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = chatUserObject.last!
                        chats["receiverUsername"] = chatUsername.last!
                        chats["videoAsset"] = PFFile(name: "video.mov", data: videoData)
                        chats["contentType"] = "vi"
                        chats["read"] = false
                        chats["saved"] = false
                        DispatchQueue.main.async(execute: {
                            chats.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    
                                    // MARK: - RPHelpers; update chatsQueue, and send push notification
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                                    rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                                    
                                    // Clear UITextView
                                    self.textView.text!.removeAll()
                                    
                                    // Dismiss
                                    self.imagePicker.dismiss(animated: true, completion: { 
                                        // Append new PFObject and reload UITableView instead of re-querying data
                                        self.messageObjects.append(chats)
                                        
                                        // Reload data and scroll to bottom in main thread if messageObjects isn't empty
                                        if self.messageObjects.count > 0 {
                                            DispatchQueue.main.async(execute: {
                                                self.tableView.reloadData()
                                                self.tableView.scrollToRow(at: IndexPath(row: self.messageObjects.count - 1, section: 0), at: .bottom, animated: true)
                                            })
                                        }
                                    })
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                    // MARK: - RPHelpers
                                    let rpHelpers = RPHelpers()
                                    rpHelpers.showError(withTitle: "Video Failed to Send")
                                    
                                    // Dismiss and reload data
                                    self.imagePicker.dismiss(animated: true, completion: { 
                                        // Append object and reload data
                                        self.messageObjects.append(chats)
                                        self.tableView.reloadData()
                                    })
                                }
                            })
                        })
                        
                    } catch let error {
                        print(error.localizedDescription as Any)
                        rpHelpers.showError(withTitle: "Failed to Compress Video...")
                    }
                case .failed:
                    rpHelpers.showError(withTitle: "Failed to Compress Video...")
                case .cancelled:
                    rpHelpers.showError(withTitle: "Failed to Compress Video...")
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    

    // MARK: - UITableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TEXT
        if self.messageObjects[indexPath.row].value(forKey: "Message") != nil {
            
            let tCell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatRoomCell", for: indexPath) as! RPChatRoomCell
            tCell.delegate = self                                           // Set PFObject
            tCell.postObject = messageObjects[indexPath.row]                // Set parent UIViewController
            tCell.updateView(withObject: messageObjects[indexPath.row])     // Update UI
            return tCell
            
        } else {
        // MEDIA CELL
            
            let mCell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatMediaCell", for: indexPath) as! RPChatMediaCell
            mCell.delegate = self                                           // Set PFObject
            mCell.postObject = messageObjects[indexPath.row]                // Set parent UIViewController
            mCell.updateView(withObject: messageObjects[indexPath.row])     // Update UI
            return mCell
        }
    }
    
    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = UIColor.groupTableViewBackground
    }
    
    // MARK: - UIScrollView Delegate Methods
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign First responder
        self.textView.resignFirstResponder()
        self.tableView.frame.origin.y = 0
    }
}



/*
 MARK: - RPChatRoom Extension; Functions
 • chatOptions() = Show options to save, unsave, or delete a chat when the UITableViewCell was selected.
 */
extension RPChatRoom {
    
    // FUNCTION - Delete chats
    func chatOptions(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Chat", message: nil)
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
                // (1) Delete button
                let delete = AZDialogAction(title: "Delete", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    
                    // Delete Chat
                    let chats = PFQuery(className: "Chats")
                    chats.getObjectInBackground(withId: self.messageObjects[indexPath.row].objectId!,
                                                block: { (object: PFObject?, error: Error?) in
                                                    if error == nil {
                                                        object!.deleteInBackground(block: { (success: Bool, error: Error?) in
                                                            if error == nil {
                                                                print("Successfully deleted chat: \(object!)")
    
                                                                // MARK: - RPHelpers; Update <ChatsQueue> with last object in array
                                                                let rpHelpers = RPHelpers()
                                                                if let lastChat = self.messageObjects.last {
                                                                    rpHelpers.updateQueue(chatQueue: lastChat, userObject: chatUserObject.last!)
                                                                } else if let firstChat = self.messageObjects.first {
                                                                    rpHelpers.updateQueue(chatQueue: firstChat, userObject: chatUserObject.last!)
                                                                }
                                                                
                                                                // Delete from messageObjects and UITableView
                                                                self.messageObjects.remove(at: indexPath.row)
                                                                self.tableView!.deleteRows(at: [indexPath], with: .fade)
                                                                
                                                                // Show success
                                                                rpHelpers.showSuccess(withTitle: "Deleted")
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                                // MARK: - RPHelpers
                                                                let rpHelpers = RPHelpers()
                                                                rpHelpers.showError(withTitle: "Network Error")
                                                            }
                                                        })
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                        // MARK: - RPHelpers
                                                        let rpHelpers = RPHelpers()
                                                        rpHelpers.showError(withTitle: "Network Error")
                                                    }
                    })
                })
                // (2) Save button
                let save = AZDialogAction(title: "Save", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    // Query Chats
                    let chats = PFQuery(className: "Chats")
                    chats.getObjectInBackground(withId: self.messageObjects[indexPath.row].objectId!,
                                                block: { (object: PFObject?, error: Error?) in
                                                    if error == nil {
                                                        object!["saved"] = true
                                                        object!.saveInBackground()
                                                        
                                                        // MARK: - RPHelpers
                                                        let rpHelpers = RPHelpers()
                                                        rpHelpers.showSuccess(withTitle: "Saved")
                                                        
                                                        // Reload UITableViewCell data and array data
                                                        self.messageObjects[indexPath.item] = object!
                                                        self.tableView.reloadRows(at: [indexPath], with: .none)
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                        // MARK: - RPHelpers
                                                        let rpHelpers = RPHelpers()
                                                        rpHelpers.showError(withTitle: "Error")
                                                    }
                    })
                })
                // (3) Unsave
                let unsave = AZDialogAction(title: "Unsave", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    // Query Chats
                    let chats = PFQuery(className: "Chats")
                    chats.getObjectInBackground(withId: self.messageObjects[indexPath.row].objectId!,
                                                block: { (object: PFObject?, error: Error?) in
                                                    if error == nil {
                                                        object!["saved"] = false
                                                        object!.saveInBackground()
                                                        
                                                        // MARK: - RPHelpers
                                                        let rpHelpers = RPHelpers()
                                                        rpHelpers.showSuccess(withTitle: "Unsaved")
                                                        
                                                        // Configure time to check for "Ephemeral" content
                                                        let components : NSCalendar.Unit = .hour
                                                        let difference = (Calendar.current as NSCalendar).components(components, from: object!.createdAt!, to: Date(), options: [])
                                                        
                                                        // Delete from messageObjects and UITableView if > 24 hours
                                                        if difference.hour! > 24 {
                                                            self.messageObjects.remove(at: indexPath.row)
                                                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                                                        } else {
                                                        // Otherwise, reload UITableViewCell
                                                            self.tableView.reloadRows(at: [indexPath], with: .fade)
                                                        }
                                                        
                                                    } else {
                                                        print(error?.localizedDescription as Any)
                                                        // MARK: - RPHelpers
                                                        let rpHelpers = RPHelpers()
                                                        rpHelpers.showError(withTitle: "Network Error")
                                                    }
                    })
                    
                })
                // Add Cancel button
                dialogController.cancelButtonStyle = { (button,height) in
                    button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                    button.setTitle("CANCEL", for: [])
                    return true
                }
                // Sender CAN delete chat
                if (self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    dialogController.addAction(delete)
                    if self.messageObjects[indexPath.row].value(forKey: "saved") as! Bool == true {
                        dialogController.addAction(unsave)
                    } else {
                        dialogController.addAction(save)
                    }
                } else {
                    if self.messageObjects[indexPath.row].value(forKey: "saved") as! Bool == true {
                        dialogController.addAction(unsave)
                    } else {
                        dialogController.addAction(save)
                    }
                }
                // Show
                dialogController.show(in: self)
            }
        }
    }
}
