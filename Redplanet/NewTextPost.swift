//
//  NewTextPost.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Social

import Parse
import ParseUI
import Bolts

import OneSignal
import SwipeNavigationController
import SDWebImage

class NewTextPost: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    
    @IBAction func backButton(_ sender: AnyObject) {
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func moreButton(_ sender: Any) {
        let textToShare = "@\(PFUser.current()!.username!)'s Text Post on Redplanet: \(self.textView.text!)\nhttps://redplanetapp.com/download/"
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var characterCount: UILabel!
    @IBOutlet weak var tableView: UITableView!

    // Share
    func postTextPost() {
        
        // Check if textView is empty
        if textView.text!.isEmpty {
            
            let alert = UIAlertController(title: "No Text Post?",
                                          message: "Share your thoughts within 500 characters about anything.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.view.tintColor = UIColor.black
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else if self.textView.text! == "What are you doing?" {
            
            let alert = UIAlertController(title: "What ARE you doing?",
                                          message: "Share your thoughts within 500 characters about anything.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.view.tintColor = UIColor.black
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else if self.textView.text.characters.count > 500 {
            
            let alert = UIAlertController(title: "Exceeded Character Count",
                                          message: "For better experience, your thoughts should be concisely shared within 500 characters.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else {
            
            // Disable button
            self.shareButton.isUserInteractionEnabled = false
            self.shareButton.isEnabled = false
            
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["byUser"]  = PFUser.current()!
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["textPost"] = self.textView!.text!
            newsfeeds["contentType"] = "tp"
            newsfeeds["saved"] = false
            newsfeeds.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    
                    // Enable button
                    self.shareButton.isUserInteractionEnabled = true
                    self.shareButton.isEnabled = true
                    
                    // Check for #'s and @'s
                    for var word in self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
                        
                        if word.hasPrefix("#") {
                            word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                            word = word.trimmingCharacters(in: CharacterSet.symbols)
                            
                            // Save hashtag to server
                            let hashtags = PFObject(className: "Hashtags")
                            hashtags["hashtag"] = word.lowercased()
                            hashtags["userHash"] = "#" + word.lowercased()
                            hashtags["by"] = PFUser.current()!.username!
                            hashtags["pointUser"] = PFUser.current()!
                            hashtags["forObjectId"] =  newsfeeds.objectId!
                            hashtags.saveInBackground()
                        
                        } else if word.hasPrefix("@") {
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
                                        print("The user is:\(object)")
                                        
                                        // Send notification to user
                                        let notifications = PFObject(className: "Notifications")
                                        notifications["from"] = PFUser.current()!.username!
                                        notifications["fromUser"] = PFUser.current()
                                        notifications["to"] = word
                                        notifications["toUser"] = object
                                        notifications["type"] = "tag tp"
                                        notifications["forObjectId"] = newsfeeds.objectId!
                                        notifications.saveInBackground()
                                        
                                        // If user's apnsId is not nil
                                        if object["apnsId"] != nil {
                                            // MARK: - OneSignal
                                            // Send push notification
                                            OneSignal.postNotification(
                                                ["contents":
                                                    ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a Text Post."],
                                                 "include_player_ids": ["\(object["apnsId"] as! String)"],
                                                 "ios_badgeType": "Increase",
                                                 "ios_badgeCount": 1
                                                ]
                                            )
                                        }
                                    }
                                } else {
                                    print(error?.localizedDescription as Any)
                                    print("Couldn't find the user...")
                                }
                            })
                        } // END: looping through words
                    }
                    
                    // MARK: - HEAP
                    Heap.track("SharedTextPost", withProperties:
                        ["byUserId": "\(PFUser.current()!.objectId!)",
                            "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                        ])
                    
                    // Completed executing
                    self.textView.resignFirstResponder()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "friendsNewsfeed"), object: nil)
                    self.textView.text! = "What are you doing?"
                    self.containerSwipeNavigationController?.showEmbeddedView(position: .bottom)
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
        }
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
            self.title = "New Text Post"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    
    // Counting function
    func countRemaining() {
        // Limit
        let limit = 500
        // Current # of characters
        let currentCharacters = self.textView.text.characters.count
        // Number of characters for space left
        let remainingCharacters = limit - currentCharacters
        
        // Change colors if character count has 20 left...
        if remainingCharacters <= limit {
            characterCount.textColor = UIColor.black
        }
        if remainingCharacters <=  20 {
            characterCount.textColor = UIColor.red
        }
        characterCount.text = String(remainingCharacters)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        // Set placeholder
        self.textView.text! = "What are you doing?"
        self.textView.textColor = UIColor.darkGray
        // Create corner radiuss
        self.navigationController?.view.layer.cornerRadius = 7.50
        self.navigationController?.view.clipsToBounds = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize title
        configureView()
        
        // Configure tableView
        self.tableView!.isHidden = true
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Make shareButton circular
        self.shareButton.layer.cornerRadius = self.shareButton.frame.size.width/2
        self.shareButton.layer.borderColor = UIColor.lightGray.cgColor
        self.shareButton.layer.borderWidth = 0.5
        self.shareButton.clipsToBounds = true
        
        // Tap to save
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(postTextPost))
        shareTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(shareTap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.textView.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
    }
    
    // MARK: - UITextView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.text! == "What are you doing?" {
            self.textView.text! = ""
            self.textView.textColor = UIColor.black
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Count characters
        countRemaining()
        
        // Define words
        let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        // Define single word
        for var word in words {
            // @'s
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
                // Show tableView and reloadData
                self.tableView!.isHidden = false
                self.tableView!.reloadData()
            } else if word.hasPrefix("http") {
                let apiEndpoint: String = "http://tinyurl.com/api-create.php?url=\(word)"
                let shortURL = try? String(contentsOf: URL(string: apiEndpoint)!, encoding: String.Encoding.ascii)
                // Replace text
                self.textView.text! = self.textView.text!.replacingOccurrences(of: "\(word)", with: shortURL!, options: String.CompareOptions.literal, range: nil)
            } else {
                self.tableView!.isHidden = true
            }
        }
        
        return true
    }
    
    // iOS 10 only
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
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
    
    
    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Loop through words
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


}
