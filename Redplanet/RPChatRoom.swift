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
import SVProgressHUD
import SDWebImage

// Global variable to hold user's object and username for chats
var chatUserObject = [PFObject]()
var chatUsername = [String]()

// Add Notification to reload data
let rpChat = Notification.Name("rpChat")

class RPChatRoom: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {
    
    // Variable to hold messageObjects
    var messageObjects = [PFObject]()
    // Keyboard frame
    var keyboard = CGRect()
    // Refresher
    var refresher: UIRefreshControl!
    // Set pipeline
    var page: Int = 50
    // Variable to hold UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newChat: UITextView!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var stickersButton: UIButton!
    
    @IBAction func backButton(_ sender: AnyObject) {
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
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        // (1) View Profile
        let visit = UIAlertAction(title: "Visit Profile",
            style: .default,
            handler: {(alertAciont: UIAlertAction!) in
                // Appned user's object
                otherObject.append(chatUserObject.last!)
                // Append user's username
                otherName.append(chatUsername.last!)
                
                // Push VC
                let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                self.navigationController?.pushViewController(otherVC, animated: true)
        })
        
        // (2) Report
        let report = UIAlertAction(title: "Report",
                                  style: .destructive,
                                  handler: {(alertAction: UIAlertAction!) in
                                    
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
                                                
                                                let alert = UIAlertController(title: "Successfully Reported",
                                                                              message: "\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)",
                                                    preferredStyle: .alert)
                                                
                                                let ok = UIAlertAction(title: "ok",
                                                                       style: .default,
                                                                       handler: nil)
                                                
                                                alert.addAction(ok)
                                                alert.view.tintColor = UIColor.black
                                                self.present(alert, animated: true, completion: nil)
                                                
                                            } else {
                                                print(error?.localizedDescription as Any)
                                                // MARK: - SVProgressHUD
                                                SVProgressHUD.showError(withStatus: "Error")
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
                                    self.present(alert, animated: true, completion: nil)
                                    
        })
        
        // (3) Block user
        let block = UIAlertAction(title: "Block",
                                  style: .default,
                                  handler: {(alertAction: UIAlertAction!) in
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
                                                    // Dismiss
                                                    let alert = UIAlertController(title: "Successfully Blocked",
                                                                                  message: "\(chatUsername.last!.uppercased()). You can unblock \(chatUserObject.last!.value(forKey: "realNameOfUser") as! String) in Settings.",
                                                        preferredStyle: .alert)
                                                    
                                                    let ok = UIAlertAction(title: "ok",
                                                                           style: .default,
                                                                           handler: { (alertAction: UIAlertAction!) in
                                                                            _ = self.navigationController?.popViewController(animated: true)
                                                    })
                                                    
                                                    alert.view.tintColor = UIColor.black
                                                    alert.addAction(ok)
                                                    self.present(alert, animated: true, completion: nil)
                                                    
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.showError(withStatus: "Error")
                                                }
                                            })
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.showError(withStatus: "Error")
                                        }
                                    })
        })
        
        // (4) Cancel
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addAction(visit)
        alert.addAction(block)
        alert.addAction(report)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func showLibrary(_ sender: Any) {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            switch status{
            case .authorized:
                print("Authorized")
                
                // Load Photo Library
                DispatchQueue.main.async(execute: {
                    self.navigationController!.present(self.imagePicker, animated: true, completion: nil)
                })
                
                break
            case .denied:
                print("Denied")
                let alert = UIAlertController(title: "Photos Access Denied",
                                              message: "Please allow Redplanet access your Photos.",
                                              preferredStyle: .alert)
                
                let settings = UIAlertAction(title: "Settings",
                                             style: .default,
                                             handler: {(alertAction: UIAlertAction!) in
                                                
                                                let url = URL(string: UIApplicationOpenSettingsURLString)
                                                UIApplication.shared.openURL(url!)
                })
                
                let deny = UIAlertAction(title: "Later",
                                         style: .destructive,
                                         handler: nil)
                
                alert.addAction(settings)
                alert.addAction(deny)
                self.present(alert, animated: true, completion: nil)
                
                break
            default:
                print("Default")
                
                break
            }
        })
    }
    
    @IBAction func showCamera(_ sender: Any) {
        chatCamera = true
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    // IBAction --> Show Stickers
    @IBAction func showStickers(_ sender: Any) {
        let stickersVC = self.storyboard?.instantiateViewController(withIdentifier: "stickersVC") as! Stickers
        self.navigationController!.pushViewController(stickersVC, animated: false)
    }
    
    // Fetch chats
    func queryChats() {
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKeys(["receiver", "sender"])
        chats.order(byAscending: "createdAt")
        chats.limit = self.page
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                // Clear arrays
                self.messageObjects.removeAll(keepingCapacity: false)
                for object in objects! {
                    // Append object
                    self.messageObjects.append(object)
                }
                // Reload data
                self.tableView!.reloadData()
                // Scroll to bottom via main thread
                DispatchQueue.main.async(execute: {
                    if self.messageObjects.count > 0 {
                        let bot = CGPoint(x: 0, y: self.tableView!.contentSize.height - self.tableView!.bounds.size.height)
                        self.tableView.setContentOffset(bot, animated: false)
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
            }
        })
    }
    
    
    // Function to send chat
    func sendChat() {
        if self.newChat.text!.isEmpty {
            // Resign first responder
            self.newChat.resignFirstResponder()
        } else {
            // Track when chat was sent
            Heap.track("SentChat", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                ])
            // Clear text to prevent sending again and set constant before sending for better UX
            let chatText = self.newChat.text!
            // Clear chat
            self.newChat.text!.removeAll()
            // Send to Chats
            let chat = PFObject(className: "Chats")
            chat["sender"] = PFUser.current()!
            chat["senderUsername"] = PFUser.current()!.username!
            chat["receiver"] = chatUserObject.last!
            chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
            chat["Message"] = chatText
            chat["read"] = false
            chat.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    // Send Push Notification to user
                    // Handle optional chaining
                    if chatUserObject.last!.value(forKey: "apnsId") != nil {
                        // MARK: - OneSignal
                        // Send push notification
                        OneSignal.postNotification(
                            ["contents":
                                ["en": "from \(PFUser.current()!.username!.uppercased())"],
                             "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                             "ios_badgeType": "Increase",
                             "ios_badgeCount": 1,
                             ]
                        )
                    }
                    
                    // Add Int to Chat
                    let score: Int = UserDefaults.standard.integer(forKey: "ChatScore") + 1
                    UserDefaults.standard.set(score, forKey: "ChatScore")
                    UserDefaults.standard.synchronize()
                    // Reload data
                    self.queryChats()
                } else {
                    print(error?.localizedDescription as Any)
                    // Reload data
                    self.queryChats()
                }
            }
        }
    }
    
    // Compress video
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
    
    
    
    // MARK: - UIImagePickercontroller Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let pickerMedia = info[UIImagePickerControllerMediaType] as! NSString
        
        
        if pickerMedia == kUTTypeImage {
            // Disable editing if it's a photo
            self.imagePicker.allowsEditing = false
            // Selected image
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            // Dismiss
            self.imagePicker.dismiss(animated: true, completion: nil)
            
            // CLImageEditor
            let editor = CLImageEditor(image: image)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            self.present(editor!, animated: true, completion: nil)
        }
        
        
        
        if pickerMedia == kUTTypeMovie {
            // Enable editing if it's a video
            self.imagePicker.allowsEditing = true
            
            // Traverse to URL
            let video = info[UIImagePickerControllerMediaURL] as! URL

            // Compress Video data
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
            self.compressVideo(inputURL: video, outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    return
                }
                switch session.status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    guard let compressedData = NSData(contentsOf: compressedURL) else {
                        return
                    }
                    
                    // Handle File Size
                    let fileSize = Double(compressedData.length / 1048576)
                    if fileSize <= 1.0 {
                        // MARK: - SVProgressHUD
                        SVProgressHUD.show()
                        // Send Video
                        let chats = PFObject(className: "Chats")
                        chats["sender"] = PFUser.current()!
                        chats["senderUsername"] = PFUser.current()!.username!
                        chats["receiver"] = chatUserObject.last!
                        chats["receiverUsername"] = chatUsername.last!
                        chats["read"] = false
                        chats["videoAsset"] = PFFile(name: "video.mov", data: compressedData as Data)
                        chats["mediaType"] = "vi"
                        chats.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                // Dismiss Progres
                                SVProgressHUD.dismiss()
                                // Clear newChat
                                self.newChat.text!.removeAll()
                                // Handle optional chaining
                                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                                    // MARK: - OneSignal
                                    // Send Push Notification to user
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "from \(PFUser.current()!.username!.uppercased())"],
                                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                }
                                // Reload data
                                self.queryChats()
                                // Dismiss
                                self.imagePicker.dismiss(animated: true, completion: nil)
                            } else {
                                print(error?.localizedDescription as Any)
                                // Reload data
                                self.queryChats()
                                // Dismiss
                                self.imagePicker.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                    
                    if fileSize > 1.0 {
                        // MARK: - SVProgressHUD
                        SVProgressHUD.showError(withStatus: "Large File Size")
                        // Reload data
                        self.queryChats()
                        // Dismiss
                        self.imagePicker.dismiss(animated: true, completion: nil)
                    }
                    
                case .failed:
                    break
                case .cancelled:
                    break
                }
            }
        }
    }
    
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Disable done button
        editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = false
    
        // Send to Chats
        let chats = PFObject(className: "Chats")
        chats["sender"] = PFUser.current()!
        chats["senderUsername"] = PFUser.current()!.username!
        chats["receiver"] = chatUserObject.last!
        chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chats["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(image, 0.5)!)
        chats["mediaType"] = "ph"
        chats["read"] = false
        chats.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Re-enable done button
                editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
                
                // Clear newChat
                self.newChat.text!.removeAll()
                
                // Handle optional chaining
                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                    // MARK: - OneSignal
                    // Send Push Notification to user
                    OneSignal.postNotification(
                        ["contents":
                            ["en": "from \(PFUser.current()!.username!.uppercased())"],
                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                         "ios_badgeType": "Increase",
                         "ios_badgeCount": 1
                        ]
                    )
                }

                // Reload data
                self.queryChats()
                
                // Dismiss view controller
                self.dismiss(animated: true, completion: nil)
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Re-enable done button
                editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = true
                
                // Reload data
                self.queryChats()
                
                // Dismiss view controller
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    

    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    // Function to refresh
    func refresh() {
        // Query Chats
        queryChats()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to send screenshot
    func sendScreenshot() {
        // Send push notification
        if chatUserObject.last!.value(forKey: "apnsId") != nil {
            OneSignal.postNotification(
                ["contents":
                    ["en": "\(PFUser.current()!.username!.uppercased()) screenshot the conversation"],
                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                 "ios_badgeType": "Increase",
                 "ios_badgeCount": 1
                ]
            )
        }
    }
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)"
        }
        // Extension: UINavigationBar && hide UITabBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
        
        // MARK: - MainUITab
        // Hide button
        rpButton.isHidden = true
    }
    
    /*
     Function to add observers to...
     (1) Show UIKeyboard
     (2) Hide UIKeyboard
     (3) Reload Chats when OneSignal notification was received
     (4) Send Chat when ScreenShot occurs
    */
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil,
                                               queue: OperationQueue.main) { notification in
                                                // Send screenshot
                                                self.sendScreenshot()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(queryChats), name: rpChat, object: nil)
    }
    
    /*
     Function to remove observers that...
     (1) Show UIKeyboard
     (2) Hide UIKeyboard
     (3) Send Chat when ScreenShot occurs
     // DON'T remove this
     (4) Reload Chats when OneSignal notification was received
     */
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationUserDidTakeScreenshot, object: nil)
        NotificationCenter.default.removeObserver(self, name: rpChat, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Query Chats
        queryChats()
        // Set bool
        chatCamera = false
        // Add observers
        self.createObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Add observers
        self.createObservers()
        
        // Set tableView estimated row height
        self.tableView!.estimatedRowHeight = 60
        self.tableView!.tableFooterView = UIView()
        
        // Draw cornerRadius for cameraButton
        self.cameraButton.layer.borderColor = UIColor(red:0.80, green:0.80, blue:0.80, alpha:1.0).cgColor
        self.cameraButton.layer.borderWidth = 3.50
        self.cameraButton.layer.cornerRadius = 33/2
        self.cameraButton.clipsToBounds = true
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        // Open photo library
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        
        // Save read receipt
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKeys(["sender", "receiver"])
        chats.order(byDescending: "createdAt")
        chats.getFirstObjectInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // Get user's first object
                // And set bool value for read receipt
                if (object!.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    object!["read"] = true
                    object!.saveInBackground()
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Scroll to bottom via main thread
        DispatchQueue.main.async(execute: {
            if self.messageObjects.count != 0 && self.messageObjects.count > 8 {
                self.tableView!.scrollToRow(at: IndexPath(row: self.messageObjects.count - 1, section: 0), at: .bottom, animated: true)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Resign first responder
        self.newChat.resignFirstResponder()
        // Remove observers
        self.removeObservers()
        // MARK: - MainUITab
        // Show button
        rpButton.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
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
                // Move tableView up
                self.tableView!.frame.origin.y -= self.keyboard.height
                 // Move chatbox up
                self.frontView.frame.origin.y -= self.keyboard.height
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
            // Move table view up
            self.tableView!.frame.origin.y += self.keyboard.height
            // Move chatbox up
            self.frontView.frame.origin.y += self.keyboard.height
        }
    }
    
    
    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        // APNSID
        if chatUserObject.last!.value(forKey: "apnsId") != nil {
            // Show user is typing
            // MARK: - OneSignal
            OneSignal.postNotification(
                ["contents":
                    ["en": "\(PFUser.current()!.username!.uppercased()) is typing..."],
                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                 "ios_badgeType": "Increase",
                 "ios_badgeCount": 1,
                 ]
            )
        }
    }
    // Send chat if text starts a new line
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // Send chat
            self.sendChat()
            return false
        } else {
            return true
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign chat
        self.newChat.resignFirstResponder()
    }

    // MARK: - UITableViewDataSource and Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    /*
     <mediaType> in Databse Schema
     • ph
     • vi
     • itm
    */

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatRoomCell", for: indexPath) as! RPChatRoomCell
        let mCell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatMediaCell", for: indexPath) as! RPChatMediaCell
        
        
        // Set cell's delegate
        cell.delegate = self
        
        // Set mCell's delegate
        mCell.delegate = self
        
        // TEXT POST
        if self.messageObjects[indexPath.row].value(forKey: "Message") != nil {
            // Set layouts
            cell.rpUserProPic.layoutIfNeeded()
            cell.rpUserProPic.layoutSubviews()
            cell.rpUserProPic.setNeedsLayout()
            
            // Make profile photo circular
            cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
            cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            cell.rpUserProPic.layer.borderWidth = 0.5
            cell.rpUserProPic.clipsToBounds = true

            // (1) Set usernames depending on who sent what
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Set Current user's username
                cell.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            } else {
                // Set username
                cell.rpUsername.text! = chatUserObject.last!.value(forKey: "realNameOfUser") as! String
            }
            
            // Fetch Objects
            // (2) Get and set user's profile photos
            // If RECEIVER == <CurrentUser>     &&      SSENDER == <OtherUser>
            if (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == chatUserObject.last!.objectId! {
            
                // Get and set profile photo
                if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
            }
            // If SENDER == <CurrentUser>       &&      RECEIVER == <OtherUser>
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
                
                // Get and set Profile Photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
            }
            
            
            
            // (3) Set message
            cell.message.text! = messageObjects[indexPath.row].value(forKey: "Message") as! String
            
            // (4) Set time
            let from = self.messageObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.time.text = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                cell.time.text = "\(difference.second!)s ago"
            } else if difference.minute! > 0 && difference.hour! == 0 {
                cell.time.text = "\(difference.minute!)m ago"
            } else if difference.hour! > 0 && difference.day! == 0 {
                cell.time.text = "\(difference.hour!)h ago"
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                cell.time.text = "\(difference.day!)d ago"
            } else if difference.weekOfMonth! > 0 {
                cell.time.text = "\(difference.weekOfMonth!)w ago"
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM dd"
                cell.time.text = createdDate.string(from: self.messageObjects[indexPath.row].createdAt!)
            }
            
            
            return cell
            
        } else {
        // MEDIA CELL
            
            // Set mCell's content object
            mCell.mediaObject = self.messageObjects[indexPath.row]
            
            // Create cell's bounds
            mCell.contentView.frame = mCell.contentView.frame
            
            // Set layouts
            mCell.rpUserProPic.layoutIfNeeded()
            mCell.rpUserProPic.layoutSubviews()
            mCell.rpUserProPic.setNeedsLayout()
            
            // Make profile photo circualr
            mCell.rpUserProPic.layer.cornerRadius = mCell.rpUserProPic.frame.size.width/2
            mCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            mCell.rpUserProPic.layer.borderWidth = 0.5
            mCell.rpUserProPic.clipsToBounds = true
            
            // (1) Set usernames depending on who sent what
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Set Current user's username
                mCell.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            } else {
                // Set username
                mCell.rpUsername.text! = chatUserObject.last!.value(forKey: "realNameOfUser") as! String
            }
            
            // (2) Fetch Media Asset
            mCell.rpMediaAsset.contentMode = .scaleAspectFill
            mCell.rpMediaAsset.layer.borderColor = UIColor.clear.cgColor
            mCell.rpMediaAsset.layer.borderWidth = 0.0
            
            // (2A) PHOTO
            if let photo = self.messageObjects[indexPath.row].value(forKey: "photoAsset") as? PFFile {
                // Traverse file to URL
                let fileURL = URL(string: photo.url!)
            
                // (A) REGULAR:  PHOTO OR STICKER
                if self.messageObjects[indexPath.row].value(forKey: "mediaType") as! String == "ph" {
                    mCell.rpMediaAsset.layer.cornerRadius = 2.00
                } else if self.messageObjects[indexPath.row].value(forKey: "mediaType") as! String == "sti" {
                // STICKER
                    mCell.rpMediaAsset.layer.cornerRadius = 2.00
                    mCell.rpMediaAsset.contentMode = .scaleAspectFit
                } else if self.messageObjects[indexPath.row].value(forKey: "mediaType") as! String == "itm" {
                // (B) MOMENT
                    mCell.rpMediaAsset.layer.cornerRadius = mCell.rpMediaAsset.frame.size.width/2
                    mCell.rpMediaAsset.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                    mCell.rpMediaAsset.layer.borderWidth = 3.50
                }
            
                // MARK: - SDWebImage
                mCell.rpMediaAsset.sd_setShowActivityIndicatorView(true)
                mCell.rpMediaAsset.sd_setIndicatorStyle(.gray)
                mCell.rpMediaAsset.sd_setImage(with: fileURL!, placeholderImage: mCell.rpMediaAsset.image)
            }
            
            // (2B) VIDEO
            if let videoFile = self.messageObjects[indexPath.row].value(forKey: "videoAsset") as? PFFile {
                // LayoutViews
                mCell.rpMediaAsset.layoutIfNeeded()
                mCell.rpMediaAsset.layoutSubviews()
                mCell.rpMediaAsset.setNeedsLayout()
                
                if self.messageObjects[indexPath.row].value(forKey: "mediaType") as! String == "vi" {
                // (A) REGULAR: VIDEO
                    mCell.rpMediaAsset.layer.cornerRadius = mCell.rpMediaAsset.frame.size.width/2
                    mCell.rpMediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    mCell.rpMediaAsset.layer.borderWidth = 3.50
                } else {
                // (B) MOMENT
                    mCell.rpMediaAsset.layer.cornerRadius = mCell.rpMediaAsset.frame.size.width/2
                    mCell.rpMediaAsset.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                    mCell.rpMediaAsset.layer.borderWidth = 3.50
                }
                
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = mCell.rpMediaAsset.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                mCell.rpMediaAsset.contentMode = .scaleAspectFit
                mCell.rpMediaAsset.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            
            
            // Call Media Cell's awakeFromNib to layout the tap functions
            mCell.awakeFromNib()
            
            
            // Fetch objects
            // (3) Set usernames depending on who sent what
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                // Set Current user's username
                mCell.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
            } else {
                // Set username
                mCell.rpUsername.text! = chatUserObject.last!.value(forKey: "realNameOfUser") as! String
            }
            
            // (4) Get and set user's profile photos
            //
            // If RECEIVER == <CurrentUser>     &&      SSENDER == <OtherUser>
            //
            if (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == chatUserObject.last!.objectId! {
            
                // Get and set profile photo
                if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    mCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
                
            }
            //
            // If SENDER == <CurrentUser>       &&      RECEIVER == <OtherUser>
            //
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
                
                // Get and set Profile Photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    // MARK: - SDWebImage
                    mCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
                }
            }
            
            
            // (5) Set time
            let from = self.messageObjects[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                mCell.time.text = "now"
            } else if difference.second! > 0 && difference.minute! == 0 {
                mCell.time.text = "\(difference.second!)s ago"
            } else if difference.minute! > 0 && difference.hour! == 0 {
                mCell.time.text = "\(difference.minute!)m ago"
            } else if difference.hour! > 0 && difference.day! == 0 {
                mCell.time.text = "\(difference.hour!)h ago"
            } else if difference.day! > 0 && difference.weekOfMonth! == 0 {
                mCell.time.text = "\(difference.day!)d ago"
            } else if difference.weekOfMonth! > 0 {
                mCell.time.text = "\(difference.weekOfMonth!)w ago"
            } else if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM dd"
                mCell.time.text = createdDate.string(from: self.messageObjects[indexPath.row].createdAt!)
            }
            
            
            return mCell
        }
        

    } // end cellForRowAt
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= self.messageObjects.count {
            
            // Increase page size to load more posts
            page = page + 50
            
            // Query chats
            queryChats()
        }
    }


}
