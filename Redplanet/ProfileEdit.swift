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


// Array to hold profile photo's caption
var profilePhotoCaption = [String]()

class ProfileEdit: UIViewController, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {
    
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
            

            // Show Progress
            SVProgressHUD.show()
            
            // Set birthday format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.userBirthday.date)
            
            
            // Set user's profile picture as a PFFile
            let proPicData = UIImagePNGRepresentation(self.rpUserProPic.image!)
            let proPicFile = PFFile(data: proPicData!)
            
            // Save changes for PFUser.current()'s data
            PFUser.current()!.email = rpEmail.text!
            PFUser.current()!["realNameOfUser"] = rpName.text!
            PFUser.current()!["userBiography"] = rpUserBio.text!
            PFUser.current()!.username = self.rpUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
            PFUser.current()!["birthday"] = stringDate
            PFUser.current()!["userProfilePicture"] = proPicFile
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved changes: \(PFUser.current()!)")
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    // Pop view controller
                    self.navigationController!.popViewController(animated: true)
                    
                } else {
                    print(error?.localizedDescription)
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
                                            
                                            // Push VC
                                            let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
                                            self.navigationController?.pushViewController(newProPicVC, animated: true)
                                            
                                        } else {
                                            print(error?.localizedDescription)
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
                                            print(error?.localizedDescription)
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
                
                
                // CLImageEditor
                let editor = CLImageEditor(image: self.rpUserProPic.image!)
                editor?.delegate = self
                self.present(editor!, animated: true, completion: nil)
                
                
            } else {
                print(error?.localizedDescription)
                
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
        
        
        // Push VC
        let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
        self.navigationController?.pushViewController(newProPicVC, animated: true)
        
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
        
        
        // Push VC
        let newProPicVC = self.storyboard?.instantiateViewController(withIdentifier: "newProPicVC") as! NewProfilePhoto
        self.navigationController?.pushViewController(newProPicVC, animated: true)
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
