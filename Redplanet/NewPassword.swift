//
//  NewPassword.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/22/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts



class NewPassword: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var newPasswordAgain: UITextField!
    
    @IBAction func backButton(_ sender: Any) {
        // Pop View Controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var saveButton: UIButton!
    @IBAction func saveAction(_ sender: Any) {
        // Check if passwords match
        if self.newPassword.text!.isEmpty || self.newPasswordAgain.text!.isEmpty {
            // Show Alert
            let alert = UIAlertController(title: "Invalid Password",
                                          message: "Please enter a value for your new password.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .cancel,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            
        } else if self.newPassword.text! != self.newPasswordAgain.text! {
            // Show Alert
            let alert = UIAlertController(title: "Incorrect Passwords",
                                          message: "Your new passwords don't match.",
                                          preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "ok",
                                   style: .cancel,
                                   handler: nil)
            
            alert.addAction(ok)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            
        } else if self.newPassword.text! == self.newPasswordAgain.text! {
            // SAVE
            PFUser.current()!.password = self.newPasswordAgain.text!
            PFUser.current()!.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    print("Successfully saved password: \(PFUser.current()!.password!)")
                    
                    // Show Alert
                    let alert = UIAlertController(title: "Password Reset Complete",
                                                  message: "You now have a new password.",
                                                  preferredStyle: .alert)
                    
                    let ok = UIAlertAction(title: "ok",
                                           style: .cancel,
                                           handler: {(alertAction: UIAlertAction!) in
                                            // Pop 2 view controllers
                                            let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController];
                                            self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true);

                    })
                    
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.present(alert, animated: true, completion: nil)
                    
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
