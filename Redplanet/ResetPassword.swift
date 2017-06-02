//
//  ResetPassword.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/27/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

import Parse
import ParseUI
import Bolts

/*
 UIViewController class that allows users to change their password by first entering their current password. If forgotten,
 then an option to reset their password via their email is presented.
 */

class ResetPassword: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var userPassword: UITextField!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
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
                                    
                                    if PFUser.current()!.email?.lowercased() == email.text!.lowercased() {
                                        // Request new password via email
                                        PFUser.requestPasswordResetForEmail(inBackground: email.text!, block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                // MARK: - AZDialogViewController
                                                let dialogController = AZDialogViewController(title: "Reset Password Requested",
                                                                                              message: "We've sent you an email to reset your password.")
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
                                                print(error?.localizedDescription as Any)
                                                // MARK: - AudioToolBox; Vibrate device
                                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                                
                                                // MARK: - AZDialogViewController
                                                let dialogController = AZDialogViewController(title: "💩\nInvalid Email",
                                                                                              message: "This email doesn't exist in our database.")
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
                                            }
                                        })
                                    } else {
                                        // MARK: - AudioToolBox; Vibrate device
                                        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                        
                                        // MARK: - AZDialogViewController
                                        let dialogController = AZDialogViewController(title: "💩\nIncorrect Email",
                                                                                      message: "This isn't the right email associated with your account!")
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
                                    }

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
        // Re set userEmail
        if userPassword.text!.isEmpty {
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Password",
                                                          message: "Please enter your password to continue.")
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
            // Login as work around to check for user's password
            PFUser.logInWithUsername(inBackground: PFUser.current()!.username!,
                                     password: self.userPassword.text!) {
                                        (user: PFUser?, error: Error?) in
                                        if user != nil {
                                            // Push VC
                                            let newPasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "newPasswordVC") as! NewPassword
                                            self.navigationController?.pushViewController(newPasswordVC, animated: true)
                                            
                                        } else {
                                            print(error?.localizedDescription as Any)
                                            
                                            // MARK: - AudioToolBox; Vibrate Device
                                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                            
                                            // MARK: - AZDialogViewController
                                            let dialogController = AZDialogViewController(title: "💩\nIncorrect Password",
                                                                                          message: "This is not the correct password associated with your account.")
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
                                        }
            }
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
