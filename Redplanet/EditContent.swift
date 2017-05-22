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

// Array 
var editObjects = [PFObject]()

class EditContent: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate {
    
    // Array to hold user's objects
    var userObjects = [PFObject]()
    
    @IBOutlet weak var textPost: UITextView!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func backButton(_ sender: Any) {
        // Remove last
        editObjects.removeLast()
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to reload data
    func reloadData() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "home"), object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
    }
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Edit"
        }
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    

    // Function to save changes
    func saveChanges(sender: UIButton) {
        
        if self.textPost.text!.isEmpty && editObjects.last!.value(forKey: "contentType") as! String == "tp" {
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

        } else if editObjects.last!.value(forKey: "contentType") as! String == "sp" && (editObjects.last!.value(forKey: "photoAsset") == nil || editObjects.last!.value(forKey: "videoAsset") == nil) && self.textPost.text!.isEmpty {
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
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.getObjectInBackground(withId: editObjects.last!.objectId!, block: {
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
                            
                            // Clear array and append object
                            editObjects.removeAll(keepingCapacity: false)
                            editObjects.append(object!)
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
            // Clear array and pop vc
            editObjects.removeAll(keepingCapacity: false)
            _ = self.navigationController?.popViewController(animated: true)

        }
    }
    
    

    
    // MARK: - UITextView Delegate Methods
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
                // show table view and reload data
                self.tableView!.isHidden = false
                self.tableView!.reloadData()
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
        cell.rpFullName.text! = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
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
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
    }
    
    
    // Function to play video
    func playVideo(sender: AnyObject) {
        // Fetch video data
        if let video = editObjects.last!.value(forKey: "videoAsset") as? PFFile {
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
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.present(rpPopUpVC, animated: true, completion: nil)
        }
    }
    
    
    // Prevent crash by looping around iPad
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Set first responder
        self.textPost.becomeFirstResponder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide tableView
        self.tableView.isHidden = true
        self.tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        // Add function to save changes tap
        let save = UITapGestureRecognizer(target: self, action: #selector(saveChanges))
        save.numberOfTapsRequired = 1
        self.completeButton.isUserInteractionEnabled = true
        self.completeButton.addGestureRecognizer(save)
        
        // MARK: - RPExtensions
        self.mediaAsset.roundAllCorners(sender: self.mediaAsset)
        
        // Text
        if let text = editObjects.last!.value(forKey: "textPost") as? String {
            self.textPost.text! = text
        }
        
        // Fill in photo
        if editObjects.last!.value(forKey: "photoAsset") != nil {
            // Photo
            if let photo = editObjects.last!.value(forKeyPath: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                self.mediaAsset.sd_setImage(with: URL(string: photo.url!), placeholderImage: self.mediaAsset.image)
            }
            
            // Add zoom-method tap
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(zoomTap)
            
        } else {
        // VIDEO
            // Get media preview
            if let videoFile = editObjects.last!.value(forKeyPath: "videoAsset") as? PFFile {
                // LayoutViews
                self.mediaAsset.layoutIfNeeded()
                self.mediaAsset.layoutSubviews()
                self.mediaAsset.setNeedsLayout()
                
                // Make Vide Preview Circular
                self.mediaAsset.layer.cornerRadius = self.mediaAsset.frame.size.width/2
                self.mediaAsset.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                self.mediaAsset.layer.borderWidth = 3.50
                // MARK: - SDWebImage
                self.mediaAsset.sd_setShowActivityIndicatorView(true)
                self.mediaAsset.sd_setIndicatorStyle(.gray)
                
                // Load Video Preview and Play Video
                let player = AVPlayer(url: URL(string: videoFile.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.mediaAsset.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.mediaAsset.contentMode = .scaleAspectFit
                self.mediaAsset.layer.addSublayer(playerLayer)
            }
            
            // Add Video preview method tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(playTap)
        }

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
    


}
