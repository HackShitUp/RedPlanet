//
//  Birthday.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AudioToolbox
import CoreData

import Parse
import ParseUI
import Bolts

/*
 Onboarding: 
 Class that asks users to enter their birthday. 
 This task is optional, and users can skip it. If so, their birthday will be saved as the current date.
 */

class Birthday: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Class variable; used to store new user's attributes as they sign up and enter their credentials
    var newUserObject: PFUser?
    
    
    @IBOutlet weak var birthday: UIDatePicker!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func backAction(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func skipAction(_ sender: Any) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "🎂\nSkip Birthday?",
                                                      message: "By skipping this you agree you're of eligible age to use Redplanet.")
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
        dialogController.addAction(AZDialogAction(title: "Skip and Confirm", handler: { (dialog) -> (Void) in

            // Save user's birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.birthday.date)
            
            // Add birthday attribute to new PFUser object
            self.newUserObject!["birthday"] = stringDate
            
            // Dismiss
            dialog.dismiss()
            
            // Push to EmailPassword VC
            let emailPasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "emailPasswordVC") as! EmailPassword
            emailPasswordVC.newUserObject = self.newUserObject!
            self.navigationController?.pushViewController(emailPasswordVC, animated: true)

        }))
        // Cancel
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
            button.setTitle("CANCEL", for: [])
            return true
        }
        
        dialogController.show(in: self)
    }
    
    // Function to save birthday
    func saveBday(sender: Any) {
        
        // Get age
        let now = Date()
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self.birthday.date, to: now)
        let age = ageComponents.year!
        
        if age < 12 {
            // Vibrate device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nAge Requirement", message: "You must be at least 12 years old or older to use Redplanet.")
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
            // Add ok buttion
            dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                // Dismiss
                dialog.dismiss()
            }))
        
            dialogController.show(in: self)
            
        } else {
            // Save user's birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.birthday.date)
            
            // Add birthday attribute to new PFUser object
            self.newUserObject!["birthday"] = stringDate
            
            // Push to EmailPassword VC
            let emailPasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "emailPasswordVC") as! EmailPassword
            emailPasswordVC.newUserObject = self.newUserObject!
            self.navigationController?.pushViewController(emailPasswordVC, animated: true)
        }
    }
    

    // MARK: - UIView Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set current date
        birthday.date = Date()
        
        // Set maximum date
        birthday.maximumDate = Date()
        
        // Add method tap to button
        let nextTap = UITapGestureRecognizer(target: self, action: #selector(saveBday))
        nextTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(nextTap)
        
        // Set continueButton's corner radius
        self.continueButton.layer.cornerRadius = 25.00
        
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
