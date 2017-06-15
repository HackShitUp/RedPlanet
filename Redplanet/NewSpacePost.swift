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

import OneSignal
import SDWebImage
import VIMVideoPlayer


/*
 UIViewController class that allows users to share posts on other user's posts IF THEY are friends.
 Friends on Redplanet are people who follow back each other (ie: userA follows userB and userB also follows userA).
 */

class NewSpacePost: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, CLImageEditorDelegate {
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    
    // Initialize UIImagePickerController
    var imagePicker: UIImagePickerController!
    // String variable to determine mediaType
    var spaceMediaType: String? = ""
    // Initialize variable to playVideo if selected
    var spaceVideoURL: URL?
    
    
    @IBOutlet weak var mediaPreview: PFImageView!
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
        // MARK: - CLImageEditor
        let editor = CLImageEditor(image: self.mediaPreview.image!)
        editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
        editor?.delegate = self
        let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
        tool?.title = "Emoji"
        self.present(editor!, animated: true, completion: nil)
    }
    
    @IBAction func postSpace(_ sender: Any) {
        // Disable button
        self.postButton.isUserInteractionEnabled = false
        if spaceMediaType == "photo" {
        // PHOTO
            self.sharePhoto()
        } else if spaceMediaType == "video" {
        // VIDEO
            self.shareVideo()
        } else if spaceMediaType == "" {
        // TEXT POST
            if self.textView!.text!.isEmpty || self.textView!.text! == "" && mediaPreview.image == nil {
                // MARK: - AudioToolBox; Vibrate Device
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "💩\nSpace Post Failed",
                                                              message: "Please share something in \(otherName.last!)'s Space.")
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
    
    
    // FUNCTION - Share Text Post
    func shareText() {
        // Create object
        let textSpace = PFObject(className: "Posts")
        textSpace["byUser"] = PFUser.current()!
        textSpace["byUsername"] = PFUser.current()!.username!
        textSpace["contentType"] = "sp"
        textSpace["saved"] = false
        textSpace["textPost"] = self.textView.text!
        textSpace["toUser"] = otherObject.last!
        textSpace["toUsername"] = otherName.last!
        // Save final object
        self.saveFinalObject(object: textSpace)
    }
    
    // FUNCTION - Create PFObject w Photo
    func sharePhoto() {
        // Create PFObject
        let photoSpace = PFObject(className: "Posts")
        photoSpace["byUser"] = PFUser.current()!
        photoSpace["byUsername"] = PFUser.current()!.username!
        photoSpace["contentType"] = "sp"
        photoSpace["saved"] = false
        photoSpace["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.mediaPreview.image!, 0.5)!)
        photoSpace["textPost"] = self.textView.text
        photoSpace["toUser"] = otherObject.last!
        photoSpace["toUsername"] = otherName.last!
        // Save Object
        self.saveFinalObject(object: photoSpace)
    }
    
    // FUNCTION - Create PFObject w Video
    func shareVideo() {
        // Create temporary URL path to store video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        // Compress video
        compressVideo(inputURL: self.spaceVideoURL!, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                rpHelpers.showError(withTitle: "Unknown error exporting video...")
            case .waiting:
                rpHelpers.showError(withTitle: "Exporting video...")
            case .exporting:
                rpHelpers.showProgress(withTitle: "Exporting video...")
            case .completed:
                // Throw and compress video data
                do {
                    let videoData = try Data(contentsOf: compressedURL)
                    // Create PFObject
                    let videoSpace = PFObject(className: "Posts")
                    videoSpace["byUser"] = PFUser.current()!
                    videoSpace["byUsername"] = PFUser.current()!.username!
                    videoSpace["contentType"] = "sp"
                    videoSpace["videoAsset"] = PFFile(name: "video.mp4", data: videoData)
                    videoSpace["saved"] = false
                    videoSpace["textPost"] = self.textView.text!
                    videoSpace["toUser"] = otherObject.last!
                    videoSpace["toUsername"] = otherName.last!
                    DispatchQueue.main.async(execute: {
                        self.saveFinalObject(object: videoSpace)
                    })
                    
                } catch let error {
                    print(error.localizedDescription as Any)
                    rpHelpers.showError(withTitle: "Failed to compress video...")
                }
            case .failed:
                rpHelpers.showError(withTitle: "Failed to compress video...")
            case .cancelled:
                rpHelpers.showError(withTitle: "Cancelled video compression...")
            }
        }
    }
    
    // FUNCTION - Save final object
    func saveFinalObject(object: PFObject) {
        object.saveInBackground { (success: Bool, error: Error?) in
            if success {
                // Send Notification
                let notifications = PFObject(className: "Notifications")
                notifications["fromUser"] = PFUser.current()!
                notifications["from"] = PFUser.current()!.username!
                notifications["toUser"] = otherObject.last!
                notifications["to"] = otherName.last!
                notifications["type"] = "space"
                notifications["forObjectId"] = object.objectId!
                notifications.saveInBackground()
                
                // MARK: - RPHelpers; show banner, check for #'s, check for @'s, and send push notification!
                let rpHelpers = RPHelpers()
                rpHelpers.showSuccess(withTitle: "Shared")
                rpHelpers.checkHash(forObject: object, forText: self.textView.text!)
                rpHelpers.checkTags(forObject: object, forText: self.textView.text!, postType: "sp")
                rpHelpers.pushNotification(toUser: otherObject.last!, activityType: "shared on your Space")
                
                // Re-enable button
                self.postButton.isUserInteractionEnabled = true
                
                // Send Notification to otherUser's Profile
                NotificationCenter.default.post(name: otherNotification, object: nil)
                // Send Notification to News Feeds
                NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
                // Pop View Controller
                _ = self.navigationController?.popViewController(animated: true)
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    // FUNCTION - Zoom into photo
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    // FUNCTION - Play video
    func playVideo() {
        // MARK: - SubtleVolume
        let subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 3)
        subtleVolume.animation = .fadeIn
        subtleVolume.barTintColor = UIColor.black
        subtleVolume.barBackgroundColor = UIColor.white
        
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let viewController = UIViewController()
        // MARK: - VIMVideoPlayer
        let vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
        vimPlayerView.player.isLooping = true
        vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
        vimPlayerView.player.setURL(spaceVideoURL)
        vimPlayerView.player.play()
        viewController.view.addSubview(vimPlayerView)
        viewController.view.bringSubview(toFront: vimPlayerView)
        viewController.view.addSubview(subtleVolume)
        viewController.view.bringSubview(toFront: subtleVolume)
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
        self.present(rpPopUpVC, animated: true, completion: nil)
    }
    
    // FUNCTION - Compress video file (open to process video before view loads...)
    func compressVideo(inputURL: URL, outputURL: URL, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
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

    @IBAction func selectAsset(_ sender: Any) {
        // Create UIImagePickerController
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
        self.navigationController?.present(self.imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func moreAction(_ sender: Any) {
        let textToShare = "@\(PFUser.current()!.username!)'s Space Post on Redplanet: \(self.textView.text!)\nhttps://redplanetapp.com/download/"
        if self.mediaPreview.image != nil {
            let objectsToShare = [textToShare, self.mediaPreview.image!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
            
        } else {
            let objectsToShare = [textToShare]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    // FUNCTION - Stylize and set title of navigation bar
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
    
    // MARK: - CLImageEditor Delegate Methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.mediaPreview.image = image
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in
            // Enable editButton
            self.editButton.isEnabled = true
        })
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in
            // Enable editButton
            self.editButton.isEnabled = true
        })
    }

    
    // MARK: - UIView Life Cycle
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable editButton
        self.editButton.isEnabled = false
        
        // Configure UITextView
        textView.delegate = self
        textView.becomeFirstResponder()
        textView.textColor = UIColor.darkGray
        textView.text = "Sharing in \(otherObject.last!.value(forKey: "realNameOfUser") as! String)'s Space..."
        
        // Hide UITableView
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        // Register NIB
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        // MARK: - RPExtensions
        mediaPreview.roundAllCorners(sender: self.mediaPreview)
        mediaPreview.layer.borderColor = UIColor.white.cgColor
        mediaPreview.layer.borderWidth = 0.5
        
        // Draw corner radius for photosButton
        photosButton.layer.cornerRadius = 10.00
        photosButton.clipsToBounds = true
        
        // Stylize title
        configureView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UIImagePickerController Delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if info[UIImagePickerControllerMediaType] as! NSString == kUTTypeImage {
            // Enable button
            self.editButton.isEnabled = true
            // Set String
            spaceMediaType = "photo"
            // Set image
            self.mediaPreview.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            // Dismiss view controller
            self.dismiss(animated: true, completion: nil)
            // MARK: - CLImageEditor
            let editor = CLImageEditor(image: self.mediaPreview.image!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
            tool?.title = "Emoji"
            // Present
            self.present(editor!, animated: true, completion: {
            // PHOTO; Add tap to zoom into photo
                let zoomTap = UITapGestureRecognizer(target: self, action: #selector(self.zoom))
                zoomTap.numberOfTapsRequired = 1
                self.mediaPreview.isUserInteractionEnabled = true
                self.mediaPreview.addGestureRecognizer(zoomTap)
            })
            
        } else if info[UIImagePickerControllerMediaType] as! NSString == kUTTypeMovie {
            // Disable button
            self.editButton.isEnabled = false
            // Set String
            spaceMediaType = "video"
            // Pass URL to instantiated variable
            self.spaceVideoURL = (info[UIImagePickerControllerMediaURL] as! URL)
            // MARK: - AVPlayer; Add video preview
            let player = AVPlayer(url: self.spaceVideoURL!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.mediaPreview.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.mediaPreview.contentMode = .scaleAspectFit
            self.mediaPreview.layer.addSublayer(playerLayer)
            player.isMuted = true
            player.play()
            // Dismiss
            self.dismiss(animated: true, completion: { 
            // VIDEO; Add tap to play video
                let playTap = UITapGestureRecognizer(target: self, action: #selector(self.playVideo))
                playTap.numberOfTapsRequired = 1
                self.mediaPreview.isUserInteractionEnabled = true
                self.mediaPreview.addGestureRecognizer(playTap)
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Determine if there is no photo or thumbnail
        if self.mediaPreview.image == nil {
            // Disable button
            self.editButton.isEnabled = false
        } else {
            // Enable button
            self.editButton.isEnabled = true
        }
        // Dismiss VC
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIPopOverPresentation Delegate Method
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: - UITextView Delegate Methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.textColor == UIColor.darkGray {
            self.textView.text! = ""
            self.textView.textColor = UIColor.black
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Access UITextView's content, and get the LAST WORD/TEXT entered
        let stringsSeparatedBySpace = textView.text.components(separatedBy: " ")
        // Then, check whether the last word/text has a "@" prefix...
        var lastString = stringsSeparatedBySpace.last!
        if lastString.hasPrefix("@") {
            // Cut all symbols
            lastString = lastString.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            lastString = lastString.trimmingCharacters(in: CharacterSet.symbols)
            // Find the user
            let realNameOfUser = PFUser.query()!
            realNameOfUser.whereKey("realNameOfUser", matchesRegex: "(?i)" + lastString)
            let username = PFUser.query()!
            username.whereKey("username", matchesRegex: "(?i)" + lastString)
            let search = PFQuery.orQuery(withSubqueries: [realNameOfUser, username])
            search.limit = 100000
            search.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.userObjects.removeAll(keepingCapacity: false)
                    for object in objects! {
                        self.userObjects.append(object)
                    }
                    
                    // Show UITableView and reloadData in main thread
                    DispatchQueue.main.async {
                        self.tableView?.isHidden = false
                        self.tableView?.reloadData()
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        } else {
            self.tableView!.isHidden = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        // (1) Set realNameOfUser
        cell.rpFullName.text! = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
        // (2) Set username
        cell.rpUsername.text! = self.userObjects[indexPath.row].value(forKey: "username") as! String
        // (3) Get and set userProfilePicture
        if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_showActivityIndicatorView()
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        return cell
    }
    
    
    
    // MARK: - UITableView Delegeate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Access UITextView's content, and get the LAST WORD/TEXT entered
        let stringsSeparatedBySpace = textView.text.components(separatedBy: " ")
        // Then, check whether the last word/text has a "@" prefix...
        var lastString = stringsSeparatedBySpace.last!
        if lastString.hasPrefix("@") {
            // Cut all symbols
            lastString = lastString.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            lastString = lastString.trimmingCharacters(in: CharacterSet.symbols)
            // Replace text
            if let username = self.userObjects[indexPath.row].value(forKey: "username") as? String {
                self.textView.text = self.textView.text.replacingOccurrences(of: "\(lastString)", with: username, options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        // Hide UITableView
        self.tableView!.isHidden = true
    }
    
}
