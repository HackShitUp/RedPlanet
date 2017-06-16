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

/*
 Class that allows users to Log In.
 */

class LogIn: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    

    @IBOutlet weak var rpUsername: UITextField!
    @IBOutlet weak var rpPassword: UITextField!
    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var backButton: UIButton!
    @IBAction func exit(_ sender: Any) {
        // Dismiss keyboards
        dismissKeyboard()
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        let alert = UIAlertController(title: "What's Your Email?",
                                      message: "Please enter your email to reset your password.",
                                      preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Done",
                                  style: .cancel) {
                                    [unowned self, alert] (action: UIAlertAction!) in
                                    
                                    let email = alert.textFields![0]
                                    
                                    // Send email to reset password
                                    PFUser.requestPasswordResetForEmail(inBackground: email.text!.lowercased(), block: { (success: Bool, error: Error?) in
                                        if success {

                                            // MARK: - AZDialogViewController
                                            let dialogController = AZDialogViewController(title: "Check Your Email!",
                                                                                          message: "You can reset your password via our link.")
                                            dialogController.dismissDirection = .bottom
                                            dialogController.dismissWithOutsideTouch = true
                                            dialogController.showSeparator = true
                                            
                                            // Configure style
                                            dialogController.buttonStyle = { (button,height,position) in
                                                button.setTitleColor(UIColor.white, for: .normal)
                                                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                                                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                                                button.layer.masksToBounds = true
                                            }
                                            // Add Skip and verify button
                                            dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                                                // Dismiss
                                                dialog.dismiss()
                                                
                                            }))
                                            
                                            dialogController.show(in: self)
                                        } else {

                                            // MARK: - AZDialogViewController
                                            let dialogController = AZDialogViewController(title: "Invalid Email",
                                                                                          message: "Your email doesn't exist in our database.")
                                            dialogController.dismissDirection = .bottom
                                            dialogController.dismissWithOutsideTouch = true
                                            dialogController.showSeparator = true
                                            
                                            // Configure style
                                            dialogController.buttonStyle = { (button,height,position) in
                                                button.setTitleColor(UIColor.white, for: .normal)
                                                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                                                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                                                button.layer.masksToBounds = true
                                            }
                                            // Add Skip and verify button
                                            dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                                                // Dismiss
                                                dialog.dismiss()
                                                
                                            }))
                                            
                                            dialogController.show(in: self)
                                        }
                                    })
        }
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .destructive,
                                   handler: nil)
        
        
        // Add textfield
        alert.addTextField(configurationHandler: nil)
        alert.addAction(cancel)
        alert.addAction(done)
        self.present(alert, animated: true, completion: nil)
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
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "Log In Failed",
                                                      message: "The username and password do not match.")
        dialogController.dismissDirection = .bottom
        dialogController.dismissWithOutsideTouch = true
        dialogController.showSeparator = true
        
        // Configure style
        dialogController.buttonStyle = { (button,height,position) in
            button.setTitleColor(UIColor.white, for: .normal)
            button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
            button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.layer.masksToBounds = true
        }
        // Add Skip and verify button
        dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()

        }))
        
        dialogController.show(in: self)
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
        
        // Design backButton
        self.backButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        // MARK: - RPExtensions
        self.backButton.makeCircular(forView: self.backButton, borderWidth: 1.5, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
