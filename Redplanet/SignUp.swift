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
        // November 17th 2015
        let newRPUserEmailAddress = newEmail.text!.lowercased().replacingOccurrences(of: " ", with: "")
        let newRPUsername = newUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
        let newRPUserPassword = newPassword.text!.replacingOccurrences(of: " ", with: "")
        
        if newRPUsername.characters.count < 6 {
            // Show that Username must be at least 6 characters long
            let alert = UIAlertController(title: "Invalid Username",
                                          message: "Username must be between 6-15 characters.",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: false, completion: nil)
            
            
        } else if newRPUsername.characters.count > 15 {
            // Show that Username must be at least 6 characters long
            let alert = UIAlertController(title: "Invalid Username",
                                          message: "Username must be between 6-15 characters.",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: false, completion: nil)
            
        } else if newRPUserEmailAddress.isEmpty {
            // Show that user's passwords must match && password must be greater than 8 characters long
            let alert = UIAlertController(title: "Invalid Email",
                                          message: "Please enter a valid email.",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: false, completion: nil)
            
        } else if newRPUserPassword.characters.count < 8 {
            // Show that user's passwords must match && password must be greater than 8 characters long
            let alert = UIAlertController(title: "Invalid Password",
                                          message: "Your password is either less than at least eight characters or too simple.",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: false, completion: nil)
            
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
            let imageData = UIImageJPEGRepresentation(UIImage(named: "Gender Neutral User-100")!, 0.5)
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
                    let alert = UIAlertController(title: "Sign up failed.",
                                                  message: "Your email is invalid or your username is taken.",
                                                  preferredStyle: .alert)
                    let tryAgain = UIAlertAction(title: "Try Again",
                                                 style: .cancel,
                                                 handler: { (alertAction: UIAlertAction!) in
                                                    // Enable button
                                                    self.continueButton.isUserInteractionEnabled = true
                    })
                    
                    alert.addAction(tryAgain)
                    alert.view.tintColor = UIColor.black
                    self.present(alert, animated: true, completion: nil)
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
