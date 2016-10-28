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



// Variable to check whether user has changed his or her profile photo
var proPicChanged = false

// Variable to hold profile photo's caption
var profilePhotoCaption = [String]()


class ProfileEdit: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUserBio: UITextView!
    @IBOutlet weak var rpUsername: UITextField!
    @IBOutlet weak var rpName: UITextField!
    @IBOutlet weak var rpEmail: UITextField!
    @IBOutlet weak var userBirthday: UIDatePicker!
    @IBOutlet weak var container: UIView!
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBAction func save(_ sender: AnyObject) {
        
        // Check for empty email...
        if rpEmail.text!.isEmpty {
            let alert = UIAlertController(title: "Invalid Email",
                                          message: "Please enter your email address to save changes.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        } else if self.rpName.text!.isEmpty {
            
            let alert = UIAlertController(title: "Please Enter Your Full Name",
                                          message: "We request your full name so friends can find you easily.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            // MARK: - SVPProgressHUD
            // delegate method
            // Show
            SVProgressHUD.show()
            
            // Set birthday format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.userBirthday.date)
            
            
            // Save user's profilePicture
            let proPicData = UIImagePNGRepresentation(self.rpUserProPic.image!)
            let proPicFile = PFFile(data: proPicData!)
            
            // Save changes to Parse className: "_User"
            let me = PFUser.current()!
            me.email = rpEmail.text!
            me["realNameOfUser"] = rpName.text!
            me["userBiography"] = rpUserBio.text!
            me.username = self.rpUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
            me["birthday"] = stringDate
            me["userProfilePicture"] = proPicFile
            me.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved objects: \(me)")
                    
                    
                    // MARK: - SVProgressHUD
                    // delegate method
                    // Dismiss
                    SVProgressHUD.dismiss()
                    
                    // User's profile picture
                    let proPicData = UIImagePNGRepresentation(self.rpUserProPic.image!)
                    let proPicFile = PFFile(data: proPicData!)
                    
                    
                    // Save to Parse: "ProfilePhoto"
                    let profilePhoto = PFObject(className: "ProfilePhoto")
                    profilePhoto["fromUser"] = PFUser.current()!
                    profilePhoto["userId"] = PFUser.current()!.objectId!
                    profilePhoto["username"] = PFUser.current()!.username!
                    profilePhoto["userProfilePicture"] = proPicFile
                    profilePhoto["proPicCaption"] = profilePhotoCaption.last!
                    profilePhoto.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved profile photo: \(profilePhoto)")
                            
                            
                            // Post notification
//                            NSNotificationCenter.defaultCenter().postNotificationName("profileLike", object: nil)
                            
                            
                            // Present alert
                            let alert = UIAlertController(title: "Successfully Saved Changes",
                                                          message: "Send your friends Push Notifications about your updated Profile or your Profile Photo?",
                                                          preferredStyle: .alert)
                            
                            let yes = UIAlertAction(title: "yes",
                                                    style: .default,
                                                    handler: { (alertAction: UIAlertAction!) in
                                                        
//                                                        for var i = 0; i <= myFriends.count - 1; i += 1 {
                                                        
                                                            
                                                            // TODO::
                                                            // Send push notification
//                                                            OneSignal.defaultClient().postNotification(
//                                                                ["contents":
//                                                                    ["en": "\(PFUser.currentUser()!.username!)'s profile photo was updated"],
//                                                                 "include_player_ids": ["\(self.friendApnsIds[i])"]
//                                                                ]
//                                                            )
                                                            
//                                                        }
                                                        
                                                        
                                                        // Pop view controller
                                                        self.navigationController!.popViewController(animated: true)
                            })
                            
                            let no = UIAlertAction(title: "no",
                                                   style: .destructive,
                                                   handler: {(UIAlertAction: UIAlertAction!)  in
                                                    // Pop view controller
                                                    self.navigationController!.popViewController(animated: true)
                            })
                            
                            alert.addAction(yes)
                            alert.addAction(no)
                            self.present(alert, animated: true, completion: nil)
                            
                            
                            
                        } else {
                            print(error?.localizedDescription)
                            
                            // MARK:- SVProgressHUD
                            // delegate method
                            // Dismiss
                            SVProgressHUD.dismiss()
                        }
                    })
                    
                    
                } else {
                    print(error?.localizedDescription)
                    
                    // MARK:- SVProgressHUD
                    // delegate method
                    // Dismiss
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
        image.navigationBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        image.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)]
        
        
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        let change = UIAlertAction(title: "Update Profile Photo",
                                   style: .default,
                                   handler: { (alertAction: UIAlertAction!) in
                                    
                                    let me = PFUser.current()!
                                    me["proPicExists"] = true
                                    me.saveInBackground(block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            print("Saved Bool!")
                                            
                                            let image = UIImagePickerController()
                                            image.delegate = self
                                            image.sourceType = UIImagePickerControllerSourceType.photoLibrary
                                            image.allowsEditing = true
                                            image.navigationBar.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                                            image.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)]
                                            
                                            self.present(image, animated: false, completion: nil)
                                            
                                        } else {
                                            print(error?.localizedDescription)
                                            
                                            // Show Network
                                            let error = UIAlertController(title: "Poor Network Connection",
                                                                          message: "Please connect to the internet to update your Profile Photo.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            error.addAction(ok)
                                            self.present(error, animated: true, completion: nil)
                                            
                                        }
                                    })
                                    
        })
        
        let edit = UIAlertAction(title: "Edit Caption",
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
                                            
                                            // Present PopOverpresentationcontroller
                                            self.performSegue(withIdentifier: "popOver", sender: self)
                                            
                                        } else {
                                            print(error?.localizedDescription)
                                            
                                            // Show Network
                                            let error = UIAlertController(title: "Poor Network Connection",
                                                                          message: "Please connect to the internet to update your Profile Photo.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: nil)
                                            
                                            error.addAction(ok)
                                            self.present(error, animated: true, completion: nil)
                                        }
                                    })
        })
        
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
                                            
                                            
                                            // Append to profilePhotoCaption
                                            profilePhotoCaption.append(" ")
                                            
                                        } else {
                                            print(error?.localizedDescription)
                                            // Dismiss
                                            SVProgressHUD.dismiss()
                                            
                                            // Show Network
                                            let error = UIAlertController(title: "Poor Network Connection",
                                                                          message: "Please connect to the internet to update your Profile Photo.",
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
            alert.addAction(edit)
            alert.addAction(remove)
            alert.addAction(cancel)
        } else {
            alert.addAction(change)
            alert.addAction(cancel)
        }
        
        self.navigationController!.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
    // Function to dismiss keybaord
    func dismissKeyboard() {
        // Resign First Responders
        rpUserBio.resignFirstResponder()
        rpName.resignFirstResponder()
        rpEmail.resignFirstResponder()
        rpUsername.resignFirstResponder()
    }
    
    
    // Prevent forced sizes for ipad
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popOver" {
            let newProfilePhoto = segue.destination as! NewProfilePhoto
            let controller = newProfilePhoto.popoverPresentationController
            
            if controller != nil {
                controller?.delegate = self
            }
        }

    }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // (A) Get profile photo's caption
        let profilePhoto = PFQuery(className: "ProfilePhoto")
        profilePhoto.whereKey("fromUser", equalTo: PFUser.current()!)
        profilePhoto.getFirstObjectInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if let proPicCaption = object!["proPicCaption"] as? String {
                    profilePhotoCaption.append(proPicCaption)
                } else {
                    profilePhotoCaption.append(" ")
                }
            } else {
                print(error?.localizedDescription)
            }
        })
        
        
        

        // (B) Layout views
        self.rpUserProPic.layoutIfNeeded()
        self.rpUserProPic.layoutSubviews()
        self.rpUserProPic.setNeedsLayout()
        
        // Load user's current profile picture
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        self.rpUserProPic.layer.borderWidth = 0.5
        self.rpUserProPic.clipsToBounds = true
        
        
        
        // (C) If there exists, a current user...
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
                        print(error?.localizedDescription)
                        // Set default
                        self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                })
            } else {
                // Set default
                self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
            }
            
        }
        
        
        
        
        // (D) Add target function to user's profile picture
        let changeProPic = UITapGestureRecognizer(target: self, action: #selector(changePhoto))
        changeProPic.numberOfTapsRequired = 1
        self.rpUserProPic.addGestureRecognizer(changeProPic)
        self.rpUserProPic.isUserInteractionEnabled = true
        

        // (E) Add Tap to hide keyboard
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
