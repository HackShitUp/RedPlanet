//
//  ResetPassword.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/27/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class ResetPassword: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var userPassword: UITextField!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func forgotPassword(_ sender: Any) {
        
        // Show alert
        let alert = UIAlertController(title: "Password Reset",
                                      message: "Please enter your email below to reset your password.",
                                      preferredStyle: .alert)
        
        let done = UIAlertAction(title: "Done",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    // Show textfield for email reset
                                    let email = alert.textFields![0]
                                    
                                    // Request new password via email
                                    PFUser.requestPasswordResetForEmail(inBackground: email.text!, block: {
                                        (success: Bool, error: Error?) in
                                        if success {
                                            let alert = UIAlertController(title: "Reset Password Requested",
                                                                          message: "We've sent you an email to reset your password.",
                                                                          preferredStyle: .alert)
                                            
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: {(alertAction: UIAlertAction!) in
                                                                    // Pop back view controller
                                                                    self.navigationController?.popViewController(animated: true)
                                            })
                                            alert.addAction(ok)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            let alert = UIAlertController(title: "Invalid Email",
                                                                          message: "This email doesn't exist in our database.",
                                                                          preferredStyle: .alert)
                                            let ok = UIAlertAction(title: "ok",
                                                                   style: .default,
                                                                   handler: {(alertAction: UIAlertAction!) in
                                                                    self.dismiss(animated: true, completion: nil)
                                            })
                                            alert.addAction(ok)
                                            alert.view.tintColor = UIColor.black
                                            self.present(alert, animated: true, completion: nil)
                                        }
                                        
                                    })

        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                  style: .cancel,
                                  handler: nil)
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(done)
        alert.addAction(cancel)
        alert.view.tintColor = UIColor.black
        self.present(alert, animated: true, completion: nil)

    }
    
    @IBOutlet weak var nextButton: UIButton!
    @IBAction func nextAction(_ sender: Any) {
        print("ASDAPSD:\(self.userPassword.text!)")
        
        // Re set userEmail
        if userPassword.text!.isEmpty {
            let alert = UIAlertController(title: "Invalid Password",
                                          message: "Please enter your password to continue.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .cancel,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            
        } else {
            // TODO::
            // Validate correct credentials
            // Before user can change their passwords...
            
            // Push VC
            let newPasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "newPasswordVC") as! NewPassword
            self.navigationController?.pushViewController(newPasswordVC, animated: true)
        }
           

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make email first responder
        userPassword.becomeFirstResponder()
        
        // Design button
        self.nextButton.layer.cornerRadius = 25.00
        self.nextButton.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
