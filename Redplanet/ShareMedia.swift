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

import Parse
import ParseUI
import Bolts


// Array to hold photo from library
var shareMediaAsset = [PHAsset]()

// When taken photo w RPCamera
var shareImageAssets = [UIImage]()



class ShareMedia: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, CLImageEditorDelegate, CLImageEditorTransitionDelegate {

    
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
    }
    
    @IBAction func editPhoto(_ sender: AnyObject) {
        // Present CLImageEditor
        let editor = CLImageEditor(image: self.mediaAsset.image!)
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
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self)
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
            self.title = "New Photo"
        }
    }
    
    
    // Function to save photo
    func savePhoto() {
        UIView.animate(withDuration: 0.5) { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
        
        UIImageWriteToSavedPhotosAlbum(self.mediaAsset.image!, self, nil, nil)
    }
    
    
    // Function to share photo
    func shareMedia() {
        // Convert UIImage to NSData
        let imageData = UIImageJPEGRepresentation(self.mediaAsset.image!, 0.5)
        // Change UIImage to PFFile
        parseFile = PFFile(data: imageData!)
        
        
        // Save to "Photos_Videos"
        let newsfeeds = PFObject(className: "Newsfeeds")
        newsfeeds["username"] = PFUser.current()!.username!
        newsfeeds["byUser"] = PFUser.current()!
        newsfeeds["photoAsset"] = parseFile
        newsfeeds["textPost"] = self.mediaCaption.text
        newsfeeds["contentType"] = "ph"
        if self.mediaCaption.text! == "Say something about this photo..." {
            newsfeeds["textPost"] = ""
        }
        newsfeeds.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                print("Successfully shared object: \(newsfeeds)")
                
                
                
                // TODO::
                // Check for hashtags
                // Check for mentions
                
                
                
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
    
    
    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.mediaCaption.text! == "Say something about this photo..." {
            self.mediaCaption.text! = ""
        }
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        countRemaining()
        
        let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
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
    
    
    
    
    
    // Function to dismissKeyboard
    func dismissKeyboard() {
        // Resign textView
        self.mediaCaption.resignFirstResponder()
        
        // Hide tableView
        self.tableView!.isHidden = true
    }
    
    
    
    
    
    // MARK: - UITableView Data Source methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userObjects.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
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
        
        let words: [String] = self.mediaCaption.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Define #word
        for var word in words {
            // @@@@@@@@@@@@@@@@@@@@@@@@@@@
            if word.hasPrefix("@") {
                
                // Cut all symbols
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                // Replace text
                // NSString.CompareOptions.literal
                self.mediaCaption.text! = self.mediaCaption.text!.replacingOccurrences(of: "\(word)", with: userObjects[indexPath.row].value(forKey: "username") as! String, options: String.CompareOptions.literal, range: nil)
            }
        }
        
        // Clear array
        self.userObjects.removeAll(keepingCapacity: false)
        
        // Hide UITableView
        self.tableView!.isHidden = true
    }
    
    
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // * Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        
        // Hide tableView on load
        self.tableView!.isHidden = true

        
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
        } else {
            
            // Set image
            // Taken with RP Camera
            self.mediaAsset.image = shareImageAssets.last!
        }
        
        
        // (4) Stylize title
        configureView()
        
        
        // (5) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
        
        // (6) Add tap to save photo
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(savePhoto))
        saveTap.numberOfTapsRequired = 1
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.addGestureRecognizer(saveTap)
        
        // (7) Add tap to share photo
        let shareTap = UITapGestureRecognizer(target: self, action: #selector(shareMedia))
        shareTap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(shareTap)
        
        
        // (8) Add dismiss keyboard tap
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(dismissTap)

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
}
