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

import Parse
import ParseUI
import Bolts


import SVProgressHUD
import OneSignal

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
        // Reload Data
        NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
        // Remove last
        editObjects.removeLast()
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
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
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = true

    }
    
    
    // Function to send save #'s or @ mentions
    func checkNotifications() {
        // Check for hashtags and user mentions
        let words: [String] = self.textPost.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
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
                hashtags["forObjectId"] =  editObjects.last!.objectId!
                hashtags.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            } else if word.hasPrefix("@") {
                // @@@@@@@@@@@@@@@@@@@@@@@@@@
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
                            
                            // Send notification to user
                            let notifications = PFObject(className: "Notifications")
                            notifications["from"] = PFUser.current()!.username!
                            notifications["fromUser"] = PFUser.current()
                            notifications["to"] = word
                            notifications["toUser"] = object
                            notifications["type"] = "tag \(editObjects.last!.value(forKey: "contentType") as! String!)"
                            notifications["forObjectId"] = object.objectId!
                            notifications.saveEventually()
                            
                            print("Successfully sent notification: \(notifications)")
                            
                            // If user's apnsId is not nil
                            if object["apnsId"] != nil {
                                // MARK: - OneSignal
                                
                                if editObjects.last!.value(forKey: "contentType") as! String == "tp" {
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Text Post."],
                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else if editObjects.last!.value(forKey: "contentType") as! String == "ph" {
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Photo."],
                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else if editObjects.last!.value(forKey: "contentType") as! String == "pp" {
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Profile Photo."],
                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                } else if editObjects.last!.value(forKey: "contentType") as! String == "vi" {
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Video."],
                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                    
                                } else if editObjects.last!.value(forKey: "contentType") as! String == "sp" {
                                    // Send push notification
                                    OneSignal.postNotification(
                                        ["contents":
                                            ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Space Post."],
                                         "include_player_ids": ["\(object["apnsId"] as! String)"],
                                         "ios_badgeType": "Increase",
                                         "ios_badgeCount": 1
                                        ]
                                    )
                                    
                                }
                            }
                            
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                        print("Couldn't find the user...")
                    }
                })
                
            } // END: @@@@@@@@@@@@@@@@@@@@@@@@@@@
        }// end for words
        

    }
    

    // Function to save changes
    func saveChanges(sender: UIButton) {
        
        if self.textPost.text!.isEmpty && editObjects.last!.value(forKey: "contentType") as! String == "tp" {
            
            let alert = UIAlertController(title: "Changes Failed",
                                          message: "You cannot save changes with no text.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            
            alert.view.tintColor = UIColor.black
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
            
        } else if editObjects.last!.value(forKey: "contentType") as! String == "sp" && (editObjects.last!.value(forKey: "photoAsset") == nil || editObjects.last!.value(forKey: "videoAsset") == nil) && self.textPost.text!.isEmpty {
            
            let alert = UIAlertController(title: "Changes Failed",
                                          message: "You cannot save changes with no text.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            
            alert.view.tintColor = UIColor.black
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        
        } else {
            
            // Show Progress
            SVProgressHUD.show()
            SVProgressHUD.setBackgroundColor(UIColor.white)
            
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
                            
                            SVProgressHUD.dismiss()
                            
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
                            
                            // Clear array and append object
                            editObjects.removeAll(keepingCapacity: false)
                            editObjects.append(object!)

                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Dismiss Progress
                            SVProgressHUD.dismiss()
                        }
                        
                    })

                } else {
                    print(error?.localizedDescription as Any)
                    SVProgressHUD.dismiss()
                }
            })

        
            // Check for hashtags and mentions
            checkNotifications()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "editContentCell", for: indexPath) as! EditContentCell
        
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
        userObjects[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get user's Profile Photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set profile photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
                
                // (2) Set full name
                cell.rpFullName.text! = object!["realNameOfUser"] as! String
                
                // (3) Set username
                cell.rpUsername.text! = object!["username"] as! String
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        return cell
    }
    
    
    
    
    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let words: [String] = self.textPost.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define #word
        for var word in words {
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
        let agrume = Agrume(image: self.mediaAsset.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self)
    }
    
    
    // Function to play video
    func playVideo(sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            
            // Fetch video data
            if let video = editObjects.last!.value(forKey: "videoAsset") as? PFFile {
                
                let videoUrl = NSURL(string: video.url!)

                
                // MARK: - PeriscopeVideoViewController
                let videoViewController = VideoViewController(videoURL: videoUrl as! URL)
                videoViewController.modalPresentationStyle = .popover
                videoViewController.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
                
                
                let popOverVC = videoViewController.popoverPresentationController
                popOverVC?.permittedArrowDirections = .any
                popOverVC?.delegate = self
                popOverVC?.sourceView = self.mediaAsset
                popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                
                
                self.present(videoViewController, animated: true, completion: nil)
            }
            
        })
    }
    
    
    // Prevent crash by looping around iPad
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        
        // Set first responder
        self.textPost.becomeFirstResponder()
        
        // Hide tableView
        self.tableView.isHidden = true
        
        // Add function to save changes tap
        let save = UITapGestureRecognizer(target: self, action: #selector(saveChanges))
        save.numberOfTapsRequired = 1
        self.completeButton.isUserInteractionEnabled = true
        self.completeButton.addGestureRecognizer(save)
        
        
        // Make complete button circular
        self.completeButton.layer.cornerRadius = self.completeButton.frame.size.width/2.0
        self.completeButton.clipsToBounds = true
        
        
        // Text
        if let text = editObjects.last!.value(forKey: "textPost") as? String {
            self.textPost.text! = text
        }
        
        
        // Add corner radius for thumbnail
        self.mediaAsset.layer.cornerRadius = 6.00
        self.mediaAsset.clipsToBounds = true
        
        
        // Fill in photo
        if editObjects.last!.value(forKey: "photoAsset") != nil {
            // Photo
            if let photo = editObjects.last!.value(forKeyPath: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set photo
                        self.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            // Add zoom-method tap
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(zoomTap)
            
        } else {
            // Video
            if let videoFile = editObjects.last!.value(forKeyPath: "videoAsset") as? PFFile {
                let videoUrl = NSURL(string: videoFile.url!)
                do {
                    let asset = AVURLAsset(url: videoUrl as! URL, options: nil)
                    let imgGenerator = AVAssetImageGenerator(asset: asset)
                    imgGenerator.appliesPreferredTrackTransform = true
                    let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                    self.mediaAsset.image = UIImage(cgImage: cgImage)
                    
                } catch let error {
                    print("*** Error generating thumbnail: \(error.localizedDescription)")
                }
            }
            
            // Add Video preview method tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaAsset.isUserInteractionEnabled = true
            self.mediaAsset.addGestureRecognizer(playTap)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
