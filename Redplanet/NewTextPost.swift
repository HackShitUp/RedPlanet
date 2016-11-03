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




class NewTextPost: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Dismiss VC
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var characterCount: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var fbShare: UIButton!
    @IBOutlet weak var twitterShare: UIButton!
    
    // Share
    func postTextPost() {
        
        // Check if textView is empty
        if textView.text!.isEmpty {
            
            let alert = UIAlertController(title: "No Text Post?",
                                          message: "Share your thoughts within 200 characters about anything.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            self.present(alert, animated: true)
            
        } else if self.textView.text.characters.count > 200 {
            
            let alert = UIAlertController(title: "Exceeded Character Count",
                                          message: "For experience purposes, your thoughts should be concisely shared within 200 characters.",
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
        let limit = 200
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
                        
                        for object in objects! {
                            self.userObjects.append(object)
                        }
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
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
        return 60
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
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
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
                // NSString.CompareOptions.literal
                self.textView.text! = self.textView.text!.replacingOccurrences(of: "\(word)", with: userObjects[indexPath.row].value(forKey: "username") as! String, options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        
        // Hide UITableView
        self.tableView!.isHidden = true
    }
    
    
    
    
    // Function to dismissKeyboard
    func dismissKeyboard() {
        // Resign textView
        self.textView!.resignFirstResponder()
        
        // Hide tableView
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
        
        
        // Add view tap to dismiss keyboard
        let viewTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        viewTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(viewTap)

        
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
