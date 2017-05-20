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
import SwipeNavigationController
import VIMVideoPlayer

class NewMedia: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, CLImageEditorDelegate {
    
    // MARK: - Class Variables
    var mediaType = String()
    var mediaAsset: PHAsset?
    // data passed via UIImagePickerController
    var mediaURL: URL?
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
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func moreAction(_ sender: Any) {
        
    }
    
    // GLOBAL FUNCTION - Compress video file (open to process video before view loads...)
    open func compressVideo(inputURL: URL, outputURL: URL, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
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
    
    
    
    // FUNCTION - Play Video
    func playVideo() {
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let viewController = UIViewController()
        // Get URL
        if mediaURL != nil {
            // MARK: - VIMVideoPlayer
            let vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
            vimPlayerView.player.isLooping = true
            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimPlayerView.player.setURL(self.mediaURL!)
            vimPlayerView.player.play()
            viewController.view.addSubview(vimPlayerView)
            viewController.view.bringSubview(toFront: vimPlayerView)
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.present(rpPopUpVC, animated: true, completion: nil)
        } else {
        // Get PHAsset
            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = .automatic
            videoOptions.isNetworkAccessAllowed = true
            videoOptions.version = .current
            PHCachingImageManager().requestAVAsset(forVideo: self.mediaAsset!,
                                                   options: videoOptions,
                                                   resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                                                    /* This result handler is performed on a random thread but
                                                     we want to do some UI work so let's switch to the main thread */
                                                    DispatchQueue.main.async(execute: {
                                                        /* Did we get the URL to the video? */
                                                        if let asset = asset as? AVURLAsset{
                                                            
                                                            // MARK: - VIMVideoPlayer
                                                            let vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
                                                            vimPlayerView.player.isLooping = true
                                                            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
                                                            vimPlayerView.player.setURL(asset.url)
                                                            vimPlayerView.player.play()
                                                            viewController.view.addSubview(vimPlayerView)
                                                            viewController.view.bringSubview(toFront: vimPlayerView)
                                                            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
                                                            self.present(rpPopUpVC, animated: true, completion: nil)
                                                            
                                                        }
                                                    })
            })
        }
    }
    
    // FUNCTION - Zoom into Photo
    func zoomPhoto() {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    
    // FUNCTION - Configure IMAGE or VIDEO; Get and set, and add zoom or play video methods...
    func configureAsset() {
        // (1) Configure mediaPreview
        // NOT via UIImagePickerController
        if self.mediaAsset != nil {
            // Set PHImageRequestOptions
            let imageOptions = PHImageRequestOptions()
            imageOptions.deliveryMode = .highQualityFormat
            imageOptions.resizeMode = .exact
            imageOptions.isSynchronous = true
            let targetSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
            // Fetch PHImageManager
            PHImageManager.default().requestImage(for: self.mediaAsset!,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: nil) {
                                                    (img, _) -> Void in
                                                    self.mediaPreview.image = img
            }
        } else {
            // Via UIImagePickerController
            // PHOTO
            if selectedImage != nil {
                self.mediaPreview.image = selectedImage
            } else {
                // VIDEO
                let player = AVPlayer(url: self.mediaURL!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.mediaPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.mediaPreview.contentMode = .scaleAspectFit
                self.mediaPreview.layer.addSublayer(playerLayer)
            }
        }
        
        // (2) Add tap methods and configure editButton
        if self.mediaType == "image" {
            self.editButton.isEnabled = true
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoomPhoto))
            zoomTap.numberOfTapsRequired = 1
            mediaPreview.isUserInteractionEnabled = true
            mediaPreview.addGestureRecognizer(zoomTap)
        } else if self.mediaType == "video" {
            self.editButton.isEnabled = false
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            mediaPreview.isUserInteractionEnabled = true
            mediaPreview.addGestureRecognizer(playTap)
        }
    }
    
    // FUNCTION - Stylize UINavigationBar
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
                self.mediaPreview.makeCircular(forView: self.mediaPreview, borderWidth: 0.5, borderColor: UIColor.white)
            }
        }
        // MARK: - RPExtensions
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - UIView Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UITableView
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure View
        configureView()
        // Configure Assets
        configureAsset()
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

    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textPost.text! == "Say something about this photo..." || self.textPost.text! == "Say something about this video..." {
            self.textPost.text! = ""
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
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
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
