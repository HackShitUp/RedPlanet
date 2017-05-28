//
//  CurrentUserNumber.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/24/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AudioToolbox
import CoreData

import Parse
import ParseUI
import Bolts

class CurrentUserNumber: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func dismiss(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        // Save phone number
        if phoneNumber.text!.isEmpty || self.phoneNumber.text! == "" || self.phoneNumber.text!.characters.count != 10 {
            // MARK: - AudioToolBox; Vibrate Device
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "💩\nInvalid Number",
                                                          message: "Please enter your phone number to find your friends.")
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
            // Track when number was saved
            Heap.track("SavedNumber", withProperties:
                ["byUserId": "\(PFUser.current()!.objectId!)",
                    "Name": "\(PFUser.current()!.value(forKey: "fullName") as! String)"
                ])
            
            // Remove non-integers
            var number = self.phoneNumber.text!
            number = number.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            number = number.trimmingCharacters(in: CharacterSet.symbols)
            
            // Save to <_User>
            PFUser.current()!["phoneNumber"] = number
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showSuccess(withTitle: "Successfully Saved Number")
                    
                    // Post Notification
                    NotificationCenter.default.post(name: contactsNotification, object: nil)
                    
                    // Pop VC
                    _ = self.navigationController?.popViewController(animated: false)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "NetworkError")
                }
            })
        }
    }



    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show user's number if it exists
        if PFUser.current()!["phoneNumber"] != nil {
            self.phoneNumber.text! = PFUser.current()!["phoneNumber"] as! String
        } else {
            self.phoneNumber.text! = self.phoneNumber.text!
        }

        // Design button
        self.saveButton.layer.cornerRadius = 22.00
        self.saveButton.clipsToBounds = true
        
        // Set delegate
        self.phoneNumber.delegate = self
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show user's number if it exists
        if PFUser.current()!["phoneNumber"] != nil {
            self.phoneNumber.text! = PFUser.current()!["phoneNumber"] as! String
        } else {
            self.phoneNumber.text! = self.phoneNumber.text!
        }
        
        // Show navigationBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show user's number if it exists
        if PFUser.current()!["phoneNumber"] != nil {
            self.phoneNumber.text! = PFUser.current()!["phoneNumber"] as! String
        } else {
            self.phoneNumber.text! = self.phoneNumber.text!
        }
     
        // Set first responder
        self.phoneNumber.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
