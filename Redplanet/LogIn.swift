//
//  LogIn.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/12/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts



class LogIn: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    

    @IBOutlet weak var rpUsername: UITextField!
    @IBOutlet weak var rpPassword: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    @IBAction func exit(_ sender: Any) {
        // Dismiss keyboards
        dismissKeyboard()
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Function to login
    func loginToRP() {
        // Loop thorugh words to check for email vs username
        for word in self.rpUsername.text!.components(separatedBy: CharacterSet.whitespacesAndNewlines) {
            if word.contains("@") {
                // LOGIN WITH EMAIL
                loginEmail()
            } else {
                // LOGIW WITH USERNAME
                loginUsername(theUsername: word)
            }
        }
    }
    
    
    // Function to login with Username
    func loginUsername(theUsername: String?) {
        // Login
        PFUser.logInWithUsername(inBackground: theUsername!.lowercased(),
                                 password: self.rpPassword.text!) {
                                    (user: PFUser?, error: Error?) in
                                    if user != nil {
                                        // Resign keyboard
                                        self.rpPassword.resignFirstResponder()
                                        
                                        // Call login function from AppDelegeate
                                        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                                        appDelegate.login()
                                        
                                        // Save installation data
                                        let installation = PFInstallation.current()
                                        installation!["user"] = PFUser.current()
                                        installation!["username"] = PFUser.current()!.username!
                                        installation!.saveEventually()
                                        
                                    } else {
                                        print(error?.localizedDescription as Any)
                                        // Show error
                                        self.showError()
                                    }
        }
    }
    
    // Function to login with Email
    func loginEmail() {
        let user = PFUser.query()!
        user.whereKey("email", equalTo: self.rpUsername.text!.lowercased().replacingOccurrences(of: " ", with: ""))
        user.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    // Login with username
                    self.loginUsername(theUsername: (object.value(forKey: "username") as! String).lowercased())
                }
            } else {
                print(error?.localizedDescription as Any)
                // Show error
                self.showError()
            }
        }
    }
    
    
    // Function to show error
    func showError() {
        // Present alert
        let alert = UIAlertController(title: "Login Failed",
                                      message: "The username and password do not match!",
                                      preferredStyle: .alert)
        
        
        let cancelAction = UIAlertAction(title: "Try Again",
                                         style: .cancel,
                                         handler: nil)
        
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
                                                                PFUser.requestPasswordResetForEmail(inBackground: email.text!.lowercased(), block: { (success: Bool, error: Error?) in
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
        
        // Dismiss keyboard
        let tap0 = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap0.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(tap0)
        
        self.rpUsername.autocorrectionType = .no
        
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
