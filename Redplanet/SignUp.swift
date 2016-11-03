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
        // Pop back
        self.navigationController!.popViewController(animated: true)
    }
    
    // Sign up
    func signUp() {
        // November 17th 2015
        let newRPUserEmailAddress = newEmail.text!.lowercased()
        let newRPUsername = newUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
        let newRPUserPassword = newPassword.text!
        
        if newRPUsername.characters.count < 6 {
            // Show that Username must be at least 6 characters long
            let alert = UIAlertController(title: "Invalid Username",
                                          message: "Username must be between 6-15 characters.",
                                          preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "ok",
                                             style: .cancel,
                                             handler: nil)
            alert.addAction(cancelAction)
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
            self.present(alert, animated: false, completion: nil)
            
        } else {
            
            
            // OTHERWISE if credentials are correct, create the new user!
            let newUser = PFUser()
            
            // Remove whitespace and newline
            newUser.username = newRPUsername.trimmingCharacters(in: NSCharacterSet.whitespaces)
            newUser.password = newRPUserPassword
            newUser.email = newRPUserEmailAddress
            newUser["private"] = true
            // Save default picture
            let imageData = UIImageJPEGRepresentation(UIImage(named: "Gender Neutral User-96")!, 0.5)
            let imageFile = PFFile(data: imageData!)
            newUser["userProfilePicture"] = imageFile
            newUser["userBiography"] = ""
            newUser["anonymous"] = false
            newUser.signUpInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("User has successfully signed up!")
                    
                    // Set installation
                    let installation = PFInstallation.current()
                    installation!["user"] = PFUser.current()
                    installation!["username"] = PFUser.current()!.username!
                    installation!.saveInBackground(block :{
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved installation data: \(installation)")
                        } else {
                            print(error?.localizedDescription as Any)
                        }
                    })
                    
                    
                    let alert = UIAlertController(title: "Thank You",
                                                  message: "Thank you for signing up for Redplanet!",
                                                  preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok",
                                           style: .cancel,
                                           handler: {(alert: UIAlertAction!) in
                                            // TODO::
                                            // Perform Segue
                                            self.performSegue(withIdentifier: "toSignUp", sender: self)
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    let alert = UIAlertController(title: "Sign up failed.",
                                                  message: "Either your email is invalid or your username is taken.",
                                                  preferredStyle: .alert)
                    let tryAgain = UIAlertAction(title: "Try Again",
                                                 style: .cancel,
                                                 handler: nil)
                    alert.addAction(tryAgain)
                    self.present(alert, animated: true, completion: nil)
                    
                    
                    print(error?.localizedDescription as Any)
                }
            })
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Create rounded buttons
        self.continueButton.layer.cornerRadius = 25.0
        self.continueButton.clipsToBounds = true
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
