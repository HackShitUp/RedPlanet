//
//  NewProfilePhoto.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/27/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import SVProgressHUD


// Array to hold changed profile photo
var changedProPicImg = [UIImage]()

class NewProfilePhoto: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var proPicCaption: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func edit(_ sender: AnyObject) {
        // CLImageEditor
        let editor = CLImageEditor(image: self.rpUserProPic.image!)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    
    
    // MARK: - CLImageEditor
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.rpUserProPic.image = image
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    
    
    // Function to handle caption
    func complete() {
        
        // Show Progress
        SVProgressHUD.show()
        
        // ***
        // Set user's profile picture as a PFFile ***
        // ***
        let proPicData = UIImagePNGRepresentation(self.rpUserProPic.image!)
        let proPicFile = PFFile(data: proPicData!)
        
        // (1) Save user's data
        PFUser.current()!["proPicExists"] = true
        PFUser.current()!["userProfilePicture"] = proPicFile
        
        
        
        // (2) Save to Parse: "ProfilePhoto"
        let profilePhoto = PFObject(className: "ProfilePhoto")
        profilePhoto["fromUser"] = PFUser.current()!
        profilePhoto["userId"] = PFUser.current()!.objectId!
        profilePhoto["username"] = PFUser.current()!.username!
        profilePhoto["userProfilePicture"] = proPicFile
        profilePhoto["proPicCaption"] = self.proPicCaption.text!
        profilePhoto.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully saved profile photo: \(profilePhoto)")
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                
                // (3) Save to newsfeed
                let newsfeeds = PFObject(className: "Newsfeeds")
                newsfeeds["byUser"] = PFUser.current()!
                newsfeeds["username"] = PFUser.current()!.username!
                newsfeeds["mediaAsset"] = proPicFile
                newsfeeds["textPost"] = self.proPicCaption.text!
                newsfeeds["contentType"] = "pp"
                newsfeeds.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        print("Successfully saved profile photo: \(newsfeeds)")
                        
                        // Post notification
                        // NSNotificationCenter.defaultCenter().postNotificationName("profileLike", object: nil)
                        
                        
                        // Present alert
                        let alert = UIAlertController(title: "Successfully Saved Changes",
                                                      message: "Your updated Profile Photo was shared in the news feed.",
                                                      preferredStyle: .alert)
                        
                        let ok = UIAlertAction(title: "ok",
                                               style: .default,
                                               handler: {(alertAction: UIAlertAction!) in
                                                
                                                // Pop view controller
                                                self.navigationController!.popViewController(animated: true)
                        })
                        
                        
                        alert.addAction(ok)
                        self.present(alert, animated: true, completion: nil)
                        
                        
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
                

                
                
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
        })
    }
    
    
    
    
    
    
    // Options for profile picture
    func changePhoto(sender: AnyObject) {
        
        // Instantiate UIImagePickerController
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = true
        image.navigationBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        image.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)]
        
        
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let change = UIAlertAction(title: "Update Profile Photo",
                                   style: .default,
                                   handler: { (alertAction: UIAlertAction!) in
                                    
                                    
                                    PFUser.current()!["proPicExists"] = true
                                    PFUser.current()!.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            print("Saved Bool!")
                                            
                                            // Show imagePicker
                                            self.present(image, animated: false, completion: nil)

                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            
                                            // Show Network
                                            let error = UIAlertController(title: "Changes Failed",
                                                                          message: "Something went wrong 😬. Please try again later.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            error.addAction(ok)
                                            self.present(error, animated: true, completion: nil)
                                            
                                        }
                                    })
                                    
        })
        
        
        // Remove
        let remove = UIAlertAction(title: "Remove Profile Photo",
                                   style: .destructive,
                                   handler: { (alertAction: UIAlertAction!) in
                                    
                                    // Show Progress
                                    SVProgressHUD.show()
                                    
                                    
                                    // Set boolean and save
                                    PFUser.current()!["proPicExists"] = false
                                    PFUser.current()!.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            // Dismiss
                                            SVProgressHUD.dismiss()
                                            
                                            // Replace current photo
                                            self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            // Dismiss
                                            SVProgressHUD.dismiss()
                                            
                                            // Show Network
                                            let error = UIAlertController(title: "Changes Failed",
                                                                          message: "Something went wrong 😬.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            error.addAction(ok)
                                            self.present(error, animated: true, completion: nil)
                                        }
                                    })
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        
        if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
            alert.addAction(change)
            alert.addAction(remove)
            alert.addAction(cancel)
        } else {
            alert.addAction(change)
            alert.addAction(cancel)
        }
        
        self.navigationController!.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    


    // MARK: - UITextViewDelegate method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.proPicCaption.text! == "Say something about your profile photo..." {
            self.proPicCaption.text! = ""
        }
    }
    
    
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!)
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
            self.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)'s Profile Photo"
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Get profile photo's caption
        let proPic = PFQuery(className: "ProfilePhoto")
        proPic.whereKey("fromUser", equalTo: PFUser.current()!)
        proPic.getFirstObjectInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
                    // Profile Photo Exists
                    // Handle optional chaining for profile photo's caption
                    if let caption = object!["proPicCaption"] as? String {
                        if caption == " " {
                            self.proPicCaption.text! = "Say something about your profile photo..."
                        } else {
                            self.proPicCaption.text! = caption
                        }
                        
                    } else {
                        self.proPicCaption.text! = "Say something about your profile photo..."
                    }
                } else {
                    // Profile Photo DOES NOT Exist
                    self.proPicCaption.text! = "Say something about your profile photo..."
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        // Stylize title
        configureView()
        

        // Set initial image
        self.rpUserProPic.image = changedProPicImg.last!
        
        // Set layouts
        self.rpUserProPic.layoutIfNeeded()
        self.rpUserProPic.layoutSubviews()
        self.rpUserProPic.setNeedsLayout()
        
        // Load user's current profile picture
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        self.rpUserProPic.layer.borderWidth = 0.5
        self.rpUserProPic.clipsToBounds = true
        
        // Design profile photo's borders and border colors
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.rpUserProPic.layer.borderWidth = 1.0
        self.rpUserProPic.clipsToBounds = true
        
        // Design button corners
        self.doneButton.layer.cornerRadius = 2.0
        self.doneButton.clipsToBounds = true
        self.doneButton.layer.cornerRadius = 15.0
        self.doneButton.clipsToBounds = true
        
        // Set method tap to handle caption
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(complete))
        captionTap.numberOfTapsRequired = 1
        self.doneButton.isUserInteractionEnabled = true
        self.doneButton.addGestureRecognizer(captionTap)
        
        // Add method tap to zoom
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
