//
//  NewSpacePost.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/7/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import AudioToolbox
import MobileCoreServices
import Photos
import PhotosUI

import Parse
import ParseUI
import Bolts

import SDWebImage
import OneSignal

class NewSpacePost: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextViewDelegate,UITableViewDataSource, UITableViewDelegate, CLImageEditorDelegate {
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    
    // Initialize UIImagePickerController
    var imagePicker: UIImagePickerController!
    
    // String variable to determine mediaType
    var spaceMediaType: String?
    
    // Initialize variable to playVideo if selected
    var spaceVideoData: URL?
    
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func editAction(_ sender: Any) {
        // If photo exists
        if self.mediaAsset.image != nil {
            // MARK: - CLImageEditor
            let editor = CLImageEditor(image: self.mediaAsset.image!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
            tool?.title = "Emoji"
            self.present(editor!, animated: true, completion: nil)
        }
    }
    
    // Function to share
    func postSpace(sender: UIButton) {
        // (1) PHOTO or VIDEO
        if self.mediaAsset.image != nil {
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Sharing...")
            if spaceMediaType == "photo" {
            // PHOTO
                self.sharePhoto()
            } else if spaceMediaType == "video" {
            // VIDEO
                self.shareVideo()
            }
        } else {
            // Check if text is empty
            if self.textView!.text!.isEmpty || self.textView!.text! == "" && mediaAsset.image == nil {
                // MARK: - AudioToolBox; Vibrate Device
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "💩\nSpace Post Failed",
                                                              message: "Please say something about this Space Post.")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = true
                dialogController.showSeparator = true
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.layer.masksToBounds = true
                }
                // Add Skip and verify button
                dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                }))
                
                dialogController.show(in: self)
                
            } else {
                // TEXT POST
                self.shareText()
            }
        }
    }
    
    // Function to share text post
    func shareText() {
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        rpHelpers.showProgress(withTitle: "Sharing...")
        // (1) Save Space Post to Newsfeeds
        let space = PFObject(className: "Newsfeeds")
        space["byUser"] = PFUser.current()!
        space["username"] = PFUser.current()!.username!
        space["contentType"] = "sp"
        space["saved"] = false
        space["textPost"] = self.textView.text!
        space["toUser"] = otherObject.last!
        space["toUsername"] = otherName.last!
        space.saveInBackground {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully shared Space Post: \(space)")
                
                // (2) Send Notification
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = otherObject.last!
                notifications["to"] = otherName.last!
                notifications["type"] = "space"
                notifications["forObjectId"] = space.objectId!
                notifications.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if error == nil {
                        print("Sent Notification: \(notifications)")
                        
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Shared")
                        
                        // Check for user mentions...
                        // Loop through words to check for @ prefixes
                        for var word in self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                            
                            // Define @username
                            if word.hasPrefix("@") {
                                // Get username
                                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                word = word.trimmingCharacters(in: CharacterSet.symbols)
                                
                                // Look for user
                                let user = PFUser.query()!
                                user.whereKey("username", equalTo: word.lowercased())
                                user.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            
                                            // Send mention to Parse server, class "Notifications"
                                            let notifications = PFObject(className: "Notifications")
                                            notifications["from"] = PFUser.current()!.username!
                                            notifications["fromUser"] = PFUser.current()!
                                            notifications["type"] = "tag sp"
                                            notifications["forObjectId"] = space.objectId!
                                            notifications["to"] = word
                                            notifications["toUser"] = object
                                            notifications.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved tag in notifications: \(notifications)")
                                                    
                                                    // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                                    if object.value(forKey: "apnsId") != nil {
                                                        let rpHelpers = RPHelpers()
                                                        _ = rpHelpers.pushNotification(toUser: object, activityType: "tagged you in a Space Post")
                                                    }
                                                    
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
                        }
                        
                        // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                        if otherObject.last!.value(forKey: "apnsId") != nil {
                            let rpHelpers = RPHelpers()
                            _ = rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "shared on your Space")
                        }
                        
                        // Send Notification to otherUser's Profile
                        NotificationCenter.default.post(name: otherNotification, object: nil)
                        // Send Notification to News Feeds
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                        // Pop View Controller
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // Function to share photo
    func sharePhoto() {
        // (1) Save Space Post to Newsfeeds
        let space = PFObject(className: "Newsfeeds")
        space["byUser"] = PFUser.current()!
        space["username"] = PFUser.current()!.username!
        space["contentType"] = "sp"
        space["saved"] = false
        space["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.mediaAsset.image!, 0.5)!)
        // Save textPost
        if self.textView.text! != "" {
            // Set textPost
            space["textPost"] = self.textView.text!
        }
        space["toUser"] = otherObject.last!
        space["toUsername"] = otherName.last!
        space.saveInBackground {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully shared Space Post: \(space)")
                
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showSuccess(withTitle: "Shared")
                
                // (2) Send Notification
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = otherObject.last!
                notifications["to"] = otherName.last!
                notifications["type"] = "space"
                notifications["forObjectId"] = space.objectId!
                notifications.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if error == nil {
                        print("Sent Notification: \(notifications)")
                        
                        // Check for user mentions...
                        // Loop through words to check for @ prefixes
                        for var word in self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                            
                            // Define @username
                            if word.hasPrefix("@") {
                                // Get username
                                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                word = word.trimmingCharacters(in: CharacterSet.symbols)
                                
                                // Look for user
                                let user = PFUser.query()!
                                user.whereKey("username", equalTo: word.lowercased())
                                user.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            
                                            // Send mention to Parse server, class "Notifications"
                                            let notifications = PFObject(className: "Notifications")
                                            notifications["from"] = PFUser.current()!.username!
                                            notifications["fromUser"] = PFUser.current()!
                                            notifications["type"] = "tag sp"
                                            notifications["forObjectId"] = space.objectId!
                                            notifications["to"] = word
                                            notifications["toUser"] = object
                                            notifications.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved tag in notifications: \(notifications)")
                                                    
                                                    // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                                    if object.value(forKey: "apnsId") != nil {
                                                        let rpHelpers = RPHelpers()
                                                        _ = rpHelpers.pushNotification(toUser: object, activityType: "tagged you in a Space Post")
                                                    }
                                                    
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
                        }
                        
                        // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                        if otherObject.last!.value(forKey: "apnsId") != nil {
                            let rpHelpers = RPHelpers()
                            _ = rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "shared on your Space")
                        }
                        
                        // Send Notification to otherUser's Profile
                        NotificationCenter.default.post(name: otherNotification, object: nil)
                        // Send Notification to News Feeds
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                        // Pop View Controller
                        _ = self.navigationController?.popViewController(animated: true)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // Function to share video
    func shareVideo() {
        // Compress video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // Call video compression function
        self.compressVideo(inputURL: spaceVideoData!, outputURL: compressedURL) { (exportSession) in
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
                // Throw
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                // (1) Save Space Post to Newsfeeds
                let space = PFObject(className: "Newsfeeds")
                space["byUser"] = PFUser.current()!
                space["username"] = PFUser.current()!.username!
                space["contentType"] = "sp"
                space["saved"] = false
                space["videoAsset"] = PFFile(name: "video.mp4", data: compressedData as Data)
                // Save textPost
                if self.textView.text! != "" {
                    // Set textPost
                    space["textPost"] = self.textView.text!
                }
                space["toUser"] = otherObject.last!
                space["toUsername"] = otherName.last!
                space.saveInBackground {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully shared Space Post: \(space)")

                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showSuccess(withTitle: "Shared")
                        
                        // Send Notification
                        let notifications = PFObject(className: "Notifications")
                        notifications["fromUser"] = PFUser.current()!
                        notifications["from"] = PFUser.current()!.username!
                        notifications["toUser"] = otherObject.last!
                        notifications["to"] = otherName.last!
                        notifications["type"] = "space"
                        notifications["forObjectId"] = space.objectId!
                        notifications.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if error == nil {
                                print("Sent Notification: \(notifications)")
                                
                                // Check for user mentions...
                                // Loop through words to check for @ prefixes
                                for var word in self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                                    
                                    // Define @username
                                    if word.hasPrefix("@") {
                                        // Get username
                                        word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                        word = word.trimmingCharacters(in: CharacterSet.symbols)
                                        
                                        // Look for user
                                        let user = PFUser.query()!
                                        user.whereKey("username", equalTo: word.lowercased())
                                        user.findObjectsInBackground(block: {
                                            (objects: [PFObject]?, error: Error?) in
                                            if error == nil {
                                                for object in objects! {
                                                    
                                                    // Send mention to Parse server, class "Notifications"
                                                    let notifications = PFObject(className: "Notifications")
                                                    notifications["from"] = PFUser.current()!.username!
                                                    notifications["fromUser"] = PFUser.current()!
                                                    notifications["type"] = "tag sp"
                                                    notifications["forObjectId"] = space.objectId!
                                                    notifications["to"] = word
                                                    notifications["toUser"] = object
                                                    notifications.saveInBackground(block: {
                                                        (success: Bool, error: Error?) in
                                                        if success {
                                                            print("Successfully saved tag in notifications: \(notifications)")
                                                            
                                                            // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                                            if object.value(forKey: "apnsId") != nil {
                                                                let rpHelpers = RPHelpers()
                                                                _ = rpHelpers.pushNotification(toUser: object, activityType: "tagged you in a Space Post")
                                                            }
                                                            
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
                                }
                                
                                // MARK: - RPHelpers; send push notification if user's apnsId is NOT nil
                                if otherObject.last!.value(forKey: "apnsId") != nil {
                                    let rpHelpers = RPHelpers()
                                    _ = rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "shared on your Space")
                                }
                                
                                // Send Notification to otherUser's Profile
                                NotificationCenter.default.post(name: otherNotification, object: nil)
                                // Send Notification to News Feeds
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                                // Pop View Controller
                                _ = self.navigationController?.popViewController(animated: true)
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showError(withTitle: "Network Error")
                    }
                }
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    // Function to compress video data
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        DispatchQueue.main.async {
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
    }
    
    // Function to choose photo
    func choosePhoto(sender: UIButton) {
        // Instnatiate UIImagePickerController
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String), (kUTTypeImage as String)]
        imagePicker.videoMaximumDuration = 180 // Perhaps reduce 180 to 120
        imagePicker.videoQuality = UIImagePickerControllerQualityType.typeHigh
        imagePicker.allowsEditing = true
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        
        // Present UIImagePickerController
        self.navigationController!.present(self.imagePicker, animated: true, completion: nil)
    }
    
    
    // Function to show more sharing options
    func doMore(sender: UIButton) {

        let textToShare = "@\(PFUser.current()!.username!)'s Space Post on Redplanet: \(self.textView.text!)\nhttps://redplanetapp.com/download/"
        
        if self.mediaAsset.image != nil {
            let objectsToShare = [textToShare, self.mediaAsset.image!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)

        } else {
            let objectsToShare = [textToShare]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UIImagePickerController Delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        let pickerMedia = info[UIImagePickerControllerMediaType] as! NSString
        
        
        if pickerMedia == kUTTypeImage {
            // Enable button
            self.editButton.isEnabled = true
            
            // Set String
            spaceMediaType = "photo"
            
            // Set image
            self.mediaAsset.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            
            // Dismiss view controller
            self.dismiss(animated: true, completion: nil)
            
            // MARK: - CLImageEditor
            let editor = CLImageEditor(image: self.mediaAsset.image!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
            tool?.title = "Emoji"
            self.present(editor!, animated: true, completion: nil)
        }
        
        if pickerMedia == kUTTypeMovie {
            
            // Disable button
            self.editButton.isEnabled = false
            
            // Set String
            spaceMediaType = "video"
            
            // Selected Video
            let video = info[UIImagePickerControllerMediaURL] as! URL
            // Instantiate spaceVideoData
            self.spaceVideoData = video
            
            do {
                let asset = AVURLAsset(url: spaceVideoData!, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                self.mediaAsset.image = UIImage(cgImage: cgImage)
            } catch let error {
                print("*** Error generating thumbnail: \(error.localizedDescription)")
            }
            
            // Dismiss
            self.dismiss(animated: true, completion: nil)
        }
        
        // Layout Tap
        self.layoutTaps()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        // Determine if there is no photo or thumbnail
        if self.mediaAsset.image == nil {
            // Disable button
            self.editButton.isEnabled = false
        } else {
            // Enable button
            self.editButton.isEnabled = true
        }
        
        // Dismiss VC
        self.dismiss(animated: true, completion: nil)
    }

    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.mediaAsset.image = image
        
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
        
        // Enable editButton
        self.editButton.isEnabled = true
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })

        // Enable editButton
        self.editButton.isEnabled = true
    }

    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(otherName.last!.uppercased())'s Space"
        }
    }
    
    
    // MARK: - UITextView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.text! == "What are you doing?" {
            self.textView.text! = ""
        }
    }
    

    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        // Define word
        for var word in words {
            // #####################
            if word.hasPrefix("@") {
                
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Find the user
                let fullName = PFUser.query()!
                fullName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                
                let theUsername = PFUser.query()!
                theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                
                let search = PFQuery.orQuery(withSubqueries: [fullName, theUsername])
                search.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        
                        // Clear arrays
                        self.userObjects.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            self.userObjects.append(object)
                        }
                        
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                // show table view and reload data
                self.tableView!.isHidden = false
                self.tableView!.reloadData()
            } else {
                self.tableView!.isHidden = true
            }
        }
        
        return true
    }

    
    // MARK: - UITableView Data Source methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Fetch user's objects
        // (1) Get and set user's profile photo
        if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        // (2) Set user's fullName
        cell.rpUsername.text! = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
        
        return cell
    }
    
    
    
    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Search for @'s
        for var word in self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            // @@@@@@@@@@@@@@@@@@@@@@@@@@@
            if word.hasPrefix("@") {
                
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Replace text
                self.textView.text! = self.textView.text!.replacingOccurrences(of: "\(word)", with: self.userObjects[indexPath.row].value(forKey: "username") as! String, options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        // Hide UITableView
        self.tableView!.isHidden = true
    }
    
    
    
    // MARK: - UIPopOverPresentation Delegate Method
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    
    // Function to play video
    func playVideo() {
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let viewController = UIViewController()
        // MARK: - RPVideoPlayerView
        let rpVideoPlayer = RPVideoPlayerView(frame: viewController.view.bounds)
        rpVideoPlayer.setupVideo(videoURL: spaceVideoData!)
        rpVideoPlayer.playbackLoops = true
        viewController.view.addSubview(rpVideoPlayer)
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
        self.present(rpPopUpVC, animated: true, completion: nil)
    }
    
    
    
    // Function to layout method taps dependednt on whether mediaType is "photo" or "video"
    func layoutTaps() {
        if spaceMediaType == "photo" {
        // PHOTO
            // Add tap to zoom into photo
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(zoomTap)
        } else if spaceMediaType == "video" {
        // VIDEO
            // Add tap to play video
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(playTap)
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable edit button
        self.editButton.isEnabled = false
        
        // Set first responder
        self.textView.becomeFirstResponder()
        
        // Hide tableView
        self.tableView.isHidden = true
        
        // Set mediaAsset's cornerRadius
        self.mediaAsset.layer.cornerRadius = 4.00
        self.mediaAsset.layer.borderColor = UIColor.white.cgColor
        self.mediaAsset.layer.borderWidth = 0.5
        self.mediaAsset.clipsToBounds = true
        
        // Draw corner radius for photosButton
        self.photosButton.layer.cornerRadius = 10.00
        self.photosButton.clipsToBounds = true
        
        // Stylize title
        configureView()
        
        // (1) Add button tap
        let spaceTap = UITapGestureRecognizer(target: self, action: #selector(postSpace))
        spaceTap.numberOfTapsRequired = 1
        self.postButton.isUserInteractionEnabled = true
        self.postButton.addGestureRecognizer(spaceTap)
        
        // (2) Add photo button tap
        let photoTap = UITapGestureRecognizer(target: self, action: #selector(choosePhoto))
        photoTap.numberOfTapsRequired = 1
        self.photosButton.isUserInteractionEnabled = true
        self.photosButton.addGestureRecognizer(photoTap)
        
        // (3) Add more button tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }


}
