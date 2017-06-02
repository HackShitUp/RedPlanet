//
//  ProfileEdit.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

import Parse
import ParseUI
import Bolts
import SDWebImage

// Array to hold profile photo's caption
var profilePhotoCaption = [String]()

// Variable to determine whether the profile photo is NEW
var isNewProPic: Bool = false

// Bool to determine whether caption has changed
var didChangeCaption: Bool = false

/*
 UIViewController class that allows the current user to edit their:
 • Profile Photo (create new, edit caption, or remove current).
 • Birthday
 • Bio
 The user must tap the "Save" UIBarButtonItem at the top right of the UIViewController to save any changes that were made. 
 */

class ProfileEdit: UIViewController, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, CLImageEditorDelegate {
    
    
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
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to show alert
    func showDialogAlert() {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Successfully Saved Changes!",
                                                      message: "New Profile Photos are automatically pushed to the news feeds.")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            button.layer.masksToBounds = true
        }
        
        // Add Delete button
        dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            // Clear cache again
            PFQuery.clearAllCachedResults()
            PFFile.clearAllCachedDataInBackground()
            URLCache.shared.removeAllCachedResponses()
            SDImageCache.shared().clearMemory()
            SDImageCache.shared().clearDisk()
            // Re-enable backButton
            self.backButton.isEnabled = true
            // Send Notification to friendsNewsfeed
            NotificationCenter.default.post(name: Notification.Name(rawValue: "HOME"), object: nil)
            // Send Notification to myProfile
            NotificationCenter.default.post(name: myProfileNotification, object: nil)
            // Pop view controller
            _ = self.navigationController?.popViewController(animated: true)
        }))
        
        dialogController.show(in: self)
    }
    

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBAction func save(_ sender: AnyObject) {
        
        if rpUsername.text!.isEmpty {
        // NO USERNAME
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Username",
                                                          message: "Please enter your username to save changes.")
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
            
        } else if rpEmail.text!.isEmpty {
        // NO EMAIL
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Email",
                                                          message: "Please enter your email to save changes.")
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
            
        } else if self.rpName.text!.isEmpty {
        // NO NAME
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Please Enter Your Full Name",
                                                          message: "This helps your friends find you better.")
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
        // CLEAR
            // Disable back button
            self.backButton.isEnabled = false

            // Handle optional chaining
            if profilePhotoCaption.isEmpty {
                profilePhotoCaption.append(" ")
            }

            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Updating Profile...")
            
            // (A) Current User's Birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.userBirthday.date)
            
            // (B) Current User's Profile Photo
            let proPicData = UIImageJPEGRepresentation(self.rpUserProPic.image!, 0.5)
            let proPicFile = PFFile(data: proPicData!)
            
            // (C) Configure username and fullname
            var rUsername = self.rpUsername.text!
            rUsername = rUsername.replacingOccurrences(of: " ", with: "")
            rUsername = rUsername.replacingOccurrences(of: "🚀", with: "")
            rUsername = rUsername.replacingOccurrences(of: "💫", with: "")
            var fullName = self.rpName.text!
            fullName = fullName.replacingOccurrences(of: "🚀", with: "")
            fullName = fullName.replacingOccurrences(of: "💫", with: "")
            
            // =====================================================================================================================
            // I) BASIC CREDENTIAL UPDATE ==========================================================================================
            // =====================================================================================================================
            let me = PFUser.current()!
            me["email"] = rpEmail.text!.lowercased()
            me["realNameOfUser"] = fullName
            me["userBiography"] = self.rpUserBio.text!
            me["username"] = rUsername.lowercased()
            me["birthday"] = stringDate
            me["userProfilePicture"] = proPicFile
            me.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved objects: \(me)")

                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showSuccess(withTitle: "Saved")
                    
                    // Enable back button
                    self.backButton.isEnabled = true
                    
                    
                    // ================================================================================================
                    // II) NEW PROFILE PHOTO ==========================================================================
                    // ================================================================================================
                    if isNewProPic == true {
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showProgress(withTitle: "Updating Profile...")
                        
                        // New Profile Photo
                        let postsClass = PFObject(className: "Posts")
                        postsClass["byUser"] = PFUser.current()!
                        postsClass["byUsername"] = PFUser.current()!.username!
                        postsClass["photoAsset"] = proPicFile
                        postsClass["contentType"] = "pp"
                        postsClass["saved"] = false
                        postsClass["textPost"] = profilePhotoCaption.last!
                        postsClass.saveInBackground(block: {
                            (success: Bool, error: Error?) in
                            if success {
                                print("Pushed New Profile Photo to Newsfeeeds:\n\(postsClass)\n")

                                // Show showDialogAlert
                                self.showDialogAlert()
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showError(withTitle: "Network Error")
                                // Re-enable backButton
                                self.backButton.isEnabled = true
                            }
                        })
                    }// END PROFILE PHOTO UPDATE
                    // =====================================================================================================
                    // III) PROFILE PHOTO CAPTION UPDATE ===================================================================
                    // =====================================================================================================
                    if isNewProPic == false && didChangeCaption == true {
                        
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.showProgress(withTitle: "Updating Profile Photo Caption...")
                        
                        // Change caption
                        // Find in <Newsfeeds>
                        let newsfeedProPic = PFQuery(className: "Posts")
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
                                        
                                        // MARK: - RPHelpers
                                        let rpHelpers = RPHelpers()
                                        rpHelpers.showSuccess(withTitle: "Updated Profile Photo Caption")
                                        
                                        // Show showDialogAlert
                                        self.showDialogAlert()
                                        
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // MARK: - RPHelpers
                                        let rpHelpers = RPHelpers()
                                        rpHelpers.showError(withTitle: "Network Error")
                                        // Re-enable backButton
                                        self.backButton.isEnabled = true
                                    }
                                })
                                
                            } else {
                                print(error?.localizedDescription as Any)
                                // MARK: - RPHelpers
                                let rpHelpers = RPHelpers()
                                rpHelpers.showError(withTitle: "Network Error")
                                // Re-enable backButton
                                self.backButton.isEnabled = true
                            }
                        })
                    } // end CAPTION UPDATE
                    
                    // Show Alert
                    self.showDialogAlert()
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                    // Re-enable backButton
                    self.backButton.isEnabled = true
                }
            })
        }
        
        // Send Notification to myProfile
        NotificationCenter.default.post(name: myProfileNotification, object: nil)
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

        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Profile Photo", message: "Options")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        // Add Cancel button
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.setTitle("CANCEL", for: [])
            return true
        }
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
            button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
            button.layer.masksToBounds = true
        }
        
        // (1) NEW PRO PIC
        let new = AZDialogAction(title: "New Profile Photo", handler: { (dialog) -> (Void) in
            // Present image picker
            dialog.present(image, animated: false, completion: nil)
        })
        
        // (2) EDIT PRO PIC CAPTION
        let edit = AZDialogAction(title: "Edit Caption", handler: { (dialog) -> (Void) in
            // Save boolean
            PFUser.current()!["proPicExists"] = true
            PFUser.current()!.saveInBackground(block: {
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
                    
                    dialog.present(newProPicVC, animated: true, completion: nil)
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        })
        
        // (3) DELETE PRO PIC CAPTION
        let delete = AZDialogAction(title: "Delete Profile Photo", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            
            // MARK: - RPHelpers
            let rpHelpers = RPHelpers()
            rpHelpers.showProgress(withTitle: "Deleting...")
            
            // Set boolean and save
            PFUser.current()!["proPicExists"] = false
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // Replace current photo
                    self.rpUserProPic.image = UIImage(named: "GenderNeutralUser")
                    
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showSuccess(withTitle: "Deleted Profile Photo")
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
            
            // Save again
            PFUser.current()!.saveEventually()
        })

        // Show options depending on whether or not user has a profile photo
        if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
            dialogController.addAction(new)
            dialogController.addAction(edit)
            dialogController.addAction(delete)
            dialogController.show(in: self)
        } else {
            dialogController.addAction(new)
            dialogController.show(in: self)
        }
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
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Configure UITabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.tabBarController?.tabBar.isTranslucent = true
        // MARK: - RPExtensions; Hide rpButton
        rpButton.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Add border to top of container
        let upperBorder = CALayer()
        upperBorder.backgroundColor = UIColor.darkGray.cgColor
        upperBorder.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(self.view.frame.width), height: CGFloat(0.50))
        self.container.layer.addSublayer(upperBorder)
        
        // Set maximum birthday
        self.userBirthday.maximumDate = Date()
        
        // Configure textColor for rpUserBio
        self.rpUserBio.textColor = UIColor.lightGray

        // Add icons to UITextField
        let userIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 15))
        userIcon.contentMode = .scaleAspectFit
        userIcon.image = UIImage(named: "User_48")
        self.rpUsername.leftViewMode = .always
        self.rpUsername.leftView = userIcon
        self.rpUsername.addSubview(userIcon)
        
        let nameIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 15))
        nameIcon.contentMode = .scaleAspectFit
        nameIcon.image = UIImage(named: "Name")
        self.rpName.leftViewMode = .always
        self.rpName.leftView = nameIcon
        self.rpName.addSubview(nameIcon)
        
        let emailIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 15))
        emailIcon.contentMode = .scaleAspectFit
        emailIcon.image = UIImage(named: "Mail")
        self.rpEmail.leftViewMode = .always
        self.rpEmail.leftView = emailIcon
        self.rpEmail.addSubview(emailIcon)
        
        // (A) Configure User's Profile Photo
        // MARK: - RPExtensions
        self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 3, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
        
        // (B) If there exists, a current user...
        if PFUser.current() != nil {
            // (1) Set birthday date
            if let bday = PFUser.current()!["birthday"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
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
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            } else {
                // Set default
                self.rpUserProPic.image = UIImage(named: "GenderNeutralUser")
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPExtensions; Show rpButton
        rpButton.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UITextField Delegate Method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.rpUsername?.resignFirstResponder()
        self.rpName?.resignFirstResponder()
        self.rpEmail?.resignFirstResponder()
        return true
    }
    
    // MARK: - UITextView Delegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.rpUserBio.textColor = UIColor.black
        if self.rpUserBio.text == "Introduce yourself..." {
            self.rpUserBio.text = ""
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.rpUserBio.resignFirstResponder()
        }
        return true
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
                if let chosenImage = info[UIImagePickerControllerEditedImage] as? UIImage {
                    // Set image
                    self.rpUserProPic.image = chosenImage
                    
                    
                    // Append image
                    changedProPicImg.append(chosenImage)
                    
                    
                    // Dismiss view controller
                    self.dismiss(animated: true, completion: nil)
                    
                    // MARK: - CLImageEditor
                    let editor = CLImageEditor(image: self.rpUserProPic.image!)
                    editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
                    editor?.delegate = self
                    let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
                    tool?.title = "Emoji"
                    self.present(editor!, animated: true, completion: nil)
                }
            } else {
                print(error?.localizedDescription as Any)
                // Dismiss view controller
                self.dismiss(animated: true, completion: nil)
            }
        })
        
        // Set Bool
        isNewProPic = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Save bool
        PFUser.current()!["proPicExists"] = false
        PFUser.current()!.saveInBackground()
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
}
