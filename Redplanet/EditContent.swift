//
//  EditContent.swift
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

import Parse
import ParseUI
import Bolts

import OneSignal
import SDWebImage
import VIMVideoPlayer

class EditContent: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    // MARK: - Configurable class variables
    var editObject: PFObject?
    
    
    // Array to hold user's objects
    var userObjects = [PFObject]()
    // Initialized CGRect for keyboard frame
    var keyboard = CGRect()
    
    @IBOutlet weak var textPost: UITextView!
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var menuView: UIView!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func updateAction(_ sender: Any) {
        if self.textPost.text!.isEmpty && self.editObject!.value(forKey: "contentType") as! String == "tp" {
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nEdit Failed",
                                                          message: "You can't save changes with no text.")
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
            
        } else if self.editObject!.value(forKey: "contentType") as! String == "sp" && (self.editObject!.value(forKey: "photoAsset") == nil || self.editObject!.value(forKey: "videoAsset") == nil) && self.textPost.text!.isEmpty {
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nEdit Failed",
                                                          message: "You can't save changes with no text.")
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
            
            // Fetch object
            let postsClass = PFQuery(className: "Posts")
            postsClass.getObjectInBackground(withId: self.editObject!.objectId!, block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // Found object, now save it
                    object!["textPost"] = self.textPost.text!
                    object!.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showSuccess(withTitle: "Edit Saved")
                            // Check for @'s and #'s
                            rpHelpers.checkHash(forObject: object!, forText: self.textPost.text!)
                            rpHelpers.checkTags(forObject: object!, forText: self.textPost.text!, postType: (object!.value(forKey: "contentType") as! String))
                            
                            
                            // TODO:: RELOAD DATA
                            /*
                             // Refresh data if successfull
                             if object!.value(forKey: "contentType") as! String == "tp" {
                             // Text Post
                             textPostObject.removeAll(keepingCapacity: false)
                             textPostObject.append(object!)
                             NotificationCenter.default.post(name: textPostNotification, object: nil)
                             
                             } else if object!.value(forKey: "contentType") as! String == "ph" {
                             // Photo
                             photoAssetObject.removeAll(keepingCapacity: false)
                             photoAssetObject.append(object!)
                             NotificationCenter.default.post(name: photoNotification, object: nil)
                             
                             } else if object!.value(forKey: "contentType") as! String == "pp" {
                             // Profile Photo
                             proPicObject.removeAll(keepingCapacity: false)
                             proPicObject.append(object!)
                             NotificationCenter.default.post(name: profileNotification, object: nil)
                             
                             } else if object!.value(forKey: "contentType") as! String == "vi" {
                             // Video
                             videoObject.removeAll(keepingCapacity: false)
                             videoObject.append(object!)
                             NotificationCenter.default.post(name: videoNotification, object: nil)
                             
                             } else if object!.value(forKey: "contentType") as! String == "sp" {
                             // Space Post
                             spaceObject.removeAll(keepingCapacity: false)
                             spaceObject.append(object!)
                             NotificationCenter.default.post(name: spaceNotification, object: nil)
                             }
                             */
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - RPHelpers
                            let rpHelpers = RPHelpers()
                            rpHelpers.showError(withTitle: "Network Error")
                        }
                    })
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
            
            
            // Reload data
            self.reloadData()
            // Pop VC
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // Function to reload data
    func reloadData() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
    }
    
    // FUNCTION - Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Edit Post"
        }
        
        // MARK: - RPExtensions; whitenBar and roundTopCorners
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.view.roundTopCorners(sender: self.navigationController?.view)
        // Hide UITabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    // FUNCTION - Zoom into photo
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    
    // FUNCTION - Play video
    func playVideo(sender: AnyObject) {
        // Fetch video data
        if let video = self.editObject!.value(forKey: "videoAsset") as? PFFile {
            // MARK: - SubtleVolume
            let subtleVolume = SubtleVolume(style: .dots)
            subtleVolume.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 3)
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
            vimPlayerView.player.setURL(URL(string: video.url!)!)
            vimPlayerView.player.play()
            viewController.view.addSubview(vimPlayerView)
            viewController.view.bringSubview(toFront: vimPlayerView)
            viewController.view.addSubview(subtleVolume)
            viewController.view.bringSubview(toFront: subtleVolume)
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.present(rpPopUpVC, animated: true, completion: nil)
        }
    }

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Set first responder
        self.textPost.becomeFirstResponder()
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide UITableView
        self.tableView.isHidden = true
        self.tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        // Implement back swipe method
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        
        // (1) Set Text
        if let text = self.editObject!.value(forKey: "textPost") as? String {
            self.textPost.text! = text
        }
        
        // (2) Add mediaPreview
        if self.editObject!.value(forKey: "photoAsset") != nil {
        // PHOTO
            if let photo = self.editObject!.value(forKeyPath: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                self.mediaPreview.sd_setIndicatorStyle(.gray)
                self.mediaPreview.sd_showActivityIndicatorView()
                self.mediaPreview.sd_setImage(with: URL(string: photo.url!), placeholderImage: self.mediaPreview.image)
            }
            
            // MARK: - RPExtensions
            self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
            
            // Add zoom-method tap
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaPreview.isUserInteractionEnabled = true
            self.mediaPreview.addGestureRecognizer(zoomTap)
            
        } else if let videoFile = self.editObject!.value(forKeyPath: "videoAsset") as? PFFile {
        // VIDEO
            // MARK: - SDWebImage
            self.mediaPreview.sd_setIndicatorStyle(.gray)
            self.mediaPreview.sd_showActivityIndicatorView()
            
            // MARK: - RPExtensions
            self.mediaPreview.makeCircular(forView: self.mediaPreview, borderWidth: 0, borderColor: UIColor.clear)
            
            // Load Video Preview and Play Video
            let player = AVPlayer(url: URL(string: videoFile.url!)!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.mediaPreview.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.mediaPreview.contentMode = .scaleAspectFit
            self.mediaPreview.layer.addSublayer(playerLayer)
            
            // Add playVideo tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaPreview.isUserInteractionEnabled = true
            self.mediaPreview.addGestureRecognizer(playTap)
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Reload data
        self.reloadData()
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
                // Move UITextView up
                self.textPost.frame.size.height -= self.keyboard.height
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
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Define word
        for var word in self.textPost.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            // #####################
            if word.hasPrefix("@") {
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Find the user
                let fullName = PFUser.query()!
                fullName.whereKey("fullName", matchesRegex: "(?i)" + word)
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
                DispatchQueue.main.async(execute: {
                    self.tableView.isHidden = false
                    self.tableView.reloadData()
                })
                
            } else {
                self.tableView!.isHidden = true
            }
        }
        
        return true
    }

    // MARK: - UITableView DataSource Methods
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
        
        // (1) Set rpFullName
        cell.rpFullName.text! = self.userObjects[indexPath.row].value(forKey: "fullName") as! String
        // (2) Set rpUsername
        cell.rpUsername.text! = self.userObjects[indexPath.row].value(forKey: "username") as! String
        // (3) Get and set userProfilePicture
        if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_showActivityIndicatorView()
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        return cell
    }

    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Define #word
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
        self.tableView!.isHidden = true
    }


}
