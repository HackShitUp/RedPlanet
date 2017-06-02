//
//  FullName.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


/*
 Onboarding: 
 Asks the user to enter their First and Last Name.
 */

class FullName: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // Function to save name
    func saveName(sender: Any) {
        
        if self.firstName.text!.isEmpty {

            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid First Name", message: "Please enter your first name.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)
            
        } else if self.lastName.text!.isEmpty {
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Last Name", message: "Please enter your last name.")
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
            
            // Add settings button
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
            
            dialogController.show(in: self)
            
        } else {
            // Set fullName
            let fullName = "\(self.firstName.text!) \(self.lastName.text!)"
            
            PFUser.current()!["realNameOfUser"] = fullName
            PFUser.current()!.saveInBackground {
                (success: Bool, error: Error?) in
                if success {                    
                    // Push VC
                    let birthdayVC = self.storyboard?.instantiateViewController(withIdentifier: "birthdayVC") as! Birthday
                    self.navigationController?.pushViewController(birthdayVC, animated: true)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // MARK: - AZDialogViewController
                    let dialogController = AZDialogViewController(title: "💩\nNetwork Error", message: "There appears to be poor connection.")
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
                    
                    // Add settings button
                    dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
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
        
        // Set first responder
        self.firstName.becomeFirstResponder()
        
        // Add tap method to save name
        let doneTap = UITapGestureRecognizer(target: self, action: #selector(saveName))
        doneTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(doneTap)
        
        // Design button's corner radius
        self.continueButton.layer.cornerRadius = 25.00

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
    // MARK: - UITextFieldDelegate method
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.firstName.isFirstResponder {
            self.lastName.becomeFirstResponder()
        } else {
            // Save name
            saveName(sender: self)
        }
        
        return true
    }
    
    
}
