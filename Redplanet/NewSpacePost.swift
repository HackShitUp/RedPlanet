//
//  NewSpacePost.swift
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


class NewSpacePost: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate,UITableViewDataSource, UITableViewDelegate, CLImageEditorDelegate {
    
    // Array to hold user objects and usernames
    var userObjects = [PFObject]()
    var usernames = [String]()
    
    
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func editAction(_ sender: Any) {
        // If photo exists
        if self.mediaAsset.image != nil {
            // Show CLImageEditor
            let editor = CLImageEditor(image: self.mediaAsset.image!)
            editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
            editor?.delegate = self
            // Present CLImageEditor
            self.present(editor!, animated: true, completion: nil)
        }
    }
    
    
    // Function to share
    func postSpace(sender: UIButton) {
        
        // TODO::
        // Change file type depending on whether it's a video or not
        
        // Check if text is empty 
        if self.textView!.text!.isEmpty {
            
            let alert = UIAlertController(title: "Post Failed",
                                          message: "Please share something in this Space Post.",
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
            
            // Post to user's Space
            let space = PFObject(className: "Newsfeeds")
            space["byUser"] = PFUser.current()!
            space["username"] = PFUser.current()!.username!
            space["contentType"] = "sp"
            // Save parseFile dependent on Boolean
            if self.mediaAsset.image != nil {
                // Set the mediaAsset
                // for now, image
                let proPicData = UIImageJPEGRepresentation(self.mediaAsset.image!, 0.5)
                let mediaFile = PFFile(data: proPicData!)
                space["photoAsset"] = mediaFile
            }
            // Save textPost
            if self.textView.text! != "" {
                // Set textPost
                space["textPost"] = self.textView.text!
            }
            
            space["toUser"] = otherObject.last!
            space["toUsername"] = otherName.last!
            space.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully shared Space Post: \(space)")
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    
                    // Send Notification
                    let notifications = PFObject(className: "Notifications")
                    notifications["fromUser"] = PFUser.current()!
                    notifications["from"] = PFUser.current()!.username!
                    notifications["toUser"] = otherObject.last!
                    notifications["to"] = otherName.last!
                    notifications["type"] = "space"
                    notifications["forObjectId"] = space.objectId!
                    notifications.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if error == nil {
                            print("Sent Notification: \(notifications)")
                            
                            
                            
                            // Hashtags only exist for shared content, not comments :/
                            // Check for user mentions...
                            let words: [String] = self.textView.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                            // Loop through words to check for # and @ prefixes
                            for var word in words {
                                
                                // Define @username
                                if word.hasPrefix("@") {
                                    // Get username
                                    word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                                    word = word.trimmingCharacters(in: CharacterSet.symbols)
                                    
                                    // Look for user
                                    let user = PFUser.query()!
                                    user.whereKey("username", equalTo: word.lowercased())
                                    user.findObjectsInBackground(block: {
                                        (objects: [PFObject]?, error: Error?) in
                                        if error == nil {
                                            for object in objects! {
                                                
                                                // Send mention to Parse server, class "Notifications"
                                                let notifications = PFObject(className: "Notifications")
                                                notifications["from"] = PFUser.current()!.username!
                                                notifications["fromUser"] = PFUser.current()!
                                                notifications["type"] = "tag sp"
                                                notifications["forObjectId"] = space.objectId!
                                                notifications["to"] = word
                                                notifications["toUser"] = object
                                                notifications.saveInBackground(block: {
                                                    (success: Bool, error: Error?) in
                                                    if success {
                                                        print("Successfully saved tag in notifications: \(notifications)")
                                                        
                                                        
                                                        // Handle optional chaining
                                                        if object.value(forKey: "apnsId") != nil {
                                                            // Send push notification
                                                            OneSignal.postNotification(
                                                                ["contents":
                                                                    ["en": "\(PFUser.current()!.username!.uppercased()) tagged you in a space post"],
                                                                 "include_player_ids": ["\(object.value(forKey: "apnsId") as! String)"]
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
                                        }
                                    })
                                    
                                }
                            }
                            
                            
                            
                            // Dismiss Progress
                            SVProgressHUD.dismiss()
                            
                            // Send push notification
                            if otherObject.last!.value(forKey: "apnsId") != nil {
                                OneSignal.postNotification(
                                    ["contents":
                                        ["en": "\(PFUser.current()!.username!.uppercased()) wrote on your Space"],
                                     "include_player_ids": ["\(otherObject.last!.value(forKey: "apnsId") as! String)"]
                                    ])
                                
                            }
                            
                            
                            // Send Notification to otherUser's Profile
                            NotificationCenter.default.post(name: otherNotification, object: nil)
                            
                            // Send Notification to News Feeds
                            NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                            
                            // Pop View Controller
                            _ = self.navigationController?.popViewController(animated: true)
                            
                            
                            
                            
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                }
            }
        }
        
    }
    
    
    
    // Function to choose photo
    func choosePhoto(sender: UIButton) {
        // Instantiate UIImagePickerController
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.navigationBar.tintColor = UIColor.black
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        

        // Present image picker
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    // Function to show more sharing options
    func doMore(sender: UIButton) {

        let textToShare = "@\(PFUser.current()!.username!)'s Space Post on Redplanet: \(self.textView.text!)\nhttps://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8"
        
        if self.mediaAsset.image != nil {
            let objectsToShare = [textToShare, self.mediaAsset.image!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)

        } else {
            let objectsToShare = [textToShare]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - UIImagePickerController Delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Set image
        self.mediaAsset.image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
        
        // CLImageEditor
        let editor = CLImageEditor(image: self.mediaAsset.image!)
        editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss VC
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.mediaAsset.image = image
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
        
        // Enable editButton
        self.editButton.isEnabled = true
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })

        // Enable editButton
        self.editButton.isEnabled = true
    }

    
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(otherName.last!.uppercased())'s Space"
        }
    }
    

    
    
    
    // MARK: - UITextView delegate methods
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.text! == "What are you doing?" {
            self.textView.text! = ""
        }
    }
    

    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
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
    
    
    
    
    
    
    
    // MARK: - UITableView Data Source methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usernames.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newSpacePostCell", for: indexPath) as! NewSpacePostCell
        
        
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
                self.textView.text! = self.textView.text!.replacingOccurrences(of: "\(word)", with: self.usernames[indexPath.row], options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        self.usernames.removeAll(keepingCapacity: false)
        
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
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable edit button
        self.editButton.isEnabled = false
        
        // Set first responder
        self.textView.becomeFirstResponder()

        // Design button corners
        self.postButton.layer.cornerRadius = self.postButton.frame.size.width/2
        self.postButton.layer.borderColor = UIColor.lightGray.cgColor
        self.postButton.layer.borderWidth = 0.5
        self.postButton.clipsToBounds = true
        
        // Hide tableView
        self.tableView.isHidden = true
        
        // Set mediaAsset's cornerRadius
        self.mediaAsset.layer.cornerRadius = 4.00
        self.mediaAsset.layer.borderColor = UIColor.white.cgColor
        self.mediaAsset.layer.borderWidth = 0.5
        self.mediaAsset.clipsToBounds = true
        
        // Stylize title
        configureView()
        
        // (1) Add button tap
        let spaceTap = UITapGestureRecognizer(target: self, action: #selector(postSpace))
        spaceTap.numberOfTapsRequired = 1
        self.postButton.isUserInteractionEnabled = true
        self.postButton.addGestureRecognizer(spaceTap)
        
        // (2) Add photo button tap
        let photoTap = UITapGestureRecognizer(target: self, action: #selector(choosePhoto))
        photoTap.numberOfTapsRequired = 1
        self.photosButton.isUserInteractionEnabled = true
        self.photosButton.addGestureRecognizer(photoTap)
        
        // (3) Add more button tap
        let moreTap = UITapGestureRecognizer(target: self, action: #selector(doMore))
        moreTap.numberOfTapsRequired = 1
        self.moreButton.isUserInteractionEnabled = true
        self.moreButton.addGestureRecognizer(moreTap)
        
        // (4) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
