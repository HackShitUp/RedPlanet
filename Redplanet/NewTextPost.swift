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
import AudioToolbox

import Parse
import ParseUI
import Bolts

import OneSignal
import SwipeNavigationController
import SDWebImage

/*
 UIViewController class that allows users to share New Text Posts.
 */

class NewTextPost: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // Array to hold user objects
    var userObjects = [PFObject]()
    // Keyboard frame
    var keyboard = CGRect()
    
    @IBAction func backButton(_ sender: AnyObject) {
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.showEmbeddedView(position: .center)
    }
    
    @IBAction func moreButton(_ sender: Any) {
        let textToShare = "@\(PFUser.current()!.username!)'s Text Post on Redplanet: \(self.textView.text!)\nhttps://redplanetapp.com/download/"
        let objectsToShare = [textToShare]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var characterCount: UILabel!
    @IBOutlet weak var tableView: UITableView!

    // Share
    func postTextPost() {
        
        // Check if textView is empty
        if textView.text!.isEmpty {
            
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nNo Text Post?",
                                                          message: "Share your thoughts within 500 characters about anything.")
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
            
        } else if self.textView.textColor == UIColor.darkGray {
            
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nNo Text Post?",
                                                          message: "Share your thoughts within 500 characters about anything.")
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
            
            
        } else if self.textView.text.characters.count > 500 {
            
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nExceeded Character Count",
                message: "For better experience, your thoughts should be concisely shared within 500 characters.")
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
            // Create PFObject
            let textPost = PFObject(className: "Posts")
            textPost["byUser"]  = PFUser.current()!
            textPost["byUsername"] = PFUser.current()!.username!
            textPost["textPost"] = self.textView!.text!
            textPost["contentType"] = "tp"
            textPost["saved"] = false
            
            // Show ShareWith View Controller
            shareWithObject.append(textPost)
            let shareWithVC = self.storyboard?.instantiateViewController(withIdentifier: "shareWithVC") as! ShareWith
            self.navigationController?.pushViewController(shareWithVC, animated: true)
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
        
        // Configure UINavigationBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        
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

    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        
        // Create corner radiuss
        self.navigationController?.view.layer.cornerRadius = 8.00
        self.navigationController?.view.clipsToBounds = true
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize title
        configureView()
        
        // Configure UITableView
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        // Register NIB
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Make shareButton circular
        self.shareButton.layer.cornerRadius = self.shareButton.frame.size.width/2
        self.shareButton.clipsToBounds = true
        
        // Tap to save
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(postTextPost))
        shareTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(shareTap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Configure UITextView; set placeholder and delegate
        self.textView.textColor = UIColor.darkGray
        self.textView.font = UIFont(name: "AvenirNext-Medium", size: 30)
        self.textView.delegate = self
        
        let randomInt = arc4random()
        if randomInt % 2 == 0 {
            // Even
            self.textView.text! = "What's up?"
        } else {
            // Odd
            self.textView.text! = "Thoughts are preludes to revolutionary movements..."
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Resign first responder
        self.textView.resignFirstResponder()
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Hide UITableView
        self.tableView?.isHidden = true
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
        // Move UI up: UITextView, and menuView
        self.textView.frame.size.height -= self.keyboard.height
        UIView.animate(withDuration: 0.4) { () -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            if self.menuView.frame.origin.y == self.menuView.frame.origin.y {
                // Move UITextView up
                self.textView.frame.size.height -= self.keyboard.height
                // Move menuView up
                self.menuView.frame.origin.y -= self.keyboard.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Define keyboard frame size
        self.keyboard = ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        // Move menuView down
        if self.menuView!.frame.origin.y != self.view.frame.size.height - self.menuView.frame.size.height {
            self.menuView.frame.origin.y += self.keyboard.height
        }
    }
    
    
    // MARK: - UITextView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.textColor == UIColor.darkGray {
            self.textView.text! = ""
            self.textView.textColor = UIColor.black
            self.textView.font = UIFont(name: "AvenirNext-Regular", size: 21)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        // Count characters
        countRemaining()
        
        // Access UITextView's content, and get the LAST WORD/TEXT entered
        let stringsSeparatedBySpace = textView.text.components(separatedBy: " ")
        // Then, check whether the last word/text has a "@" prefix...
        var lastString = stringsSeparatedBySpace.last!
        if lastString.hasPrefix("@") {
            // Cut all symbols
            lastString = lastString.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            lastString = lastString.trimmingCharacters(in: CharacterSet.symbols)
            // Find the user
            let realNameOfUser = PFUser.query()!
            realNameOfUser.whereKey("realNameOfUser", matchesRegex: "(?i)" + lastString)
            let username = PFUser.query()!
            username.whereKey("username", matchesRegex: "(?i)" + lastString)
            let search = PFQuery.orQuery(withSubqueries: [realNameOfUser, username])
            search.limit = 100000
            search.findObjectsInBackground(block: {
                (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // Clear arrays
                    self.userObjects.removeAll(keepingCapacity: false)
                    for object in objects! {
                        self.userObjects.append(object)
                    }
                    
                    // Show UITableView and reloadData in main thread
                    DispatchQueue.main.async {
                        self.tableView!.isHidden = false
                        self.tableView!.reloadData()
                    }
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        } else {
            self.tableView!.isHidden = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Set realNameOfUser
        if let fullName = self.userObjects[indexPath.row].value(forKey: "realNameOfUser") as? String {
            cell.rpFullName.text = fullName
        }
        
        // (2) Set username
        if let username = self.userObjects[indexPath.row].value(forKey: "username") as? String {
            cell.rpUsername.text = username
        }
        
        // (3) Get and set userProfilePicture
        if let proPic = self.userObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setIndicatorStyle(.gray)
            cell.rpUserProPic.sd_showActivityIndicatorView()
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        
        return cell
    }
    
    
    // MARK: - UITableViewdelegeate Method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Access UITextView's content, and get the LAST WORD/TEXT entered
        let stringsSeparatedBySpace = textView.text.components(separatedBy: " ")
        // Then, check whether the last word/text has a "@" prefix...
        var lastString = stringsSeparatedBySpace.last!
        if lastString.hasPrefix("@") {
            // Cut all symbols
            lastString = lastString.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            lastString = lastString.trimmingCharacters(in: CharacterSet.symbols)
            // Replace text
            if let username = self.userObjects[indexPath.row].value(forKey: "username") as? String {
                self.textView.text = self.textView.text.replacingOccurrences(of: "\(lastString)", with: username, options: String.CompareOptions.literal, range: nil)
            }
        }

        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        // Hide UITableView
        self.tableView!.isHidden = true
    }


}
