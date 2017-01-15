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
import Mixpanel

class NewTextPost: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func moreButton(_ sender: Any) {
        let textToShare = "@\(PFUser.current()!.username!)'s Text Post on Redplanet: \(self.textView.text!)\nhttps://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8"
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
        
        // MARK: - Mixpanel
        Mixpanel.initialize(token: "947d5f290bf33c49ce88353930208769").track(event: "Shared Text Post",
                                      properties: ["Username":"\(PFUser.current()!.username!)"]
        )
        
        
        // Check if textView is empty
        if textView.text!.isEmpty {
            
            let alert = UIAlertController(title: "No Text Post?",
                                          message: "Share your thoughts within 500 characters about anything.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else if self.textView.text.characters.count > 500 {
            
            let alert = UIAlertController(title: "Exceeded Character Count",
                                          message: "For experience purposes, your thoughts should be concisely shared within 500 characters.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else {
            
            let newsfeeds = PFObject(className: "Newsfeeds")
            newsfeeds["byUser"]  = PFUser.current()!
            newsfeeds["username"] = PFUser.current()!.username!
            newsfeeds["textPost"] = self.textView!.text!
            newsfeeds["contentType"] = "tp"
            newsfeeds.saveInBackground {
                (success: Bool, error: Error?) in
                if error == nil {
                    print("Saved \(newsfeeds)")
                    
                    
                    
                    // Check for hashtags
                    // and user mentions
                    let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                    
                    
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
                        // end #
                        
                        
                        
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
                                        notifications["type"] = "tag tp"
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
                                                         "include_player_ids": ["\(object["apnsId"] as! String)"]
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
                    
                    
                    
                    // Send notification
                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                    
                    
                    // Push Show MasterTab
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    UIApplication.shared.keyWindow?.rootViewController = masterTab
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            }
            
        }
    }
    
    
    // Functino to share privately
    func sharePrivate() {
        // Show Chats
        let newChatVC = self.storyboard?.instantiateViewController(withIdentifier: "newChats") as! NewChats
        self.navigationController?.pushViewController(newChatVC, animated: true)
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
            self.title = "New Text Post"
        }
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
    
    
    


    // MARK: - UITextView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.text! == "What are you doing?" {
            self.textView.text! = ""
        }
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        // Count characters
        countRemaining()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        countRemaining()
        
        let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "newTPCell", for: indexPath) as! NewTextPostCell
        
        
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
    
    
    
    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define #word
        for var word in words {
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
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize title
        configureView()
        
        // Set textView to first responder
        self.textView!.becomeFirstResponder()
        
        // Hide tableView
        self.tableView!.isHidden = true
        // Set Tableview properties
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        
        // Hide tableView
        self.tableView.isHidden = true
        
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
        
        
        // TODO:::
        // Tap to share privately
        let privateShare = UITapGestureRecognizer(target: self, action: #selector(sharePrivate))
        privateShare.numberOfTapsRequired = 1
//        self.directButton.isUserInteractionEnabled = true
//        self.directButton.addGestureRecognizer(privateShare)
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
