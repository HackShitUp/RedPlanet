//
//  CurrentUserNumber.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/24/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD

class CurrentUserNumber: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func dismiss(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func saveAction(_ sender: Any) {
        // Save phone number
        if phoneNumber.text!.isEmpty || self.phoneNumber.text! == "" || self.phoneNumber.text!.characters.count != 10 {
            // Dismiss
            let alert = UIAlertController(title: "Invalid Number",
                                          message: "Please enter your phone number to find your friends.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            
        } else {
            // Show Progress
            SVProgressHUD.show()
            
            
            // Remove non-integers
            var number = self.phoneNumber.text!
            number = number.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            number = number.trimmingCharacters(in: CharacterSet.symbols)
            
            // Save to <_User>
            PFUser.current()!["phoneNumber"] = number
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    // Post Notification
                    NotificationCenter.default.post(name: contactsNotification, object: nil)
                    
                    // Pop VC
                    self.navigationController?.popViewController(animated: false)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    // Pop VC
                    self.navigationController?.popViewController(animated: false)
                }
            })
        }
    }


    // MARK: - UITextFieldDelegate Method
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.phoneNumber.text! == "_ _ _ _ _ _ _ _ _ _" {
            self.phoneNumber.text! = ""
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show user's number if it exists
        if PFUser.current()!["phoneNumber"] != nil {
            self.phoneNumber.text! = PFUser.current()!["phoneNumber"] as! String
        } else {
            self.phoneNumber.text! = "_ _ _ _ _ _ _ _ _ _"
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
            self.phoneNumber.text! = "_ _ _ _ _ _ _ _ _ _"
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
            self.phoneNumber.text! = "_ _ _ _ _ _ _ _ _ _"
        }
     
        // Set first responder
        self.phoneNumber.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
