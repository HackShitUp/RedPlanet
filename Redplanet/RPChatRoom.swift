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
import SimpleAlert
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
        
        let report = UIAlertAction(title: "Report",
                                  style: .destructive,
                                  handler: {(alertAction: UIAlertAction!) in
                                    
                                    
                                    let alert = UIAlertController(title: "Report \(chatUsername.last!.uppercased())?",
                                        message: "Are you sure you'd like to report \(chatUsername.last!.uppercased())?",
                                        preferredStyle: .alert)
                                    
                                    let yes = UIAlertAction(title: "yes",
                                                            style: .destructive,
                                                            handler: { (alertAction: UIAlertAction!) -> Void in
                                                                // I have to manually delete all "blocked objects..." -__-
                                                                let block = PFObject(className: "Block_Reported")
                                                                block["from"] = PFUser.current()!.username!
                                                                block["fromUser"] = PFUser.current()!
                                                                block["to"] = chatUsername.last!
                                                                block["forObjectId"] = chatUserObject.last!.objectId!
                                                                block.saveInBackground(block: {
                                                                    (success: Bool, error: Error?) in
                                                                    if success {
                                                                        print("Successfully reported \(block)")
                                                                        
                                                                    } else {
                                                                        print(error?.localizedDescription as Any)
                                                                    }
                                                                })
                                                                // Close cell
                                                                self.tableView.setEditing(false, animated: true)
                                    })
                                    
                                    let no = UIAlertAction(title: "no",
                                                           style: .cancel,
                                                           handler: nil)
                                    
                                    alert.addAction(no)
                                    alert.addAction(yes)
                                    alert.view.tintColor = UIColor.black
                                    self.present(alert, animated: true, completion: nil)
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addAction(visit)
        alert.addAction(report)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
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
    
    
    
    // Function to access photos
    func accessPhotos() {
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
        let chat = PFObject(className: "Chats")
        chat["sender"] = PFUser.current()!
        chat["senderUsername"] = PFUser.current()!.username!
        chat["receiver"] = chatUserObject.last!
        chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chat["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(image, 0.5)!)
        chat["read"] = false
        chat.saveInBackground {
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

    
    // Function to push camera
    func goCamera(sender: UIButton) {
        chatCamera = true
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    
    // Function to go to stickers
    func goStickers(sender: UIButton) {
        let stickersVC = self.storyboard?.instantiateViewController(withIdentifier: "stickersVC") as! Stickers
        self.navigationController!.pushViewController(stickersVC, animated: false)
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
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Query Chats
        queryChats()
        // Stylize title
        configureView()

        // Send push notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil,
                                               queue: OperationQueue.main) { notification in
                                                // Send screenshot
                                                self.sendScreenshot()
        }
        // Add observer to reload chats
        NotificationCenter.default.addObserver(self, selector: #selector(queryChats), name: rpChat, object: nil)
        
        // Add long press method in tableView
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(options))
        hold.minimumPressDuration = 0.30
        self.tableView.isUserInteractionEnabled = true
        self.tableView.addGestureRecognizer(hold)
        
        // Set bool
        chatCamera = false
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true

        // Set tableView estimated row height
        self.tableView!.estimatedRowHeight = 60
        
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
        
        
        // Add Photo Library method to photosButton
        let photosTap = UITapGestureRecognizer(target: self, action: #selector(accessPhotos))
        photosTap.numberOfTapsRequired = 1
        self.photosButton.isUserInteractionEnabled = true
        self.photosButton.addGestureRecognizer(photosTap)
        // Add camera tap
        let cameraTap = UITapGestureRecognizer(target: self, action: #selector(goCamera))
        cameraTap.numberOfTapsRequired = 1
        self.cameraButton.isUserInteractionEnabled = true
        self.cameraButton.addGestureRecognizer(cameraTap)
        // Add stickers tap
        let stickersTap = UITapGestureRecognizer(target: self, action: #selector(goStickers))
        stickersTap.numberOfTapsRequired = 1
        self.stickersButton.isUserInteractionEnabled = true
        self.stickersButton.addGestureRecognizer(stickersTap)
        
        
        // Add Function Method to add user's read recipets
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
                    object!.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Read")
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(queryChats), name: rpChat, object: nil)
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
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // Send chat
            self.sendChat()
            return false
        } else {
            return true
        }
    }
    
    
    // while writing something
    func textViewDidChange(_ textView: UITextView) {
//        if newChat.contentSize.height > newChat.frame.size.height && newChat.frame.height < 130 {
//            let difference = newChat.contentSize.height - newChat.frame.size.height
//            newChat.frame.origin.y = newChat.frame.origin.y - difference
//            newChat.frame.size.height = newChat.contentSize.height
//        }
    }

    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign chat
        self.newChat.resignFirstResponder()
    }
    
    
    // Function for options
    func options(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchedAt = sender.location(in: self.tableView)
            if let indexPath = self.tableView.indexPathForRow(at: touchedAt) {
                
                
                // MARK: - SimpleAlert
                let options = AlertController(title: "Options",
                                              message: nil,
                                              style: .alert)
                
                // Design content view
                options.configContentView = { view in
                    if let view = view as? AlertContentView {
                        view.backgroundColor = UIColor.white
                        view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                        view.titleLabel.textColor = UIColor.black
                        view.textBackgroundView.layer.cornerRadius = 3.00
                        view.textBackgroundView.clipsToBounds = true
                        
                    }
                }
                
                // Design corner radius
                options.configContainerCornerRadius = {
                    return 14.00
                }
                
                
                let delete = AlertAction(title: "Delete",
                                         style: .destructive,
                                         handler: { (AlertAction) in
                                            
                                            // MARK: - SVProgressHUD
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                            SVProgressHUD.show()
                                            
                                            // delete chat
                                            let chats = PFQuery(className: "Chats")
                                            chats.whereKey("sender", equalTo: PFUser.current()!)
                                            chats.whereKey("receiver", equalTo: chatUserObject.last!)
                                            chats.whereKey("objectId", equalTo: self.messageObjects[indexPath.row].objectId!)
                                            chats.findObjectsInBackground(block: {
                                                (objects: [PFObject]?, error: Error?) in
                                                if error == nil {
                                                    for object in objects! {
                                                        object.deleteInBackground(block: {
                                                            (success: Bool, error: Error?) in
                                                            if error == nil {
                                                                print("Successfully deleted message: \(object)")
                                                                
                                                                // MARK: - SVProgressHUD
                                                                SVProgressHUD.showSuccess(withStatus: "Deleted")
                                                                
                                                                // Delete chat from tableview
                                                                self.messageObjects.remove(at: indexPath.row)
                                                                self.tableView!.deleteRows(at: [indexPath], with: .fade)
                                                                
                                                                // Query chats
                                                                self.queryChats()
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                    // MARK: - SVProgressHUD
                                                    SVProgressHUD.showError(withStatus: "Error")
                                                }
                                            })
                })
                
                let report = AlertAction(title: "Report",
                                         style: .default,
                                         handler: { (AlertAction) in
                                            
                                            let alert = UIAlertController(title: "Report \(chatUsername.last!.uppercased())?",
                                                message: "Are you sure you'd like to report \(chatUsername.last!.uppercased())?",
                                                preferredStyle: .alert)
                                            
                                            let yes = UIAlertAction(title: "yes",
                                                                    style: .destructive,
                                                                    handler: { (alertAction: UIAlertAction!) -> Void in
                                                                        // I have to manually delete all "blocked objects..." -__-
                                                                        let block = PFObject(className: "Block_Reported")
                                                                        block["from"] = PFUser.current()!.username!
                                                                        block["fromUser"] = PFUser.current()!
                                                                        block["to"] = chatUsername.last!
                                                                        block["forObjectId"] = self.messageObjects[indexPath.row].objectId!
                                                                        block.saveInBackground(block: {
                                                                            (success: Bool, error: Error?) in
                                                                            if success {
                                                                                print("Successfully reported \(block)")
                                                                                
                                                                            } else {
                                                                                print(error?.localizedDescription as Any)
                                                                            }
                                                                        })
                                                                        // Close cell
                                                                        self.tableView.setEditing(false, animated: true)
                                            })
                                            
                                            let no = UIAlertAction(title: "no",
                                                                   style: .cancel,
                                                                   handler: nil)
                                            
                                            alert.addAction(no)
                                            alert.addAction(yes)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
                                            
                })
                

                let cancel = AlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
                
                
                // Return specific actions depending on user's object
                if (self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
                    options.addAction(cancel)
                    options.addAction(delete)
                    delete.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                    delete.button.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                } else {
                    options.addAction(cancel)
                    options.addAction(report)
                    report.button.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 19.0)
                    report.button.setTitleColor(UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0), for: .normal)
                }
                
                for b in options.actions {
                    b.button.frame.size.height = 50
                }
                
                cancel.button.titleLabel?.font = UIFont(name: "AvenirNext-Demibold", size: 17.0)
                cancel.button.setTitleColor(UIColor.black, for: .normal)
                
                // Show Alert
                self.present(options, animated: true, completion: nil)
                
            }
        }
    }
    
    

    // MARK: - UITableViewDataSource and Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

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
            messageObjects[indexPath.row].fetchInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // Fetch media asset and handle optional chaining
                    if let media = object!["photoAsset"] as? PFFile {
                        // MARK: - SDWebImage
                        mCell.rpMediaAsset.sd_setShowActivityIndicatorView(true)
                        mCell.rpMediaAsset.sd_setIndicatorStyle(.gray)
                        
                        // Traverse file to URL
                        let fileURL = URL(string: media.url!)
                        
                        // Create rounded corners
                        mCell.rpMediaAsset.layer.cornerRadius = 12.00
                        mCell.rpMediaAsset.layer.borderColor = UIColor.clear.cgColor
                        mCell.rpMediaAsset.layer.borderWidth = 0.00
                        
                        // MARK: - SDWebImage
                        mCell.rpMediaAsset.sd_setImage(with: fileURL!, placeholderImage: mCell.rpMediaAsset.image)
                        
                    } else {
                        // Get media preview
                        if let videoFile = object!["videoAsset"] as? PFFile {
                        // VIDEO
                            // LayoutViews
                            mCell.rpMediaAsset.layoutIfNeeded()
                            mCell.rpMediaAsset.layoutSubviews()
                            mCell.rpMediaAsset.setNeedsLayout()
                            
                            // Make Vide Preview Circular
                            mCell.rpMediaAsset.layer.cornerRadius = mCell.rpMediaAsset.frame.size.width/2
                            mCell.rpMediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                            mCell.rpMediaAsset.layer.borderWidth = 3.50
                            // MARK: - SDWebImage
                            mCell.rpMediaAsset.sd_setShowActivityIndicatorView(true)
                            mCell.rpMediaAsset.sd_setIndicatorStyle(.gray)
                            
                            // Load Video Preview and Play Video
                            let player = AVPlayer(url: URL(string: videoFile.url!)!)
                            let playerLayer = AVPlayerLayer(player: player)
                            playerLayer.frame = mCell.rpMediaAsset.bounds
                            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                            mCell.rpMediaAsset.contentMode = .scaleAspectFit
                            mCell.rpMediaAsset.layer.addSublayer(playerLayer)
                            player.isMuted = true
                            player.isMuted = true
                            player.play()
                        }
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
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
