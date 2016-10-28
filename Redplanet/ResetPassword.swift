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
    
    @IBOutlet weak var userEmail: UITextField!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    @IBAction func resetPassword(_ sender: AnyObject) {
        // Re set userEmail
        if userEmail.text!.isEmpty {
            let alert = UIAlertController(title: "Password Reset Failed",
                                          message: "Please enter your email.",
                                          preferredStyle: .alert)
            let ok = UIAlertAction(title: "ok",
                                   style: .cancel,
                                   handler: nil)
            
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            // Request new password via email
            PFUser.requestPasswordResetForEmail(inBackground: userEmail.text!, block: {
                (success: Bool, error: Error?) in
                if success {
                    let alert = UIAlertController(title: "Received Reset Password Request",
                                                  message: "Please check your email! You can change your password via the link we sent.",
                                                  preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: {(alertAction: UIAlertAction!) in
                                            // Pop back view controller
                                            self.navigationController!.popViewController(animated: true)
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    print(error?.localizedDescription)
                    let alert = UIAlertController(title: "Invalid Email",
                                                  message: "This email doesn't exist in our database.",
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make email first responder
        userEmail.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
