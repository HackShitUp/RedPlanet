//
//  EmailPassword.swift
//  Redplanet
//
//  Created by Joshua Choi on 6/15/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class EmailPassword: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: - Class variable; used to store new user's attributes as they sign up and enter their credentials
    var newUserObject: PFUser?
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBOutlet weak var switchButton: UIButton!
    @IBAction func switchAction(_ sender: Any) {
        // Change UIKeyboard Type to default
        if newUserPassword.isFirstResponder && newUserPassword.keyboardType == .numberPad {
            self.newUserPassword.keyboardType = .default
            self.switchButton.setTitle("Alphanumeric Password", for: .normal)
        } else if newUserPassword.isFirstResponder && newUserPassword.keyboardType == .default {
        // Change UIKeyboard Type to numberPad
            self.newUserPassword.keyboardType = .numberPad
            self.switchButton.setTitle("Numeric Password", for: .normal)
        }
        
        // Resign FirstResponder
        self.newUserPassword.resignFirstResponder()
        self.newUserPassword.becomeFirstResponder()
    }
    
    
    @IBOutlet weak var newUserEmail: UITextField!
    @IBOutlet weak var newUserPassword: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // FUNCTION - SIGN UP
    func signUp() {

        // (1) Check if UITextFields are empty
        if newUserPassword.text!.isEmpty || newUserEmail.text!.isEmpty {
            // Show Alert
            self.showAlert(title: "Invalid Credentials", message: "Please enter a value for your email or password.")
            
        } else if !newUserEmail.text!.lowercased().replacingOccurrences(of: " ", with: "").contains("@") {
        // (2) Check if email is valid
            // Show Alert
            self.showAlert(title: "Invalid Email", message: "Please enter a valid email.")
        
        } else if newUserPassword.text!.replacingOccurrences(of: " ", with: "").characters.count < 4 {
        // (3) Check for strength of password
            // Show Alert
            self.showAlert(title: "Weak Password", message: "Please make sure your password is at least 4 characters long.")
            
        } else {
        // (4) Nothing Wrong; Check if email exists
            let user = PFUser.query()!
            user.whereKey("email", equalTo: newUserEmail.text!.lowercased().replacingOccurrences(of: " ", with: ""))
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    // NEW USER
                    if objects!.isEmpty {
                        // Update PFUser object
                        self.newUserObject!["email"] = self.newUserEmail.text!.lowercased().replacingOccurrences(of: " ", with: "")
                        self.newUserObject!["password"] = self.newUserPassword.text!.replacingOccurrences(of: " ", with: "")
                        
                        // Push to CreateProfile VC and pass newUserObject; PFUser
                        let createProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "createProfileVC") as! CreateProfile
                        createProfileVC.newUserObject = self.newUserObject!
                        self.navigationController?.pushViewController(createProfileVC, animated: true)

                    } else {
                    // EMAIL EXISTS
                        // Show Alert
                        self.showAlert(title: "Duplicate Email", message: "This email already exists in our database...")
                    }
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        }
    }
    
    // FUNCTION - Show Alert
    func showAlert(title: String, message: String) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "💩\n\(title)",
                                                      message: "\(message)")
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
        
        // Add settings button
        dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
        }))
        
        dialogController.show(in: self)
    }
    
    // MARK: - UIView Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set UITextField delegates
        self.newUserEmail.delegate = self
        self.newUserPassword.delegate = self

        // Make newUserEmail First Responder
        self.newUserEmail.becomeFirstResponder()
        
        // Configure continueButton with rounded corners
        self.continueButton.layer.cornerRadius = 25
        self.continueButton.clipsToBounds = true
        
        // Design backButton
        self.backButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        // MARK: - RPExtensions
        self.backButton.makeCircular(forView: self.backButton, borderWidth: 1.5, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
        
        // Add sign up method
        let signUpTap = UITapGestureRecognizer(target: self, action: #selector(signUp))
        signUpTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(signUpTap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - UITextField Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // EMAIL; disable switchButton
        if newUserEmail.isFirstResponder {
            self.switchButton.isEnabled = false
        }
        
        // PASSWORD; enable switchButton
        if newUserPassword.isFirstResponder {
            self.switchButton.isEnabled = true
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // EMAIL
        if newUserEmail.isFirstResponder {
            self.switchButton.isEnabled = true
            self.newUserPassword.becomeFirstResponder()
        }
        
        return true
    }

}
