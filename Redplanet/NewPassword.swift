//
//  NewPassword.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/22/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import AudioToolbox
import CoreData
import UIKit

import Parse
import ParseUI
import Bolts

/*
 UIViewController class that asks the current user to enter their new password.
 */

class NewPassword: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var newPasswordAgain: UITextField!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop View Controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveAction(_ sender: Any) {
        // Check if passwords match
        if self.newPassword.text!.isEmpty || self.newPasswordAgain.text!.isEmpty {
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Password",
                                                          message: "Please enter a value for your new password.")
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

        } else if self.newPassword.text! != self.newPasswordAgain.text! {
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nIncorrect Passwords",
                                                          message: "Your new passwords don't match.")
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
            
        } else if self.newPassword.text! == self.newPasswordAgain.text! {
            // SAVE
            PFUser.current()!.password = self.newPasswordAgain.text!
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // MARK: - AZDialogViewController
                    let dialogController = AZDialogViewController(title: "Password Reset Complete",
                                                                  message: "You now have a new password.")
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
                        // Pop 2 view controllers
                        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);
                    }))
                    dialogController.show(in: self)

                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Design button
        self.saveButton.layer.cornerRadius = 25.00
        self.saveButton.clipsToBounds = true
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
