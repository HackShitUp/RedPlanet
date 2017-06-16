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
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
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
            
        } else if self.lastName.text!.isEmpty {
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Last Name", message: "Please enter your last name.")
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
            
        } else {
            // Create new PFObject
            let userObject = PFUser()
            userObject["realNameOfUser"] = "\(self.firstName.text!) \(self.lastName.text!)"
            
            // Push to bdayVC and pass PFObject to class
            let bdayVC = self.storyboard?.instantiateViewController(withIdentifier: "birthdayVC") as! Birthday
            bdayVC.newUserObject = userObject
            self.navigationController?.pushViewController(bdayVC, animated: true)
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
        
        // Design backButton
        self.backButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        // MARK: - RPExtensions
        self.backButton.makeCircular(forView: self.backButton, borderWidth: 1.5, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
