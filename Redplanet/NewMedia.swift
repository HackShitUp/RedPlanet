//
//  NewMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import Photos

import Parse
import ParseUI
import Bolts

import OneSignal
import SDWebImage
import SwipeNavigationController
import VIMVideoPlayer

/*
 UIViewController that presents the selected photo or video from "Library.swift"
 Also allows editing options if the selected asset was a photo. This class pushes to "ShareWith.swift" for sharing options.
 */

class NewMedia: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, CLImageEditorDelegate {
    
    // MARK: - Class Variables
    var mediaType = String()
    // Selected PHAsset and assetURL to pass selectedURL or PHAsset's URL to...
    var mediaAsset: PHAsset?
    var assetURL: URL?
    // Data passed from UIImagePickerController
    var selectedURL: URL?
    var selectedImage: UIImage?
    
    // Initialized CGRect for keyboard frame
    var keyboard = CGRect()
    // Array to hold user's objects
    var userObjects = [PFObject]()


    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var textPost: UITextView!
    @IBAction func back(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editAction(_ sender: Any) {
        // MARK: - CLImageEditor; Modified "CLEmoticonTool" title
        let editor = CLImageEditor(image: self.mediaPreview.image!)
        editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
        editor?.delegate = self
        let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
        tool?.title = "Emoji"
        self.present(editor!, animated: true, completion: nil)
    }
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func moreAction(_ sender: Any) {
        if mediaType == "image" {
            // Photo to Share
            let textToShare = "@\(PFUser.current()!.username!)'s Photo on Redplanet: \(self.textPost.text!)\nhttps://redplanetapp.com/download/"
            let objectsToShare = [textToShare, self.mediaPreview.image!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        } else if mediaType == "video" {
            // Traverse video url to DATA
            let textToShare = "@\(PFUser.current()!.username!)'s Video on Redplanet: \(self.textPost.text!)\nhttps://redplanetapp.com/download/"
            let videoData = NSData(contentsOf: self.assetURL!)
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let docDirectory = paths[0]
            let filePath = "\(docDirectory)/tmpVideo.mov"
            videoData?.write(toFile: filePath, atomically: true)
            let videoLink = NSURL(fileURLWithPath: filePath)
            let objectsToShare = [textToShare, videoLink] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.setValue("Video", forKey: "subject")
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var shareButton: UIButton!
    @IBAction func shareAction(_ sender: Any) {
        // Handle caption
        if self.textPost.text == "Say something about this photo..." || self.textPost.text == "Say something about this video..." {
            self.textPost.text = ""
        }
        // Share Photo or Video
        if self.mediaType == "image" {
            sharePhoto()
        } else if self.mediaType == "video" {
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Compressing Video...")
            shareVideo()
        }
    }
    
    // FUNCTION - Share photo
    func sharePhoto() {
        // Create PFObject
        let photo = PFObject(className: "Posts")
        photo["byUser"] = PFUser.current()!
        photo["byUsername"] = PFUser.current()!.username!.lowercased()
        photo["contentType"] = "ph"
        photo["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.mediaPreview.image!, 0.5)!)
        photo["textPost"] = self.textPost.text
        photo["saved"] = false
        // Append PFObject
        shareWithObject.append(photo)
        let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
        self.navigationController?.pushViewController(shareWithVC, animated: true)
    }
    
    // FUNCTION - Share video
    func shareVideo() {
        // Create temporary URL path to store video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // MARK: - RPHelpers
        let rpHelpers = RPHelpers()
        // Compress video
        compressVideo(inputURL: self.assetURL!, outputURL: compressedURL) { (exportSession) in
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
                    let videoFile = PFFile(name: "video.mp4", data: videoData)
                    // Create PFObject
                    let video = PFObject(className: "Posts")
                    video["byUser"] = PFUser.current()!
                    video["byUsername"] = PFUser.current()!.username!.lowercased()
                    video["contentType"] = "vi"
                    video["videoAsset"] = videoFile
                    video["textPost"] = self.textPost.text
                    video["saved"] = false
                    DispatchQueue.main.async(execute: {
                        // Append PFObject
                        shareWithObject.append(video)
                        let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
                        self.navigationController?.pushViewController(shareWithVC, animated: true)
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
 
    
    // MARK: - Interactive Functions; Zoom Photo or Play Video
    // FUNCTION - Zoom into Photo
    func zoomPhoto() {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    // FUNCTION - Play Video
    func playVideo() {
        // MARK: - SubtleVolume
        let subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 3)
        subtleVolume.animation = .fadeIn
        subtleVolume.barTintColor = UIColor.black
        subtleVolume.barBackgroundColor = UIColor.white
        self.view.addSubview(subtleVolume)
        
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let viewController = UIViewController()
        // MARK: - VIMVideoPlayer
        let vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
        vimPlayerView.player.isLooping = true
        vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
        vimPlayerView.player.setURL(self.assetURL!)
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
    
    // FUNCTION - Stylize UINavigationBar, and configure UI
    func configureView() {
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary = [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: navBarFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            if mediaType == "image" {
                self.title = "New Photo"
                self.textPost.text! = "Say something about this photo..."
                // MARK: - RPExtensions
                self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
            } else {
                self.title = "New Video"
                self.textPost.text! = "Say something about this video..."
                // MARK: - RPExtensions
                self.mediaPreview.makeCircular(forView: self.mediaPreview, borderWidth: 0, borderColor: UIColor.clear)
            }
        }
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - CLImageEditorDelegate
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        editor.dismiss(animated: true) {
            self.mediaPreview.image = image
        }
    }
    
    // MARK: - UIView Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Configure View
        configureView()
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure mediaPreview
        if selectedImage != nil {
        // IMAGE via UIImagePickerController
            self.mediaPreview.image = self.selectedImage
            configureImageTap()
        } else if self.selectedURL != nil {
        // Video via UIImagePickerController
            manageVideoAsset(withURL: self.selectedURL!)
        } else {
        // PHAsset
            if self.mediaType == "image" {
                manageImageAsset()
            } else if self.mediaType == "video" {
                manageVideoAsset(withURL: nil)
            }
        }
        
        // Configure UITableView
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        
        // Set UITextView delegate
        textPost.delegate = self
        
        // Implement back swipe method
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(back))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Resign firest responder
        self.textPost.resignFirstResponder()
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
            if self.menuView.frame.origin.y == self.menuView.frame.origin.y {
                // Move menuView up
                self.menuView.frame.origin.y -= self.keyboard.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        if self.menuView!.frame.origin.y != self.view.frame.size.height - self.menuView.frame.size.height {
            // Move menuView down
            self.menuView.frame.origin.y += self.keyboard.height
        }
    }

    
    
    // MARK: - UITextView Delegate Methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textPost.text! == "Say something about this photo..." || self.textPost.text! == "Say something about this video..." {
            self.textPost.text! = ""
            self.textPost.textColor = UIColor.black
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let words: [String] = self.textPost.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
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
                // Show UITableView and reload data in main thread
                DispatchQueue.main.async {
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                }
            } else {
                self.tableView.isHidden = true
            }
        }
        return true
    }
    
    
    
    // MARK: - UITableView DataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("UserCell", owner: self, options: nil)?.first as! UserCell
        
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
    
    
    // MARK: - UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Loop through words
        for var word in self.textPost.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            // @@@@@@@@@@@@@@@@@@@@@@@@@@@
            if word.hasPrefix("@") {
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                // Replace text
                self.textPost.text! = self.textPost.text!.replacingOccurrences(of: "\(word)", with: self.userObjects[indexPath.row].value(forKey: "username") as! String, options: String.CompareOptions.literal, range: nil)
            }
        }
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        // Hide UITableView
        self.tableView.isHidden = true
    }



}



/*
 MARK: - NewMedia Extensions; Manages PHAsset and shows image or video previews...
 • manageImageAsset()
 • configureImageTap()
 • manageVideoAsset()
 */
extension NewMedia {
    // FUNCTION - Get image from PHAsset
    func manageImageAsset() {
        // Set up PHImageRequestOptions
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .exact
        imageOptions.isSynchronous = true
        let targetSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
        // Fetch image
        PHImageManager.default().requestImage(for: self.mediaAsset!, targetSize: targetSize, contentMode: .aspectFill,
                                              options: nil) {
                                                (assetImage, _) -> Void in
                                                self.mediaPreview.image = assetImage
        }
        // Add tap method to zoom into photo
        self.configureImageTap()
    }
    
    // FUNCTION - Add tap methods to zoom into photo
    func configureImageTap() {
        // Configure editButton
        self.editButton.isEnabled = true
        // Add tap method to zoom
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoomPhoto))
        zoomTap.numberOfTapsRequired = 1
        mediaPreview.isUserInteractionEnabled = true
        mediaPreview.addGestureRecognizer(zoomTap)
    }
    
    
    // FUNCTION - Get video from PHAsset
    func manageVideoAsset(withURL: URL?) {
        if withURL != nil {
            self.assetURL = withURL!
            // MARK: - AVPlayer
            let player = AVPlayer(url: self.selectedURL!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.mediaPreview.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.mediaPreview.contentMode = .scaleAspectFit
            self.mediaPreview.layer.addSublayer(playerLayer)
        } else {
            // Set up PHVideoRequestOptions
            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = .automatic
            videoOptions.isNetworkAccessAllowed = true
            videoOptions.version = .original
            PHCachingImageManager().requestAVAsset(forVideo: self.mediaAsset!, options: videoOptions,
                                                   resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                                                    /* Did we get the URL to the video? */
                                                    // Execute in configuration in main thread to minimize wait time...
                                                    DispatchQueue.main.async(execute: {
                                                        if let asset = asset as? AVURLAsset{
                                                            self.assetURL = asset.url
                                                            let player = AVPlayer(url: self.assetURL!)
                                                            let playerLayer = AVPlayerLayer(player: player)
                                                            playerLayer.frame = self.mediaPreview.bounds
                                                            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                                                            self.mediaPreview.contentMode = .scaleAspectFit
                                                            self.mediaPreview.layer.addSublayer(playerLayer)
                                                        }
                                                    })
            })
        }
        // Disable editButton
        self.editButton.isEnabled = false
        // Add tap method to play video
        let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
        playTap.numberOfTapsRequired = 1
        mediaPreview.isUserInteractionEnabled = true
        mediaPreview.addGestureRecognizer(playTap)
    }
}
