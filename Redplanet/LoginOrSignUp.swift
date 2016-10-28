//
//  LoginOrSignUp.swift
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


class LoginOrSignUp: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var rpUsername: UITextField!
    @IBOutlet weak var rpPassword: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // Function to login
    func loginToRP() {
        print("Logging in...")
        
        // Superseed to lowercaseString
        let theUsername = rpUsername.text!.lowercased()
        let thePassword = rpPassword.text!
        
        // Login
        PFUser.logInWithUsername(inBackground: theUsername,
                                 password: thePassword) {
                                    (user: PFUser?, error: Error?) in
                                    if user != nil {
                                        print("Logging user in...")
                                        
                                        // Resign keyboard
                                        self.rpPassword.resignFirstResponder()
                                        
                                        
                                        // Get phone disk to remember if
                                        // User has logged in or not
                                        UserDefaults.standard.set(PFUser.current()!.username!, forKey: "username")
                                        UserDefaults.standard.synchronize()
                                        
                                        // Call login function from AppDelegeate
                                        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                                        appDelegate.login()
                                        
                                        
                                        // Save installation data
                                        let installation = PFInstallation.current()
                                        installation!["user"] = PFUser.current()
                                        installation!["username"] = PFUser.current()!.username!
                                        installation!.saveInBackground(block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Successfully saved installation data: \(installation)")
                                            } else {
                                                print(error?.localizedDescription)
                                            }
                                        })
                                        
                                        
                                        // Save apnsId
                                        if playerId.isEmpty {
                                            PFUser.current()!["apnsId"] = ""
                                        } else {
                                            PFUser.current()!["apnsId"] = playerId.last!
                                            PFUser.current()!.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully saved apnsId: \(PFUser.current()!)")
                                                } else {
                                                    print(error?.localizedDescription)
                                                }
                                            })
                                        }
                                        
                                        
                                    } else {
                                        print(error?.localizedDescription)
                                        
                                        print("User login failed")
                                        
                                        
                                        
                                        
                                        // Present alert
                                        let alert = UIAlertController(title: "Login Failed",
                                                                      message: "The username and password do not match!",
                                                                      preferredStyle: .alert)
                                        
                                        
                                        let cancelAction = UIAlertAction(title: "Try Again",
                                                                         style: .cancel,
                                                                         handler: {(alertAction: UIAlertAction!) in
                                                                            
                                                                            // Clear textfields
                                                                            self.rpUsername.text! = ""
                                                                            self.rpPassword.text! = ""
                                                                            
                                                                            // Set first responder
                                                                            self.rpUsername.becomeFirstResponder()
                                                                            
                                        })
                                        
                                        let forgot = UIAlertAction(title: "Forgot Password",
                                                                   style: .default,
                                                                   handler: {(alertAction: UIAlertAction!) in
                                                                    
                                                                    let alert = UIAlertController(title: "What's Your Email?",
                                                                                                  message: "Please enter your email to reset your password.",
                                                                                                  preferredStyle: .alert)
                                                                    
                                                                    
                                                                    let email = UIAlertAction(title: "Done",
                                                                                              style: .default) {
                                                                                                [unowned self, alert] (action: UIAlertAction!) in
                                                                                                
                                                                                                let email = alert.textFields![0]
                                                                                                
                                                                                                // Send email to reset password
                                                                                                PFUser.requestPasswordResetForEmail(inBackground: email.text!, block: { (success: Bool, error: Error?) in
                                                                                                    if success {
                                                                                                        
                                                                                                        let alert = UIAlertController(title: "Check Your Email!",
                                                                                                                                      message: "You can reset your password via our link.",
                                                                                                                                      preferredStyle: .alert)
                                                                                                        
                                                                                                let ok = UIAlertAction(title: "ok",
                                                                                                                               style: .default,
                                                                                                                               handler: {(alertAction: UIAlertAction!) in
                                                                                                                                // Pop back view controller
                                                                                                                                self.dismiss(animated: true, completion: nil)
                                                                                                        })
                                                                                                        
                                                                                                        alert.addAction(ok)
                                                                                                        self.present(alert, animated: true, completion: nil)
                                                                                                    } else {
                                                                                                        
                                                                                                        // Invalid email
                                                                                                        let alert = UIAlertController(title: "Invalid Email",
                                                                                                                                      message: "Your email doesn't exist in our database.",
                                                                                                                                      preferredStyle: .alert)
                                                                                                        
                                                                                                        let ok = UIAlertAction(title: "ok",
                                                                                                                               style: .default,
                                                                                                                               handler: {(alertAction: UIAlertAction!) in
                                                                                                                                self.dismiss(animated: true, completion: nil)
                                                                                                        })
                                                                                                        
                                                                                                        alert.addAction(ok)
                                                                                                        self.present(alert, animated: true, completion: nil)
                                                                                                        
                                                                                                    }
                                                                                                })
                                                                                                
                                                                                                
                                                                                                
                                                                    }
                                                                    
                                                                    let cancel = UIAlertAction(title: "Cancel",
                                                                                               style: .destructive,
                                                                                               handler: nil)
                                                                    
                                                                    
                                                                    // Add textfield
                                                                    alert.addTextField(configurationHandler: nil)
                                                                    alert.addAction(email)
                                                                    alert.addAction(cancel)
                                                                    self.present(alert, animated: true, completion: nil)
                                                                    
                                                                    
                                        })
                                        
                                        alert.addAction(forgot)
                                        alert.addAction(cancelAction)
                                        
                                        self.present(alert, animated: false, completion: nil)
                                        
                                    }
                                    
        }
        
    }
    
    // UITextField Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Move to next UITextField
        if rpUsername.isFirstResponder {
            // Move to Password
            rpPassword.becomeFirstResponder()
        } else {
            // Login to RP
            loginToRP()
        }
        
        return true
    }
    
    
    // Dismiss keyboard
    func dismissKeyboard() {
        // Resign first responders
        self.rpUsername.resignFirstResponder()
        self.rpPassword.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Text == Hello, welcome to Redplanet, the first social media platform that can filter your newsfeed, the way you want it to.
        // ^?
        
        // Dismiss keyboard
        let tap0 = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap0.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(tap0)
        

        // Design loginButton
        self.loginButton.layer.cornerRadius = 25.00
        
        // Set username to be first responder
        self.rpUsername.becomeFirstResponder()
        
        // Add login function to loginButton
        let tap = UITapGestureRecognizer(target: self, action: #selector(loginToRP))
        tap.numberOfTapsRequired = 1
        self.loginButton.isUserInteractionEnabled = true
        self.loginButton.addGestureRecognizer(tap)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
