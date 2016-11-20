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


class FullName: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // Function to save name
    func saveName(sender: Any) {
        
        if self.firstName.text!.isEmpty {
            
            // Invalid first name
            let alert = UIAlertController(title: "Invalid First Name",
                                          message: "Please enter your first name.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true)
            
        } else if self.lastName.text!.isEmpty {
            
            // Invalid last name
            let alert = UIAlertController(title: "Invalid Last Name",
                                          message: "Please enter your last name.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .default,
                                   handler: nil)
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true)
            
        } else {
            // Set fullName
            let fullName = "\(self.firstName.text!) \(self.lastName.text!)"
            
            PFUser.current()!["realNameOfUser"] = fullName
            PFUser.current()!.saveInBackground {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved fullName: \(PFUser.current()!)")
                    
                    // Push VC
                    let birthdayVC = self.storyboard?.instantiateViewController(withIdentifier: "birthdayVC") as! Birthday
                    self.navigationController?.pushViewController(birthdayVC, animated: true)
                    
                } else {
                    print(error?.localizedDescription as Any)
                    
                    // There was a network error
                    let alert = UIAlertController(title: "There was an error.",
                                                  message: "There appears to be poor connection.",
                                                  preferredStyle: .alert)
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: nil)
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.present(alert, animated: true)
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
