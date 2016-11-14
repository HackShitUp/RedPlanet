//
//  RPChatRoom.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
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

    
    // Variable to hold UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    
    // Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newChat: UITextView!
    
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
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
//        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)
    }
    
    // Query all of the user's chats
    func queryChats() {
        let chats = PFQuery(className: "Chats")
        chats.includeKey("receiver")
        chats.includeKey("sender")
//        chats.order(byAscending: "createdAt")
        chats.order(byDescending: "createdAt")
        chats.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.messageObjects.removeAll(keepingCapacity: false)
                
                // Append Objects
                for object in objects! {
                    // IF SENDER == PFUser.currentUser()!
                    // AND RECEIVER == OtherUser
                    if object["sender"] as! PFUser == PFUser.current()! && object["receiver"] as! PFUser == chatUserObject.last! {
                        self.messageObjects.append(object)
                    }
                    
                    
                    // IF RECEIVER == PFUser.currentUser()!
                    // AND SENDER == OtherUser
                    if object["receiver"] as! PFUser == PFUser.current()! && object["sender"] as! PFUser == chatUserObject.last! {
                        self.messageObjects.append(object)
                    }
                }
                
                print("Message objects: \(self.messageObjects.count)")
                
            } else {
                print(error?.localizedDescription as Any)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    // Function to send chat
    func sendChat() {
        // Send to Chats
        let chat = PFObject(className: "Chats")
        chat["sender"] = PFUser.current()!
        chat["senderUsername"] = PFUser.current()!.username!
        chat["receiver"] = chatUserObject.last!
        chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chat["Message"] = self.newChat.text!
        chat["read"] = false
        chat.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                print("Successfully sent chat: \(chat)")
                
                // Clear newChat
                self.newChat.text!.removeAll()
                
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
                
                // Failed
                // TODO::??
                // Show Alert?
                
                // Reload data
                self.queryChats()
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
    
        // Selected image
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage

        // Dimsiss VC
        self.dismiss(animated: true, completion: nil)
        
        // CLImageEditor
        let editor = CLImageEditor(image: image)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    
    
    
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        
        // Show Progress
        SVProgressHUD.show()
        
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
                print("Successfully sent chat: \(chat)")
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear newChat
                self.newChat.text!.removeAll()
                
                
                // Handle optional chaining
                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                    // MARK: - OneSignal
                    // Send Push Notification to user
                    OneSignal.postNotification(
                        ["contents":
                            ["en": "from \(PFUser.current()!.username!)"],
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
                
                print("Network Error")
                
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
    

    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        
        // Query Chats
        queryChats()

        // Send push notification
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationUserDidTakeScreenshot,
                                               object: nil,
                                               queue: OperationQueue.main) { notification in
                                                
                                                // Send push notification
                                                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                                                    OneSignal.postNotification(
                                                        ["contents":
                                                            ["en": "\(PFUser.current()!.username!) screenshotted the conversation"],
                                                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"]
                                                        ]
                                                    )
                                                }
        }
        
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true

        // Set tableView height
        self.tableView!.estimatedRowHeight = 60
        // Scroll to bottom of tableView
        self.tableView!.contentOffset = CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude)

        // Set title
        self.title = "\(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)"

        // Set placeholder for newChat
        self.newChat.text! = "Chatting with \(chatUserObject.last!.value(forKey: "realNameOfUser") as! String)..."
        
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
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        
        // Add Photo Library method to photosButton
        let photosTap = UITapGestureRecognizer(target: self, action: #selector(accessPhotos))
        photosTap.numberOfTapsRequired = 1
        self.photosButton.isUserInteractionEnabled = true
        self.photosButton.addGestureRecognizer(photosTap)
        
        
        
        // Add Function Method to add user's read recipets
        let sender = PFQuery(className: "Chats")
        sender.whereKey("sender", equalTo: PFUser.current()!)
        sender.whereKey("receiver", equalTo: chatUserObject.last!)
        
        let receiver = PFQuery(className: "Chats")
        receiver.whereKey("receiver", equalTo: PFUser.current()!)
        receiver.whereKey("sender", equalTo: chatUserObject.last!)
        
        let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
        chats.includeKey("sender")
        chats.includeKey("receiver")
        chats.order(byDescending: "createdAt")
        chats.getFirstObjectInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                
                // Get user's first object
                if object!["receiver"] as!  PFUser == PFUser.current()! {
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
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set first responder
        self.newChat.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UIKeyboard Notification
    func keyboardWillShow(notification: NSNotification) {
        // Define keyboard frame size
        keyboard = ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
        
        
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // Raise Text View
//            self.frontView.frame.origin.y = self.tableView.frame.size.height - self.keyboard.height
            self.frontView.frame.origin.y -= self.keyboard.height
            

            print("TABLEVIEW HEIGHT: \(self.tableView!.frame.size.height)")
            print("NEWCHAT Y ORIGIN: \(self.newChat.frame.origin.y)")
            print("FrontView y origin: \(self.frontView.frame.origin.y)")
            print("Scroll view's frame: \(self.tableView.frame)")
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Move UI up
        UIView.animate(withDuration: 0.4) { () -> Void in
            
            // Lower Text View
//            self.frontView.frame.origin.y = self.tableView.frame.size.height
            self.frontView.frame.origin.y += self.keyboard.height

            
            print("newchat frame: \(self.newChat.frame.origin.y)")
            print("Scroll view's frame: \(self.tableView.frame)")
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear placeholder
        self.newChat.text! = ""
    }
    
    
    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Resign chat
        self.newChat.resignFirstResponder()
    }
    
    
    

    // MARK: - UITableViewDataSource and Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of cells: \(self.messageObjects.count)")
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
        
        
        if messageObjects[indexPath.row].value(forKey: "photoAsset") == nil {
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
            if self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! {
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
            if messageObjects[indexPath.row].value(forKey: "receiver") as! PFUser == PFUser.current()! && messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == chatUserObject.last! {
                
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
            if messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! && messageObjects[indexPath.row].value(forKey: "receiver") as! PFUser == chatUserObject.last! {
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
            ///                       ///
            /// Return Media Cell    ///
            ///                     ///
            //////////////////////////
            
            
            // Set layouts
            mCell.rpUserProPic.layoutIfNeeded()
            mCell.rpUserProPic.layoutSubviews()
            mCell.rpUserProPic.setNeedsLayout()
            mCell.rpUserProPic.layer.cornerRadius = mCell.rpUserProPic.frame.size.width/2
            mCell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            mCell.rpUserProPic.layer.borderWidth = 0.5
            mCell.rpUserProPic.clipsToBounds = true
            
            
            // (1) Set usernames depending on who sent what
            if self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! {
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
                                
                                // Set Media Asset
                                mCell.rpMediaAsset.image = UIImage(data: data!)
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                
                                // TODO::
                                // Set Default
                            }
                        })
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
            
            // Fetch objects
            // (3) Set usernames depending on who sent what
            if self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! {
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
            if messageObjects[indexPath.row].value(forKey: "receiver") as! PFUser == PFUser.current()! && messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == chatUserObject.last! {
                
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
            if messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! && messageObjects[indexPath.row].value(forKey: "receiver") as! PFUser == chatUserObject.last! {
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
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        
        // (1) Delete Chat
        let delete = UITableViewRowAction(style: .normal,
                                          title: "Delete") { (UITableViewRowAction, indexPath) in
                                            
                                            // Show Progress
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
        delete.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        // Baby blue
        like.backgroundColor = UIColor(red:0.04, green:0.60, blue:1.00, alpha:1.0)
        // Yellow
        report.backgroundColor = UIColor(red:1.00, green:0.84, blue:0.00, alpha:1.0)
        
        
        
        // Return specific actions depending on user's object
        if self.messageObjects[indexPath.row].value(forKey: "sender") as! PFUser == PFUser.current()! {
            return [delete]
        } else {
            return [report]
        }
        
        
        
        
    } // End edit action
    



}
