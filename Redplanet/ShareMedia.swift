//
//  ShareMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/29/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Photos
import PhotosUI
import AVFoundation
import AVKit


import Parse
import ParseUI
import Bolts
import OneSignal
import Mixpanel

// Array to hold photo or video from library; PHAsset
var shareMediaAsset = [PHAsset]()

// When selected via UIImagePickerController; UIImage
var shareImageAssets = [UIImage]()

// URL to hold video data; when selected via UIImagePcikerController; URL
var instanceVideoData: URL?

// Media Type
// Photo or Video
var mediaType: String?

class ShareMedia: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, CLImageEditorDelegate, CLImageEditorTransitionDelegate {

    
    // Variable to hold parseFile
    // Only done to allow videos to be shared in the future
    var parseFile: PFFile?
    
    
    // Array to hold user's objects for @
    var userObjects = [PFObject]()
    
    
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var mediaCaption: UITextView!
    @IBOutlet weak var tableView: UITableView!

    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: false)
    }
    
    @IBAction func more(_ sender: Any) {
        let textToShare = "@\(PFUser.current()!.username!)'s Photo on Redplanet: \(self.mediaCaption.text!)\nhttps://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8"
        let objectsToShare = [textToShare, self.mediaAsset.image!] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
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
    @IBOutlet weak var saveButton: UIButton!
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        if mediaType == "photo" {
            
            // Mark: - Agrume
            let agrume = Agrume(image: self.mediaAsset.image!)
            agrume.statusBarStyle = UIStatusBarStyle.lightContent
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
    
    
    
    
    
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
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
            
        }
        
        
        // * Show navigation bar and tab bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide tableView on load
        self.tableView!.isHidden = true
        self.tableView!.allowsSelection = true
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        
        // Set placeholder depending on media type
        if mediaType == "photo" {
            self.mediaCaption.text! = "Say something about this photo..."
            // Enable edit button
            editBarButton.isEnabled = true
        } else {
            self.mediaCaption.text! = "Say something about this video..."
            // Disable edit button
            editBarButton.isEnabled = false
        }
        
        
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
            // Get video thumbnail
            do {
                let asset = AVURLAsset(url: instanceVideoData!, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                self.mediaAsset.image = UIImage(cgImage: cgImage)
                
            } catch let error {
                print("*** Error generating thumbnail: \(error.localizedDescription)")
            }
        }
        
        
        // (4) Stylize title
        configureView()
        
        
        // (5) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
        
        // (6) Add tap to save photo
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(saveMedia))
        saveTap.numberOfTapsRequired = 1
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.addGestureRecognizer(saveTap)
        
        // (7) Add tap to share photo
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareMedia))
        shareTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(shareTap)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureView()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Post notification
//        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // Function to save photo
    func saveMedia() {
        
        
        if mediaType == "photo" {
            
            UIView.animate(withDuration: 0.5) { () -> Void in
                
                self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                
                self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
            
            UIImageWriteToSavedPhotosAlbum(self.mediaAsset.image!, self, nil, nil)

        } else {
            
            if shareMediaAsset.isEmpty {
                // Save video URL
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: instanceVideoData!)
                }) { saved, error in
                    if saved {
                        self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                }


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

                                                        
                                                        DispatchQueue.main.async(execute: {
                                                            
                                                            /* Did we get the URL to the video? */
                                                            if let asset = asset as? AVURLAsset{
                                                                
                                                                
                                                                PHPhotoLibrary.shared().performChanges({
                                                                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: asset.url)
                                                                }) { saved, error in
                                                                    if saved {
                                                                        self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
                                                                    } else {
                                                                        print(error?.localizedDescription as Any)
                                                                    }
                                                                }
                                                                
                                     
                                                            } else {
                                                                // Did not get the AVAssetUrl
                                                                print("This is not a URL asset. Cannot play")
                                                            }
                                                            
                                                        })
                })
            }

        }
    }
    
    
    
    
    // Function to share photo
    func shareMedia() {
        
        
        // Run in main thread
        DispatchQueue.main.async(execute: {
            
            // Determine Content Type
            if mediaType == "photo" {
                
                // Share Photo
                self.sharePhotoData()
                
                // MARK: - Mixpanel
                Mixpanel.initialize(token: "947d5f290bf33c49ce88353930208769").track(event: "Shared Photo",
                                              properties: ["Username":"\(PFUser.current()!.username!)"]
                )
                
            } else {
                
                // Share Video
                self.shareVideoData()
                
                // MARK: - Mixpanel
                Mixpanel.initialize(token: "947d5f290bf33c49ce88353930208769").track(event: "Shared Video",
                                              properties: ["Username":"\(PFUser.current()!.username!)"]
                )
                
            } // end contentType Determination
            
            // Clear arrays
            shareMediaAsset.removeAll(keepingCapacity: false)
            shareImageAssets.removeAll(keepingCapacity: false)
            
            // Send Notification
            NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
            
            // Push Show MasterTab
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
            UIApplication.shared.keyWindow?.rootViewController = masterTab
        }) // end running in main thread
    }
    
    
    
    
    
    
    
    // Function to share photo data
    func sharePhotoData() {
        // Save to Newsfeeds
        let newsfeeds = PFObject(className: "Newsfeeds")
        newsfeeds["username"] = PFUser.current()!.username!
        newsfeeds["byUser"] = PFUser.current()!
        // Convert UIImage to NSData
        let imageData = UIImageJPEGRepresentation(self.mediaAsset.image!, 0.5)
        // Change UIImage to PFFile
        parseFile = PFFile(data: imageData!)
        newsfeeds["photoAsset"] = parseFile
        newsfeeds["contentType"] = "ph"
        if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
            newsfeeds["textPost"] = ""
        } else {
            newsfeeds["textPost"] = self.mediaCaption.text
        }
        
        // Finally, save...
        newsfeeds.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                print("Successfully shared object: \(newsfeeds)")
                
                // Check for hashtags
                // and user mentions
                let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                
                
                // Define #word
                for var word in words {
                    
                    
                    
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
                    }
                    
                    
                    
                    // @@@@@@@@@@@@@@@@@@@@@@@@@@
                    if word.hasPrefix("@") {
                        // Cut all symbols
                        word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                        word = word.trimmingCharacters(in: CharacterSet.symbols)
                        
                        print("The user's username to notify is: \(word)")
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
                                    print("The user is:\(object)")
                                    
                                    
                                    // Send notification to user
                                    let notifications = PFObject(className: "Notifications")
                                    notifications["from"] = PFUser.current()!.username!
                                    notifications["fromUser"] = PFUser.current()
                                    notifications["to"] = word
                                    notifications["toUser"] = object
                                    notifications["type"] = "tag ph"
                                    notifications["forObjectId"] = newsfeeds.objectId!
                                    notifications.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            
                                            print("Successfully sent notification: \(notifications)")
                                            
                                            // If user's apnsId is not nil
                                            if object["apnsId"] != nil {
                                                // MARK: - OneSignal
                                                // Send push notification
                                                OneSignal.postNotification(
                                                    ["contents":
                                                        ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Photo."],
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
                        })
                        
                    } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        

    }
    
    
    
    // Function to share video data
    func shareVideoData() {
        
        if shareMediaAsset.isEmpty {
            
            // Traverse url to Data
            let tempImage = instanceVideoData as NSURL?
            _ = tempImage?.relativePath
            let videoData = NSData(contentsOfFile: (tempImage?.relativePath!)!)
            self.parseFile = PFFile(name: "video.mp4", data: videoData! as Data)
            
            // Save to Newsfeeds
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["byUser"] = PFUser.current()!
            if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
                newsfeeds["textPost"] = ""
            } else {
                newsfeeds["textPost"] = self.mediaCaption.text
            }
            newsfeeds["videoAsset"] = self.parseFile
            newsfeeds["contentType"] = "vi"
            
            // Finally, save...
            newsfeeds.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    print("Successfully shared object: \(newsfeeds)")
                    
                    // Check for hashtags
                    // and user mentions
                    let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                    
                    
                    // Define #word
                    for var word in words {
                        
                        
                        
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
                        }
                        
                        
                        
                        // @@@@@@@@@@@@@@@@@@@@@@@@@@
                        if word.hasPrefix("@") {
                            // Cut all symbols
                            word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                            word = word.trimmingCharacters(in: CharacterSet.symbols)
                            
                            print("The user's username to notify is: \(word)")
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
                                        print("The user is:\(object)")
                                        
                                        
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
                                                
                                                print("Successfully sent notification: \(notifications)")
                                                
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
                            })
                            
                        } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    print("ERROR SHARING VIDEOS")
                }
            }

        } else {
            
            // Set video options
            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = .automatic
            videoOptions.isNetworkAccessAllowed = true
            videoOptions.version = .current
            
            PHCachingImageManager().requestAVAsset(forVideo: shareMediaAsset.last!,
                                                   options: videoOptions,
                                                   resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                                                    
                                                    /* This result handler is performed on a random thread but
                                                     we want to do some UI work so let's switch to the main thread */
                                                    
                                                    DispatchQueue.main.async(execute: {
                                                        
                                                        /* Did we get the URL to the video? */
                                                        if let asset = asset as? AVURLAsset {
                                                            
                                                            // Traverse url to Data
                                                            let tempImage = asset.url as NSURL?
                                                            _ = tempImage?.relativePath
                                                            let videoData = NSData(contentsOfFile: (tempImage?.relativePath!)!)
                                                            self.parseFile = PFFile(name: "video.mp4", data: videoData! as Data)
                                                            
                                                            // Save to Newsfeeds
                                                            let newsfeeds = PFObject(className: "Newsfeeds")
                                                            newsfeeds["username"] = PFUser.current()!.username!
                                                            newsfeeds["byUser"] = PFUser.current()!
                                                            if self.mediaCaption.text! == "Say something about this photo..." || self.mediaCaption.text! == "Say something about this video..." {
                                                                newsfeeds["textPost"] = ""
                                                            } else {
                                                                newsfeeds["textPost"] = self.mediaCaption.text
                                                            }
                                                            newsfeeds["videoAsset"] = self.parseFile
                                                            newsfeeds["contentType"] = "vi"
                                                            
                                                            // Finally, save...
                                                            newsfeeds.saveInBackground {
                                                                (success: Bool, error: Error?) in
                                                                if error == nil {
                                                                    print("Successfully shared object: \(newsfeeds)")
                                                                    
                                                                    // Check for hashtags
                                                                    // and user mentions
                                                                    let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                                                                    
                                                                    
                                                                    // Define #word
                                                                    for var word in words {
                                                                        
                                                                        
                                                                        
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
                                                                        }
                                                                        
                                                                        
                                                                        
                                                                        // @@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                        if word.hasPrefix("@") {
                                                                            // Cut all symbols
                                                                            word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                                                            word = word.trimmingCharacters(in: CharacterSet.symbols)
                                                                            
                                                                            print("The user's username to notify is: \(word)")
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
                                                                                        print("The user is:\(object)")
                                                                                        
                                                                                        
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
                                                                                                
                                                                                                print("Successfully sent notification: \(notifications)")
                                                                                                
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
                                                                            })
                                                                            
                                                                        } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                    }
                                                                    
                                                                    
                                                                } else {
                                                                    print(error?.localizedDescription as Any)
                                                                    print("ERROR SHARING VIDEOS")
                                                                }
                                                            }
                                                            
                                                            
                                                        } else {
                                                            // Did not get the AVAssetUrl
                                                            print("This is not a URL asset. Cannot play")
                                                        }
                                                        
                                                    })
            })
        }
    }

    
    
    
    
    
    
    
    
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "shareMediaCell", for: indexPath) as! ShareMediaCell
        
        
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
        self.userObjects[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set user's pro pic
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                // (2) Set user's fullName
                cell.rpFullName.text! = object!["realNameOfUser"] as! String
                
                // (3) Set user's username
                cell.rpUsername.text! = object!["username"] as! String
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        
        return cell
    }
    
    
    // MARK: - UITableViewDelegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define #word
        for var word in words {
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
