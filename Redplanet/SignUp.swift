//
//  SignUp.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

/*
 Class that allows people to create an account and Sign Up.
 */

class SignUp: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var newEmail: UITextField!
    @IBOutlet weak var newUsername: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Sign up
    func signUp() {
        
        let newRPUserEmailAddress = newEmail.text!.lowercased().replacingOccurrences(of: " ", with: "")
        let newRPUsername = newUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
        let newRPUserPassword = newPassword.text!.replacingOccurrences(of: " ", with: "")
        
        if newRPUsername.characters.count < 6 {
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Username",
                                                          message: "Username must be between 6-15 characters long.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)
            
            
        } else if newRPUsername.characters.count > 15 {
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Username",
                                                          message: "Username must be between 6-15 characters long.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)

            
        } else if newRPUserEmailAddress.isEmpty {

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Email",
                                                          message: "Please enter a valid email.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)
            
        } else if newRPUserPassword.characters.count < 8 {

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Password",
                                                          message: "Your password must be at least eight characters long.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)


        } else {
            // Disable button
            self.continueButton.isUserInteractionEnabled = false
            
            // OTHERWISE if credentials are correct, create the new user!
            let newUser = PFUser()

            // Remove whitespace and newline
            newUser.username = newRPUsername.trimmingCharacters(in: NSCharacterSet.whitespaces)
            newUser.password = newRPUserPassword
            newUser.email = newRPUserEmailAddress
            newUser["private"] = true
            // Save default picture
            let imageData = UIImageJPEGRepresentation(UIImage(named: "GenderNeutralUser")!, 0.5)
            let imageFile = PFFile(data: imageData!)
            newUser["userProfilePicture"] = imageFile
            newUser["userBiography"] = ""
            newUser.signUpInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // Enable button
                    self.continueButton.isUserInteractionEnabled = true
                    
                    // Set installation
                    let installation = PFInstallation.current()
                    installation!["user"] = PFUser.current()
                    installation!["username"] = PFUser.current()!.username!
                    installation!.saveEventually()
                    
                    // Push VC
                    let nameVC = self.storyboard?.instantiateViewController(withIdentifier: "fullNameVC") as! FullName
                    self.navigationController?.pushViewController(nameVC, animated: true)
                    
                } else {
                    print("ERROR: \(error?.localizedDescription as Any)")
                    let usernameCount = PFUser.query()!
                    usernameCount.whereKey("username", equalTo: newRPUsername)
                    usernameCount.countObjectsInBackground(block: { (count: Int32, error: Error?) in
                        if count > 0 {
                            // MARK: - AZDialogViewController
                            let dialogController = AZDialogViewController(title: "💩\nSign up failed.",
                                                                          message: "Your email is invalid or your username is taken.")
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
                            
                            // Add settings button
                            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                                // Enable button
                                self.continueButton.isUserInteractionEnabled = true
                                // Dismiss
                                dialog.dismiss()
                            }))
                            
                            dialogController.show(in: self)
                        } else {
                            // MARK: - AZDialogViewController
                            let dialogController = AZDialogViewController(title: "💩\nSign up failed.",
                                                                          message: "Poor connection error.")
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
                            
                            // Add settings button
                            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                                // Enable button
                                self.continueButton.isUserInteractionEnabled = true
                                // Dismiss
                                dialog.dismiss()
                            }))
                            
                            dialogController.show(in: self)
                        }
                    })
                }
            })
        }
    }
    
    
    
    // MARK: - UITextFieldDelegate method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if newEmail.isFirstResponder {
            self.newUsername.becomeFirstResponder()
        }else if newUsername.isFirstResponder {
            self.newPassword.becomeFirstResponder()
        }else {
            // Sign the user up
            self.signUp()
        }
        
        return true
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set first responder
        self.newEmail.becomeFirstResponder()
        
        // Create rounded buttons
        self.continueButton.layer.cornerRadius = 25.0
        self.continueButton.clipsToBounds = true
        
        // Add sign up method
        let signUpTap = UITapGestureRecognizer(target: self, action: #selector(signUp))
        signUpTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(signUpTap)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
