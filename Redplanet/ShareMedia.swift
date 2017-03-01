//
//  ShareMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/29/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
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
import SVProgressHUD

// Array to hold photo or video from library; PHAsset
var shareMediaAsset = [PHAsset]()

// When selected via UIImagePickerController; UIImage
var shareImageAssets = [UIImage]()

// URL to hold video data; when selected via UIImagePcikerController; URL
var instanceVideoData: URL?

// Media Type
// Photo or Video
var mediaType: String?

class ShareMedia: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, CLImageEditorDelegate, CLImageEditorTransitionDelegate, SwipeNavigationControllerDelegate {

    // Array to hold user's objects for @
    var userObjects = [PFObject]()
    
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var mediaCaption: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: false)
    }

    @IBAction func moreButton(_ sender: Any) {
        
        if mediaType == "photo" {
            // Photo to Share
            let textToShare = "@\(PFUser.current()!.username!)'s Photo on Redplanet: \(self.mediaCaption.text!)\nhttps://redplanetapp.com/download/"
            let objectsToShare = [textToShare, self.mediaAsset.image!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        } else if mediaType == "video" {
            // Traverse video url to DATA
            let textToShare = "@\(PFUser.current()!.username!)'s Video on Redplanet: \(self.mediaCaption.text!)\nhttps://redplanetapp.com/download/"
            if shareMediaAsset.isEmpty {
                // INSTANCEVIDEODATA
                let videoData = NSData(contentsOf: instanceVideoData!)
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let docDirectory = paths[0]
                let filePath = "\(docDirectory)/tmpVideo.mov"
                videoData?.write(toFile: filePath, atomically: true)
                let videoLink = NSURL(fileURLWithPath: filePath)
                let objectsToShare = [textToShare, videoLink] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                activityVC.setValue("Video", forKey: "subject")
                self.present(activityVC, animated: true, completion: nil)
            } else {
                // PHASSET
                // Set video options
                let videoOptions = PHVideoRequestOptions()
                videoOptions.deliveryMode = .automatic
                videoOptions.isNetworkAccessAllowed = true
                videoOptions.version = .current
                PHCachingImageManager().requestAVAsset(forVideo: shareMediaAsset.last!,
                                                       options: videoOptions,
                                                       resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                                                        /* Did we get the URL to the video? */
                                                        if let asset = asset as? AVURLAsset{
                                                            let videoData = NSData(contentsOf: asset.url)
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
                })
            }
        }
    }

    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBAction func editPhoto(_ sender: AnyObject) {
        // Present CLImageEditor
        let editor = CLImageEditor(image: self.mediaAsset.image!)
        editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    // MARK: - CLImageEditorDelegate
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        self.mediaAsset.image = image
        editor.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBOutlet weak var shareButton: UIButton!
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        if mediaType == "photo" {
            // Mark: - Agrume
            let agrume = Agrume(image: self.mediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
            agrume.showFrom(self)
        } else {
            
            // Play the Video
            playVideo()
        }
    }
    
    
    
    
    // Play V I D E O
    func playVideo() {
        
        // Set video options
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .automatic
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.version = .current
        
        
        if shareMediaAsset.isEmpty {
            // URL
            // MARK: - VideoViewController
            let videoViewController = VideoViewController(videoURL: instanceVideoData!)
            videoViewController.modalPresentationStyle = .popover
            videoViewController.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
            
            
            
            let popOverVC = videoViewController.popoverPresentationController
            popOverVC?.permittedArrowDirections = .any
            popOverVC?.delegate = self
            popOverVC?.sourceView = self.mediaAsset
            popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            
            
            self.present(videoViewController, animated: true, completion: nil)
            
        } else {
            // PHASSET
            PHCachingImageManager().requestAVAsset(forVideo: shareMediaAsset.last!,
                                                   options: videoOptions,
                                                   resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                                                    
                                                    /* This result handler is performed on a random thread but
                                                     we want to do some UI work so let's switch to the main thread */
                                                    
                                                    DispatchQueue.main.async(execute: {
                                                        
                                                        /* Did we get the URL to the video? */
                                                        if let asset = asset as? AVURLAsset{
                                                            
                                                            
                                                            // MARK: - VideoViewController
                                                            let videoViewController = VideoViewController(videoURL: asset.url)
                                                            videoViewController.modalPresentationStyle = .popover
                                                            videoViewController.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
                                                            
                                                            
                                                            
                                                            let popOverVC = videoViewController.popoverPresentationController
                                                            popOverVC?.permittedArrowDirections = .any
                                                            popOverVC?.delegate = self
                                                            popOverVC?.sourceView = self.mediaAsset
                                                            popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                                                            
                                                            
                                                            self.present(videoViewController, animated: true, completion: nil)
                                                            
                                                            
                                                        } else {
                                                            // Did not get the AVAssetUrl
                                                            print("This is not a URL asset. Cannot play")
                                                        }
                                                        
                                                    })
            })

        }
        
    }

    // MARK: - UIModalPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            if mediaType == "photo" {
                self.title = "New Photo"
            } else {
                self.title = "New Video"
            }
            self.mediaCaption.text! = "Say something about this \(mediaType!)..."
            
        }
        
        // * Show navigation bar and tab bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, willShowEmbeddedViewForPosition position: Position) {
        // Resign keyboard
        self.mediaCaption.resignFirstResponder()
        // Release data
        shareMediaAsset.removeAll(keepingCapacity: false)
        shareImageAssets.removeAll(keepingCapacity: false)
        mediaType = nil
        instanceVideoData = nil
        // Reload data
        NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - SwipeNavigationController
    func swipeNavigationController(_ controller: SwipeNavigationController, didShowEmbeddedViewForPosition position: Position) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide tableView on load
        self.tableView!.isHidden = true
        self.tableView!.allowsSelection = true
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        
        // Add tap methods depnding on mediaType
        if mediaType == "photo" {
            // Enable edit button
            editBarButton.isEnabled = true
            // Tap method to share Photo
            let shareTap = UITapGestureRecognizer(target: self, action: #selector(sharePhotoData))
            shareTap.numberOfTapsRequired = 1
            self.shareButton.isUserInteractionEnabled = true
            self.shareButton.addGestureRecognizer(shareTap)
        } else if mediaType == "video" {
            // Disable edit button
            editBarButton.isEnabled = false
            // Tap method to share VIDEO
            if shareMediaAsset.isEmpty {
                let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareLibVideo))
                shareTap.numberOfTapsRequired = 1
                self.shareButton.isUserInteractionEnabled = true
                self.shareButton.addGestureRecognizer(shareTap)
            } else {
                let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareVideoData))
                shareTap.numberOfTapsRequired = 1
                self.shareButton.isUserInteractionEnabled = true
                self.shareButton.addGestureRecognizer(shareTap)
            }
        }
        
        // add delegate for mediaCaption
        self.mediaCaption.delegate = self
        
        // MARK:- SwipeNavigationController
        self.containerSwipeNavigationController?.delegate = self
        
        // (1) Make shareButton circular
        self.shareButton.layer.cornerRadius = self.shareButton.frame.size.width/2
        self.shareButton.layer.borderColor = UIColor.lightGray.cgColor
        self.shareButton.layer.borderWidth = 0.5
        self.shareButton.clipsToBounds = true
        
        // (2) Add rounded corners and set clip within bounds
        self.mediaAsset.layer.cornerRadius = 6.0
        self.mediaAsset.layer.borderColor = UIColor.white.cgColor
        self.mediaAsset.layer.borderWidth = 0.5
        self.mediaAsset.clipsToBounds = true
        
        // (3) Set image
        // Set Image Request Options
        // Cancel pixelation
        // with Synchronous call
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .exact
        imageOptions.isSynchronous = true
        // Set preferred size
        let targetSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        
        // Check whether the image was...
        // (A) Taken
        // (B) Selected from collection or photo library
        // Then, set image
        
        // PHOTO
        // PHAsset
        if shareMediaAsset.count != 0 {
            PHImageManager.default().requestImage(for: shareMediaAsset.last!,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFill,
                                                  options: nil) {
                                                    (img, _) -> Void in
                                                    // Set image
                                                    // Selected from library
                                                    self.mediaAsset.image = img
            }
        } else if shareImageAssets.count != 0 {
            // PHOTO
            // UIImage
            // Set image
            // photo selected from UIImagePickerController
            self.mediaAsset.image = shareImageAssets.last!
        } else {
            // VIDEO
            // Load Video Preview and Play Video
            let player = AVPlayer(url: instanceVideoData!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.mediaAsset.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.mediaAsset.contentMode = .scaleAspectFit
            self.mediaAsset.layer.addSublayer(playerLayer)
        }
        
        
        // (4) Stylize title
        configureView()
        
        // (5) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Set placeholder depending on mediaType
        self.mediaCaption.text! = "Say something about this \(mediaType!)..."
        // Add tap methods depnding on mediaType
        if mediaType == "photo" {
            // Enable edit button
            editBarButton.isEnabled = true
            // Tap method to share Photo
            let shareTap = UITapGestureRecognizer(target: self, action: #selector(sharePhotoData))
            shareTap.numberOfTapsRequired = 1
            self.shareButton.isUserInteractionEnabled = true
            self.shareButton.addGestureRecognizer(shareTap)
        } else if mediaType == "video" {
            // Disable edit button
            editBarButton.isEnabled = false
            // Tap method to share VIDEO
            if shareMediaAsset.isEmpty {
                let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareLibVideo))
                shareTap.numberOfTapsRequired = 1
                self.shareButton.isUserInteractionEnabled = true
                self.shareButton.addGestureRecognizer(shareTap)
            } else {
                let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareVideoData))
                shareTap.numberOfTapsRequired = 1
                self.shareButton.isUserInteractionEnabled = true
                self.shareButton.addGestureRecognizer(shareTap)
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.mediaCaption.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }
    
    // Function to share photo data
    func sharePhotoData() {
        
        // MARK: - HEAP
        Heap.track("SharedPhoto", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        
        // Clear caption
        if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
            self.mediaCaption.text! = ""
        }
        
        // Save to Newsfeeds
        let newsfeeds = PFObject(className: "Newsfeeds")
        newsfeeds["username"] = PFUser.current()!.username!
        newsfeeds["byUser"] = PFUser.current()!
        newsfeeds["photoAsset"] = PFFile(data: UIImageJPEGRepresentation(self.mediaAsset.image!, 0.5)!)
        newsfeeds["contentType"] = "ph"
        newsfeeds["saved"] = false
        newsfeeds["textPost"] = self.mediaCaption.text
        newsfeeds.saveInBackground {
            (success: Bool, error: Error?) in
            if success {

                // Define #word
                for var word in self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                    // #####################
                    if word.hasPrefix("#") {
                        // Cut all symbols
                        word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                        word = word.trimmingCharacters(in: CharacterSet.symbols)
                        
                        // Save hashtag to server
                        let hashtags = PFObject(className: "Hashtags")
                        hashtags["hashtag"] = word.lowercased()
                        hashtags["userHash"] = "#" + word.lowercased()
                        hashtags["by"] = PFUser.current()!.username!
                        hashtags["pointUser"] = PFUser.current()!
                        hashtags["forObjectId"] =  newsfeeds.objectId!
                        hashtags.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("#\(word) has been saved!")
                            } else {
                                print(error?.localizedDescription as Any)
                            }
                        })
                    // @@@@@@@@@@@@@@@@@@@@@@@@@@
                    } else if word.hasPrefix("@") {
                        // Cut all symbols
                        word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                        word = word.trimmingCharacters(in: CharacterSet.symbols)
                        
                        // Search for user
                        let theUsername = PFUser.query()!
                        theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                        let realName = PFUser.query()!
                        realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                        let mention = PFQuery.orQuery(withSubqueries: [theUsername, realName])
                        mention.findObjectsInBackground(block: {
                            (objects: [PFObject]?, error: Error?) in
                            if error == nil {
                                for object in objects! {
                                    
                                    // Send notification to user
                                    let notifications = PFObject(className: "Notifications")
                                    notifications["from"] = PFUser.current()!.username!
                                    notifications["fromUser"] = PFUser.current()
                                    notifications["to"] = word
                                    notifications["toUser"] = object
                                    notifications["type"] = "tag vi"
                                    notifications["forObjectId"] = newsfeeds.objectId!
                                    notifications.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            
                                            // If user's apnsId is not nil
                                            if object["apnsId"] != nil {
                                                // MARK: - OneSignal
                                                // Send push notification
                                                OneSignal.postNotification(
                                                    ["contents":
                                                        ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Video."],
                                                     "include_player_ids": ["\(object["apnsId"] as! String)"],
                                                     "ios_badgeType": "Increase",
                                                     "ios_badgeCount": 1
                                                    ]
                                                )
                                            }
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                }
                            } else {
                                print(error?.localizedDescription as Any)
                                print("Couldn't find the user...")
                            }
                        }) } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                }// end for loop for words
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        
    }// end sharePhotoData() function
    
    
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

    // Function share library video
    func shareLibVideo() {
        
        // MARK: - HEAP
        Heap.track("SharedVideo", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Clear caption if it doesn't exist
        if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
            self.mediaCaption.text! = ""
        }
        // Compress video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // Call video compression function
        self.compressVideo(inputURL: instanceVideoData!, outputURL: compressedURL) { (exportSession) in
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
                let parseFile = PFFile(name: "video.mp4", data: compressedData as Data)
                // Save to Newsfeeds
                let newsfeeds = PFObject(className: "Newsfeeds")
                newsfeeds["username"] = PFUser.current()!.username!
                newsfeeds["byUser"] = PFUser.current()!
                newsfeeds["textPost"] = self.mediaCaption.text!
                newsfeeds["videoAsset"] = parseFile
                newsfeeds["contentType"] = "vi"
                newsfeeds["saved"] = false
                newsfeeds.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        
                        // Define #word
                        for var word in self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                            // #####################
                            if word.hasPrefix("#") {
                                // Cut all symbols
                                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                word = word.trimmingCharacters(in: CharacterSet.symbols)
                                
                                // Save hashtag to server
                                let hashtags = PFObject(className: "Hashtags")
                                hashtags["hashtag"] = word.lowercased()
                                hashtags["userHash"] = "#" + word.lowercased()
                                hashtags["by"] = PFUser.current()!.username!
                                hashtags["pointUser"] = PFUser.current()!
                                hashtags["forObjectId"] =  newsfeeds.objectId!
                                hashtags.saveInBackground(block: {
                                    (success: Bool, error: Error?) in
                                    if success {
                                        print("#\(word) has been saved!")
                                    } else {
                                        print(error?.localizedDescription as Any)
                                    }
                                })
                                // @@@@@@@@@@@@@@@@@@@@@@@@@@
                            } else if word.hasPrefix("@") {
                                // Cut all symbols
                                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                word = word.trimmingCharacters(in: CharacterSet.symbols)
                                
                                // Search for user
                                let theUsername = PFUser.query()!
                                theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                                let realName = PFUser.query()!
                                realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                                let mention = PFQuery.orQuery(withSubqueries: [theUsername, realName])
                                mention.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        for object in objects! {
                                            
                                            // Send notification to user
                                            let notifications = PFObject(className: "Notifications")
                                            notifications["from"] = PFUser.current()!.username!
                                            notifications["fromUser"] = PFUser.current()
                                            notifications["to"] = word
                                            notifications["toUser"] = object
                                            notifications["type"] = "tag vi"
                                            notifications["forObjectId"] = newsfeeds.objectId!
                                            notifications.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    
                                                    // If user's apnsId is not nil
                                                    if object["apnsId"] != nil {
                                                        // MARK: - OneSignal
                                                        // Send push notification
                                                        OneSignal.postNotification(
                                                            ["contents":
                                                                ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Video."],
                                                             "include_player_ids": ["\(object["apnsId"] as! String)"],
                                                             "ios_badgeType": "Increase",
                                                             "ios_badgeCount": 1
                                                            ]
                                                        )
                                                    }
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
                                        }
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        print("Couldn't find the user...")
                                    }
                                }) } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                        }// end for loop for words
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                
            case .failed:
                break
            case .cancelled:
                break
            }
        }

        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
        
    }// end shareLibVideo() function
    
    
    // Function to share video data
    func shareVideoData() {
        
        // MARK: - HEAP
        Heap.track("SharedVideo", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Clear caption if it doesn't exist
        if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
            self.mediaCaption.text! = ""
        }
        // Compress video
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4")
        // Set video options
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .automatic
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.version = .current
        PHCachingImageManager().requestAVAsset(forVideo: shareMediaAsset.last!,
                                               options: videoOptions,
                                               resultHandler: {(asset: AVAsset?,
                                                audioMix: AVAudioMix?,
                                                info: [AnyHashable : Any]?) -> Void in
                                                
                                                /* This result handler is performed on a random thread but
                                                 we want to do some UI work so let's switch to the main thread */
                                                
                                                /* Did we get the URL to the video? */
                                                if let asset = asset as? AVURLAsset {
                                                    // Call video compression function
                                                    self.compressVideo(inputURL: asset.url, outputURL: compressedURL) { (exportSession) in
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
                                                            let parseFile = PFFile(name: "video.mp4", data: compressedData as Data)
                                                            // Save to Newsfeeds
                                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                                            newsfeeds["username"] = PFUser.current()!.username!
                                                            newsfeeds["byUser"] = PFUser.current()!
                                                            newsfeeds["textPost"] = self.mediaCaption.text!
                                                            newsfeeds["videoAsset"] = parseFile
                                                            newsfeeds["contentType"] = "vi"
                                                            newsfeeds["saved"] = false
                                                            newsfeeds.saveInBackground(block: {
                                                                (success: Bool, error: Error?) in
                                                                if success {
                                                                    
                                                                    // Define #word
                                                                    for var word in self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                                                                        // #####################
                                                                        if word.hasPrefix("#") {
                                                                            // Cut all symbols
                                                                            word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                                                            word = word.trimmingCharacters(in: CharacterSet.symbols)
                                                                            
                                                                            // Save hashtag to server
                                                                            let hashtags = PFObject(className: "Hashtags")
                                                                            hashtags["hashtag"] = word.lowercased()
                                                                            hashtags["userHash"] = "#" + word.lowercased()
                                                                            hashtags["by"] = PFUser.current()!.username!
                                                                            hashtags["pointUser"] = PFUser.current()!
                                                                            hashtags["forObjectId"] =  newsfeeds.objectId!
                                                                            hashtags.saveInBackground(block: {
                                                                                (success: Bool, error: Error?) in
                                                                                if success {
                                                                                    print("#\(word) has been saved!")
                                                                                } else {
                                                                                    print(error?.localizedDescription as Any)
                                                                                }
                                                                            })
                                                                            // @@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                        } else if word.hasPrefix("@") {
                                                                            // Cut all symbols
                                                                            word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                                                            word = word.trimmingCharacters(in: CharacterSet.symbols)
                                                                            
                                                                            // Search for user
                                                                            let theUsername = PFUser.query()!
                                                                            theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                                                                            let realName = PFUser.query()!
                                                                            realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                                                                            let mention = PFQuery.orQuery(withSubqueries: [theUsername, realName])
                                                                            mention.findObjectsInBackground(block: {
                                                                                (objects: [PFObject]?, error: Error?) in
                                                                                if error == nil {
                                                                                    for object in objects! {
                                                                                        
                                                                                        // Send notification to user
                                                                                        let notifications = PFObject(className: "Notifications")
                                                                                        notifications["from"] = PFUser.current()!.username!
                                                                                        notifications["fromUser"] = PFUser.current()
                                                                                        notifications["to"] = word
                                                                                        notifications["toUser"] = object
                                                                                        notifications["type"] = "tag vi"
                                                                                        notifications["forObjectId"] = newsfeeds.objectId!
                                                                                        notifications.saveInBackground(block: {
                                                                                            (success: Bool, error: Error?) in
                                                                                            if success {
                                                                                                
                                                                                                // If user's apnsId is not nil
                                                                                                if object["apnsId"] != nil {
                                                                                                    // MARK: - OneSignal
                                                                                                    // Send push notification
                                                                                                    OneSignal.postNotification(
                                                                                                        ["contents":
                                                                                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Video."],
                                                                                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                                                                                         "ios_badgeType": "Increase",
                                                                                                         "ios_badgeCount": 1
                                                                                                        ]
                                                                                                    )
                                                                                                }
                                                                                            } else {
                                                                                                print(error?.localizedDescription as Any)
                                                                                            }
                                                                                        })
                                                                                    }
                                                                                } else {
                                                                                    print(error?.localizedDescription as Any)
                                                                                    print("Couldn't find the user...")
                                                                                }
                                                                            }) } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                    }// end for loop for words
                                                                    
                                                                } else {
                                                                    print(error?.localizedDescription as Any)
                                                                }
                                                            })
                                                        case .failed:
                                                            break
                                                        case .cancelled:
                                                            break
                                                        }
                                                    }
                                                    
                                                }
        })
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
    }// end shareVideoData() function

    
    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
            self.mediaCaption.text! = ""
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
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
        
        // LayoutViews for rpUserProPic
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // Fetch user's objects
        // (1) Get and set user's profile photo
        if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
        
        // (2) Set user's fullName
        cell.rpUsername.text! = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
        
        return cell
    }
    
    
    // MARK: - UITableViewDelegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Loop through words
        for var word in self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            // @@@@@@@@@@@@@@@@@@@@@@@@@@@
            if word.hasPrefix("@") {
                
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Replace text
                self.mediaCaption.text! = self.mediaCaption.text!.replacingOccurrences(of: "\(word)", with: self.userObjects[indexPath.row].value(forKey: "username") as! String, options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        
        // Hide UITableView
        self.tableView!.isHidden = true
    }
    
}
