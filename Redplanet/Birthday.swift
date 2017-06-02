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
    
    
    @IBOutlet weak var birthday: UIDatePicker!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBAction func skipAction(_ sender: Any) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "🎁\nSkip Birthday?",
                                                      message: "By skipping you confirm you're of eligible age to use Redplanet.")
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
        dialogController.addAction(AZDialogAction(title: "Skip and Confirm", handler: { (dialog) -> (Void) in
            // Save current bday
            // Save user's birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.birthday.date)
            
            // Save Birthday
            PFUser.current()!["birthday"] = stringDate
            PFUser.current()!.saveInBackground()
            
            // Dismiss
            dialog.dismiss()
            
            // Push to NewUserVC
            let userVC = self.storyboard?.instantiateViewController(withIdentifier: "newUserVC") as! NewUser
            self.navigationController?.pushViewController(userVC, animated: true)

        }))
        // Cancel
        dialogController.cancelButtonStyle = { (button,height) in
            button.tintColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
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
                button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                button.layer.masksToBounds = true
            }
            // Add ok buttion
            dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
                // Save current bday
                // Save user's birthday
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d yyyy"
                let stringDate = dateFormatter.string(from: self.birthday.date)
                
                // Save Birthday
                PFUser.current()!["birthday"] = stringDate
                PFUser.current()!.saveInBackground()
                
                // Dismiss
                dialog.dismiss()
            }))
        
            dialogController.show(in: self)
            
        } else {
            // Save user's birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d yyyy"
            let stringDate = dateFormatter.string(from: self.birthday.date)
            
            // Save Birthday
            PFUser.current()!["birthday"] = stringDate
            PFUser.current()!.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    // Push to NewUserVC
                    let userVC = self.storyboard?.instantiateViewController(withIdentifier: "newUserVC") as! NewUser
                    self.navigationController?.pushViewController(userVC, animated: true)
                    
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

        // Set current date
        birthday.date = Date()
        
        // Set maximum date
        birthday.maximumDate = Date()
        
        // Add method tap to button
        let nextTap = UITapGestureRecognizer(target: self, action: #selector(saveBday))
        nextTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(nextTap)
        
        // Design button's corner radius
        self.continueButton.layer.cornerRadius = 25.00
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
