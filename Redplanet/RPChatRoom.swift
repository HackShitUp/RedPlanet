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

// TODO::
// NOTE: That when you're sending an image, make sure you just send the image ONLY, so the database can distinguish it


// Global variable to hold user's object
var chatUserObject = [PFObject]()

// Global variabel to hold username
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
    
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newChat: UITextView!
    
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        
        // Clear arrays
        chatUserObject.removeLast()
        chatUsername.removeLast()
        
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
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
                let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
                self.navigationController?.pushViewController(otherVC, animated: true)
        })
        
        let report = UIAlertAction(title: "Report",
                                  style: .destructive,
                                  handler: {(alertAction: UIAlertAction!) in
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        alert.addAction(visit)
        alert.addAction(report)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Query all of the user's chats
    func queryChats() {
        // (A) Sender
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        // (B) Receiver
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        
        // (1) Chats subqueries
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKeys(["receiver", "sender"])
        chats.order(byAscending: "createdAt")
        chats.limit = self.page
        chats.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.messageObjects.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    // Append object
                    self.messageObjects.append(object)
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
            
            // Run in main thread...
            DispatchQueue.main.async(execute: {
                // Scroll to the bottom
                if self.messageObjects.count > 0 {
                    let bot = CGPoint(x: 0, y: self.tableView!.contentSize.height - self.tableView!.bounds.size.height)
                    self.tableView.setContentOffset(bot, animated: false)
                }
            })
            
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
                                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
                                ]
                            )
                        }
                        
                        
                    }
                    
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
    
    
    
    // UIImagePickercontroller Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let pickerMedia = info[UIImagePickerControllerMediaType] as! NSString
        
        
        if pickerMedia == kUTTypeImage {
            print("Photo selected")
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
            
            // Show Progress
            SVProgressHUD.show()
            SVProgressHUD.setBackgroundColor(UIColor.white)
            
            // Selected image
            let video = info[UIImagePickerControllerMediaURL] as! URL
            
            let tempImage = video as NSURL?
            _ = tempImage?.relativePath
            let videoData = NSData(contentsOfFile: (tempImage?.relativePath!)!)
            let parseFile = PFFile(name: "video.mp4", data: videoData! as Data)
            
            // Send Video
            let chats = PFObject(className: "Chats")
            chats["sender"] = PFUser.current()!
            chats["senderUsername"] = PFUser.current()!.username!
            chats["receiver"] = chatUserObject.last!
            chats["receiverUsername"] = chatUsername.last!
            chats["read"] = false
            chats["videoAsset"] = parseFile
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
                             "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
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
        
        
    }
    
    
    
    
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Disable done button
        editor.navigationController?.navigationBar.topItem?.leftBarButtonItem?.isEnabled = false
        
        // Convert UIImage to NSData
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        // Change UIImage to PFFile
        let parseFile = PFFile(data: imageData!)
        
        
        // Send to Chats
        let chat = PFObject(className: "Chats")
        chat["sender"] = PFUser.current()!
        chat["senderUsername"] = PFUser.current()!.username!
        chat["receiver"] = chatUserObject.last!
        chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chat["photoAsset"] = parseFile
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
                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
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
        // Set bool
        chatCamera = true
        
        // Push VC
        let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "camera") as! RPCamera
        self.navigationController!.pushViewController(cameraVC, animated: true)
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
                    ["en": "\(PFUser.current()!.username!.uppercased()) screenshotted the conversation"],
                 "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
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
    }
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
        // Query Chats
        queryChats()

        // Send push notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil,
                                               queue: OperationQueue.main) { notification in
                                                // Send screenshot
                                                self.sendScreenshot()
        }
        
        
        // Set bool
        chatCamera = false
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true

        // Set tableView estimated row height
        self.tableView!.estimatedRowHeight = 60
        
        // Add notifications to hide chatBoxx
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(queryChats), name: rpChat, object: nil)
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
        
        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView!.addSubview(refresher)
        
        
        // Open photo library
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.allowsEditing = true
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
        
        // Stylize title
        configureView()
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Run in main thread...
        DispatchQueue.main.async(execute: {
            // Scroll to the bottom
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
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
        
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // If table view's origin is 0
            if self.tableView!.frame.origin.y == 0 {
                
                // Scroll to the bottom
                if self.messageObjects.count > 0 {
                    let bot = CGPoint(x: 0, y: self.tableView!.contentSize.height - self.tableView!.bounds.size.height)
                    self.tableView.setContentOffset(bot, animated: false)
                }
                
                // Move tableView up
                self.tableView!.frame.origin.y -= self.keyboard.height
                
                // Move chatbox up
                self.frontView.frame.origin.y -= self.keyboard.height
                
            }
            
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
        
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatRoomCell", for: indexPath) as! RPChatRoomCell
        let mCell = self.tableView!.dequeueReusableCell(withIdentifier: "rpChatMediaCell", for: indexPath) as! RPChatMediaCell
        
        
        // Set cell's delegate
        cell.delegate = self
        
        // Set mCell's delegate
        mCell.delegate = self
        
        
        if self.messageObjects[indexPath.row].value(forKey: "Message") != nil {
        
            //////////////////////////////
            ///                       ///
            /// Return TextPost Cell ///
            ///                     ///
            //////////////////////////
            
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
            //
            // If RECEIVER == <CurrentUser>     &&      SSENDER == <OtherUser>
            //
            if (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == chatUserObject.last!.objectId! {
            
                // Get and set profile photo
                if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                        if error == nil {
                            // Set pro pic
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
            }
            //
            // If SENDER == <CurrentUser>       &&      RECEIVER == <OtherUser>
            //
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
                
                // Get and set Profile Photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                        if error == nil {
                            // Set pro pic
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
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
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.time.text = "now"
            }
            
            if difference.second! > 0 && difference.minute! == 0 {
                cell.time.text = "\(difference.second!)s ago"
            }
            
            if difference.minute! > 0 && difference.hour! == 0 {
                cell.time.text = "\(difference.minute!)m ago"
            }
            
            if difference.hour! > 0 && difference.day! == 0 {
                cell.time.text = "\(difference.hour!)h ago"
            }
            
            if difference.day! > 0 && difference.weekOfMonth! == 0 {
                cell.time.text = "\(difference.day!)d ago"
            }
            
            if difference.weekOfMonth! > 0 {
                cell.time.text = "\(difference.weekOfMonth!)w ago"
            }
            
            if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM dd"
                cell.time.text = createdDate.string(from: self.messageObjects[indexPath.row].createdAt!)
            }
            
            
            return cell
            
        } else {
            
            //////////////////////////////
            /////////////////////////////
            /// Return Media Cell //////
            ///////////////////////////
            //////////////////////////
            
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
                        media.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                
                                // Create rounded corners
                                mCell.rpMediaAsset.layer.cornerRadius = 0.00
                                mCell.rpMediaAsset.contentMode = .scaleAspectFit
                                mCell.rpMediaAsset.layer.borderColor = UIColor.clear.cgColor
                                mCell.rpMediaAsset.layer.borderWidth = 0.00
                                mCell.rpMediaAsset.clipsToBounds = true
                                
                                // Set Media Asset
                                mCell.rpMediaAsset.image = UIImage(data: data!)
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                
                                // TODO::
                                // Set Default
                            }
                        })
                    } else {
                        // Get media preview
                        if let video = object!["videoAsset"] as? PFFile {
                            
                            // Make circular
                            mCell.rpMediaAsset.layer.cornerRadius = mCell.rpMediaAsset.frame.size.width/2
                            mCell.rpMediaAsset.contentMode = .scaleAspectFill
                            mCell.rpMediaAsset.layer.borderColor = UIColor.white.cgColor
                            mCell.rpMediaAsset.layer.borderWidth = 12.00
                            mCell.rpMediaAsset.clipsToBounds = true
                            
                            let videoUrl = NSURL(string: video.url!)
                            do {
                                let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                                let imgGenerator = AVAssetImageGenerator(asset: asset)
                                imgGenerator.appliesPreferredTrackTransform = true
                                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                                mCell.rpMediaAsset.image = UIImage(cgImage: cgImage)
                                
                            } catch let error {
                                print("*** Error generating thumbnail: \(error.localizedDescription)")
                            }

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
                    proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                        if error == nil {
                            // Set pro pic
                            mCell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Set default
                            mCell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
            }
            //
            // If SENDER == <CurrentUser>       &&      RECEIVER == <OtherUser>
            //
            if (self.messageObjects[indexPath.row].object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (self.messageObjects[indexPath.row].object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
                
                // Get and set Profile Photo
                if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                    proPic.getDataInBackground(block: { (data: Data?, error: Error?) in
                        if error == nil {
                            // Set pro pic
                            mCell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Set default
                            mCell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
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
            }
            
            if difference.second! > 0 && difference.minute! == 0 {
                mCell.time.text = "\(difference.second!)s ago"
            }
            
            if difference.minute! > 0 && difference.hour! == 0 {
                mCell.time.text = "\(difference.minute!)m ago"
            }
            
            if difference.hour! > 0 && difference.day! == 0 {
                mCell.time.text = "\(difference.hour!)h ago"
            }
            
            if difference.day! > 0 && difference.weekOfMonth! == 0 {
                mCell.time.text = "\(difference.day!)d ago"
            }
            
            if difference.weekOfMonth! > 0 {
                mCell.time.text = "\(difference.weekOfMonth!)w ago"
            }
            
            if difference.weekOfMonth! > 0 {
                let createdDate = DateFormatter()
                createdDate.dateFormat = "MMM dd"
                mCell.time.text = createdDate.string(from: self.messageObjects[indexPath.row].createdAt!)
            }
            
            
            return mCell
        }
        

    } // end cellForRowAt
    
    
    
    
    
    // MARK: - UITableViewDelegate Method
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    } // end edit boolean
    
    
    func textViewDidChange(_ textView: UITextView) {


    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        
        // (1) Delete Chat
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            // Show Progress
                                            SVProgressHUD.show()
                                            SVProgressHUD.setBackgroundColor(UIColor.white)
                                            
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
                                                                
                                                                // Dismiss progress 
                                                                SVProgressHUD.dismiss()
                                                                
                                                                // Query chats
                                                                self.queryChats()
                                                                
                                                                
                                                            } else {
                                                                print(error?.localizedDescription as Any)
                                                            }
                                                        })
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                    // Error
                                                }
                                            })

                                            
        }
        
        // (2) Like?
        let like = UITableViewRowAction(style: .normal,
                                        title: " Like ") { (UITableViewRowAction, indexPath) in
                                            
                                            
                                            
                                            // TODO::
                                            // Edit Content
                                            
                                            // Close cell
                                            self.tableView!.setEditing(false, animated: true)
                                            
        }

        
        // (3) Block user
        let report = UITableViewRowAction(style: .normal,
                                          title: "Report") { (UITableViewRowAction, indexPath) in
                                            
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
                                                                        tableView.setEditing(false, animated: true)
                                            })
                                            
                                            let no = UIAlertAction(title: "no",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            alert.addAction(yes)
                                            alert.addAction(no)
                                            self.present(alert, animated: true, completion: nil)
                                            
        }
        
        
        
        
        
        // Set background images
        // Red
        delete.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        // Baby blue
        like.backgroundColor = UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0)
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
        
        
        
        // Return specific actions depending on user's object
        if (self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
            return [delete]
        } else {
            return [report]
        }
        

        
    } // End edit action
    

    
    
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
