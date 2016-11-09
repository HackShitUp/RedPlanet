//
//  EditContent.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/7/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import SVProgressHUD
import OneSignal

// Array 
var editObjects = [PFObject]()

class EditContent: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    // Array to hold user's objects and usernames
    var userObjects = [PFObject]()
    var usernames = [String]()

    
    @IBOutlet weak var textPost: UITextView!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
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
    }
    
    
    // Function to save changes
    func saveChanges(sender: UIButton) {
        
        
        // Variable to hold content type for convenience
        var contentTypeString: String?
        
        // Show Progress
        SVProgressHUD.show()
        
        
        // Fetch object
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: editObjects.last!.objectId!)
        newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    
                    // Set contentTypeString
                    contentTypeString = object["contentType"] as! String
                    
                    // Found object
                    object["textPost"] = self.textPost.text!
                    object.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved changes")
                            
                            
                            // Check for hashtags
                            // and user mentions
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
                                    hashtags["forObjectId"] =  object.objectId!
                                    hashtags.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            print("#\(word) has been saved!")
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                }
                                // end #
                                
                                
                                
                                // @@@@@@@@@@@@@@@@@@@@@@@@@@
                                if word.hasPrefix("@") {
                                    // Cut all symbols
                                    word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                    word = word.trimmingCharacters(in: CharacterSet.symbols)
                                    
                                    print("The user's username to notify is: \(word)")
                                    // Search for user
                                    let theUsername = PFQuery(className: "_User")
                                    theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                                    
                                    let realName = PFQuery(className: "_User")
                                    realName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                                    
                                    let mention = PFQuery.orQuery(withSubqueries: [theUsername, realName])
                                    mention.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                print("The user is:\(object)")
                                                
                                                
                                                // Variable
                                                
                                                // Send notification to user
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["fromUser"] = PFUser.current()
                                                notifications["to"] = word
                                                notifications["toUser"] = object
                                                notifications["type"] = "tag \(contentTypeString!)"
                                                notifications["forObjectId"] = object.objectId!
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        
                                                        print("Successfully sent notification: \(notifications)")
                                                        
                                                        
                                                        // If user's apnsId is not nil
                                                        if object["apnsId"] != nil {
                                                            // MARK: - OneSignal
                                                            
                                                            if contentTypeString! == "tp" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Text Post."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                            }
                                                            if contentTypeString! == "ph" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Photo."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                            }
                                                            if contentTypeString! == "pp" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Profile Photo."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                            }
                                                            if contentTypeString! == "vi" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Video."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                                
                                                            }
                                                            if contentTypeString! == "sp" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Space Post."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                                
                                                            }
                                                            if contentTypeString! == "sh" {
                                                                // Send push notification
                                                                OneSignal.postNotification(
                                                                    ["contents":
                                                                        ["en": "\(PFUser.current()!.username!) tagged you in a Share."],
                                                                     "include_player_ids": ["\(object["apnsId"] as! String)"]
                                                                    ]
                                                                )
                                                            }
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
                            
                            // Dismiss Progress
                            SVProgressHUD.dismiss()
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
        })
        
        
        
        // Dismiss Progress
        SVProgressHUD.dismiss()
        
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
        
        
        // Send to Text Post
        NotificationCenter.default.post(name: photoNotification, object: nil)
        
        // Send to Photo Asset
        NotificationCenter.default.post(name: textPostNotification, object: nil)
        
        // Send to Profile Photo
        NotificationCenter.default.post(name: profileNotification, object: nil)
        
        
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
                let fullName = PFQuery(className: "_User")
                fullName.whereKey("realNameOfUser", matchesRegex: "(?i)" + word)
                
                let theUsername = PFQuery(className: "_User")
                theUsername.whereKey("username", matchesRegex: "(?i)" + word)
                
                let search = PFQuery.orQuery(withSubqueries: [fullName, theUsername])
                search.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        
                        
                        // Clear arrays
                        self.userObjects.removeAll(keepingCapacity: false)
                        self.usernames.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            self.userObjects.append(object)
                            self.usernames.append(object["username"] as! String)
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
        return self.usernames.count
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
                self.textPost.text! = self.textPost.text!.replacingOccurrences(of: "\(word)", with: self.usernames[indexPath.row], options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        self.usernames.removeAll(keepingCapacity: false)
        
        // Hide UITableView
        self.tableView!.isHidden = true
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
            
        } else {
            // Video
            if let video = editObjects.last!.value(forKeyPath: "videoAsset") as? PFFile {
                // TODO::
                // Set video thumbnail
            }
            
        }
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
