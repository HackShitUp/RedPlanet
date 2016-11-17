//
//  ProfileEdit.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD



// Array to hold profile photo's caption
var profilePhotoCaption = [String]()

// Variable to determine whether the profile photo is NEW
var newProfilePhoto: Bool = false

class ProfileEdit: UIViewController, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {

    // Bool to determine whether caption has changed
    var changedCaption: Bool = false
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUserBio: UITextView!
    @IBOutlet weak var rpUsername: UITextField!
    @IBOutlet weak var rpName: UITextField!
    @IBOutlet weak var rpEmail: UITextField!
    @IBOutlet weak var userBirthday: UIDatePicker!
    @IBOutlet weak var container: UIView!
    
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBAction func save(_ sender: AnyObject) {
        
        
        // Check for empty email...
        if rpEmail.text!.isEmpty {
            
            let alert = UIAlertController(title: "Invalid Email",
                                          message: "Please enter your email to save changes.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        } else if self.rpName.text!.isEmpty {
            
            let alert = UIAlertController(title: "Please Enter Your Full Name",
                                          message: "Help your friends find you better!",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            // Disable back button
            self.backButton.isEnabled = false
            
            // I) Save user's data
            // II) Save user's Profile Photo but check the following
            /*
             
             The user can decide to do either of the following: 
             
             (A) Change Profile Photo - then,
             • User's 'proPicExists' == true
             • User's new Profile Photo must be pushed to <Newsfeeds>
             
             // (B) Change Profile Photo's caption - then,
             • User's 'proPicExists' == true
             • User's new Profile Photo must NOT be pushed to <Newsfeeds>
             
             // (C) Removed Profile Photo
             • User's 'proPicExists' == false
             • User's new Profile Photo must NOT be pushed to <Newsfeeds>
             
             */
            
            // Handle optional chaining
            if profilePhotoCaption.isEmpty {
                profilePhotoCaption.append(" ")
            }

            // Show Progress
            SVProgressHUD.show()
            
            // (A) Current User's Birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.userBirthday.date)
            
            
            // (B) Current User's Profile Photo
            let proPicData = UIImageJPEGRepresentation(self.rpUserProPic.image!, 0.5)
            let proPicFile = PFFile(data: proPicData!)
            
            
            
            // I) Save changes to Parse className: "_User"
            let me = PFUser.current()!
            me.email = rpEmail.text!
            me["realNameOfUser"] = self.rpName.text!
            me["userBiography"] = rpUserBio.text!
            me.username = self.rpUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
            me["birthday"] = stringDate
            me["userProfilePicture"] = proPicFile
            me.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved objects: \(me)")
                  

                    /*
                     
                     IF there exists a new profile photo, determine whether user has just changed its caption.
                     Otherwise, push the new profile photo to the new newsfeeds.
                     
                    */
                    
                    
                    if self.rpUserProPic.image == UIImage(named: "Gender Neutral User-100") {
                        // User has removed his/her profile photo
                        
                        // Dismiss Progress
                        SVProgressHUD.dismiss()
                        
                        // Present alert
                        let alert = UIAlertController(title: "Successfully Saved Changes",
                                                      message: "New Profile Photos are automatically pushed to the news feeds.",
                                                      preferredStyle: .alert)
                        
                        let ok = UIAlertAction(title: "ok",
                                               style: .default,
                                               handler: { (alertAction: UIAlertAction!) in
                                                
                                                // Re-enable backButton
                                                self.backButton.isEnabled = true
                                                
                                                // Send Notification to friendsNewsfeed
                                                NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                
                                                // Send Notification to myProfile
                                                NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                
                                                // Pop view controller
                                                self.navigationController?.popViewController(animated: true)
                        })
                        
                        
                        
                        alert.addAction(ok)
                        alert.view.tintColor = UIColor.black
                        self.present(alert, animated: true, completion: nil)
                        
                    } else {
                        
                        if self.changedCaption == true {
                            // Change caption
                            // Find in <Newsfeeds>
                            let newsfeedProPic = PFQuery(className: "Newsfeeds")
                            newsfeedProPic.whereKey("byUser", equalTo: PFUser.current()!)
                            newsfeedProPic.whereKey("contentType", equalTo: "pp")
                            newsfeedProPic.order(byDescending: "createdAt")
                            newsfeedProPic.getFirstObjectInBackground(block: {
                                (object: PFObject?, error: Error?) in
                                if error == nil {
                                    print("Found")
                                    
                                    // Change Caption
                                    object!["textPost"] = profilePhotoCaption.last!
                                    object!.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if error == nil {
                                            // Changed Caption
                                            print("Changed Caption: \(object)")
                                            
                                            // Dismiss Progress
                                            SVProgressHUD.dismiss()
                                            
                                            // Present alert
                                            let alert = UIAlertController(title: "Successfully Saved Changes",
                                                                          message: "Updated Profile Photos are automatically pushed to the news feeds.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: { (alertAction: UIAlertAction!) in
                                                                    
                                                                    // Re-enable backButton
                                                                    self.backButton.isEnabled = true
                                                                    
                                                                    // Send Notification to friendsNewsfeed
                                                                    NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                                    
                                                                    // Send Notification to myProfile
                                                                    NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                                    
                                                                    // Pop view controller
                                                                    self.navigationController?.popViewController(animated: true)
                                            })
                                            
                                            
                                            alert.addAction(ok)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                            
                            
                        } else {
                            // New Profile Photo
                            let newsfeeds = PFObject(className: "Newsfeeds")
                            newsfeeds["byUser"] = PFUser.current()!
                            newsfeeds["username"] = PFUser.current()!.username!
                            newsfeeds["photoAsset"] = proPicFile
                            newsfeeds["contentType"] = "pp"
                            newsfeeds["textPost"] = profilePhotoCaption.last!
                            newsfeeds.saveInBackground(block: {
                                (success: Bool, error: Error?) in
                                if success {
                                    print("Pushed New Profile Photo to Newsfeeeds:\n\(newsfeeds)\n")
                                    
                                    // Dismiss Progress
                                    SVProgressHUD.dismiss()
                                    
                                    // Present alert
                                    let alert = UIAlertController(title: "Successfully Saved Changes",
                                                                  message: "New Profile Photos are automatically pushed to the news feeds.",
                                                                  preferredStyle: .alert)
                                    
                                    let ok = UIAlertAction(title: "ok",
                                                           style: .default,
                                                           handler: { (alertAction: UIAlertAction!) in
                                                            
                                                            
                                                            // Re-enable backButton
                                                            self.backButton.isEnabled = true

                                                            
                                                            // Send Notification to friendsNewsfeed
                                                            NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                                                            
                                                            // Send Notification to myProfile
                                                            NotificationCenter.default.post(name: myProfileNotification, object: nil)
                                                            
                                                            // Pop view controller
                                                            self.navigationController?.popViewController(animated: true)
                                    })
                                    
                                    
                                    
                                    alert.addAction(ok)
                                    alert.view.tintColor = UIColor.black
                                    self.present(alert, animated: true, completion: nil)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                        
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                }
            })

            
            
        }
    }
    
    
    
    
    
    
    
    
    // Options for profile picture
    func changePhoto(sender: AnyObject) {
        
        
        // Instantiate UIImagePickerController
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = true
        image.navigationBar.tintColor = UIColor.black
        image.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]

        

        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let change = UIAlertAction(title: "Update Profile Photo",
                                   style: .default,
                                   handler: { (alertAction: UIAlertAction!) in
                                    
                                    // Set Bool
                                    newProfilePhoto = true
                                    
                                    // Present image picker
                                    self.present(image, animated: false, completion: nil)
        })
        
        
        let edit = UIAlertAction(title: "Edit Profile Photo Caption",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    
                                    // Save boolean
                                    let me = PFUser.current()!
                                    me["proPicExists"] = true
                                    me.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            
                                            // Append new profile photo
                                            changedProPicImg.append(self.rpUserProPic.image!)
                                            
                                            // Present Popover
                                            let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
                                            newProPicVC.modalPresentationStyle = .popover
                                            newProPicVC.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
                                            
                                            
                                            let popOverVC = newProPicVC.popoverPresentationController
                                            popOverVC?.permittedArrowDirections = .any
                                            popOverVC?.delegate = self
                                            popOverVC?.sourceView = self.rpUserProPic
                                            popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
                                            
                                            
                                            self.present(newProPicVC, animated: true, completion: nil)
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                        }
                                    })
                                    
                                    self.changedCaption = true
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
                                            self.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                                            
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
                                    
                                    
                                    // Save again
                                    PFUser.current()!.saveEventually()
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        
        
        // Show options depending on whether or not user has a profile photo
        if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
            alert.addAction(change)
            alert.addAction(edit)
            alert.addAction(remove)
            alert.addAction(cancel)
        } else {
            alert.addAction(change)
            alert.addAction(cancel)
        }
        
        // Add black tint
        alert.view.tintColor = UIColor.black
        self.navigationController!.present(alert, animated: true, completion: nil)
    }
    
    
    
    // Prevent forced sizes for ipad
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    
    // Show PopOver
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popOver" {
            let newProfilePhoto = segue.destination as! NewProfilePhoto
            newProfilePhoto.modalPresentationStyle = .popover
            newProfilePhoto.preferredContentSize = CGSize(width: 300, height: 300)
            
            let controller = newProfilePhoto.popoverPresentationController
            
            if controller != nil {
                controller?.delegate = self
            }
        }

    }
    
    
    
    
    
    
    
    
    
    // MARK: - UIImagePickerController Delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Edit changes
        PFUser.current()!["proPicExists"] = true
        PFUser.current()!.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if success {
                print("Saved Bool!")
                
                
                
                // Set image
                self.rpUserProPic.image = info[UIImagePickerControllerOriginalImage] as! UIImage
                
                
                // Append image
                changedProPicImg.append(info[UIImagePickerControllerOriginalImage] as! UIImage)
                
                
                // Dismiss view controller
                self.dismiss(animated: true, completion: nil)
                
                
                // MARK: - CLImageEditor
                // Show Editing Options
                let editor = CLImageEditor(image: self.rpUserProPic.image!)
                editor?.delegate = self
                self.present(editor!, animated: true, completion: nil)
                
                
            } else {
                print(error?.localizedDescription as Any)
                
            }
        })
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Save bool
        PFUser.current()!["proPicExists"] = false
        PFUser.current()!.saveInBackground()
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - CLImageEditor delegate methods
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.rpUserProPic.image = image
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
        
        
        // Present Popover
        let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
        newProPicVC.modalPresentationStyle = .popover
        newProPicVC.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
        
        
        let popOverVC = newProPicVC.popoverPresentationController
        popOverVC?.permittedArrowDirections = .any
        popOverVC?.delegate = self
        popOverVC?.sourceView = self.rpUserProPic
        popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        
        self.present(newProPicVC, animated: true, completion: nil)
        
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
        
        
        // Present Popover
        let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
        newProPicVC.modalPresentationStyle = .popover
        newProPicVC.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
        
        
        let popOverVC = newProPicVC.popoverPresentationController
        popOverVC?.permittedArrowDirections = .any
        popOverVC?.delegate = self
        popOverVC?.sourceView = self.rpUserProPic
        popOverVC?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        
        self.present(newProPicVC, animated: true, completion: nil)
    }

    
    
    
    
    

    
    
    // Function to dismiss keybaord
    func dismissKeyboard() {
        // Resign First Responders
        rpUserBio.resignFirstResponder()
        rpName.resignFirstResponder()
        rpEmail.resignFirstResponder()
        rpUsername.resignFirstResponder()
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // (A) Layout views
        self.rpUserProPic.layoutIfNeeded()
        self.rpUserProPic.layoutSubviews()
        self.rpUserProPic.setNeedsLayout()
        
        // Load user's current profile picture
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.rpUserProPic.layer.borderWidth = 0.75
        self.rpUserProPic.clipsToBounds = true
        
        
        
        // (B) If there exists, a current user...
        if PFUser.current() != nil {
            
            // (1) Set birthday date
            if let bday = PFUser.current()!["birthday"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                print("The birthday: \(bday)")
                userBirthday.date = dateFormatter.date(from: bday)!
            }
            
            
            // (2) Set username's title to navigation bar
            if let fullName = PFUser.current()!.value(forKey: "realNameOfUser") as? String {
                self.title = fullName
            }
            
            // (3) Set username
            rpUsername.text = PFUser.current()!.username!
            
            // (4) Set user's biography
            if let RPBiography = PFUser.current()!["userBiography"] as? String {
                if RPBiography.isEmpty {
                    // Set biography
                    rpUserBio.text = "Who are you?"
                } else {
                    rpUserBio.text = RPBiography
                }
            }
            
            // (5) Set user's real name
            if let RPRealName = PFUser.current()!["realNameOfUser"] as? String {
                if RPRealName.isEmpty {
                    rpName.text = "What's your real name?"
                } else {
                    rpName.text = RPRealName
                }
            }
            
            // (6) Set user's email
            if let RPEmail = PFUser.current()!["email"] as? String {
                if RPEmail.isEmpty {
                    rpEmail.text = "What's your email?"
                } else {
                    rpEmail.text = RPEmail
                }
            }
            
            
            // (7) Set user's profile photo
            if let proPic = PFUser.current()!["userProfilePicture"] as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) -> Void in
                    if error == nil {
                        // Set profile photo
                        self.rpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                        // Set default
                        self.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                    }
                })
            } else {
                // Set default
                self.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
            }
            
        }
        
        
        
        
        // (C) Add target function to user's profile picture
        let changeProPic = UITapGestureRecognizer(target: self, action: #selector(changePhoto))
        changeProPic.numberOfTapsRequired = 1
        self.rpUserProPic.addGestureRecognizer(changeProPic)
        self.rpUserProPic.isUserInteractionEnabled = true
        

        // (D) Add Tap to hide keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.numberOfTapsRequired = 1
        self.container.isUserInteractionEnabled = true
        self.view.isUserInteractionEnabled = true
        self.container.addGestureRecognizer(tap)
        self.view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
