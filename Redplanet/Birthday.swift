//
//  Birthday.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts



class Birthday: UIViewController, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var birthday: UIDatePicker!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // Function to save birthday
    func saveBday(sender: Any) {

        // Push to NewUserVC
        let userVC = self.storyboard?.instantiateViewController(withIdentifier: "newUserVC") as! NewUser
        self.navigationController?.pushViewController(userVC, animated: true)
        
        /*
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
                
                // Network error
                
                let alert = UIAlertController(title: "There was an error.",
                                              message: "There appears to be poor connection.",
                                              preferredStyle: .alert)
                let ok = UIAlertAction(title: "ok",
                                       style: .default,
                                       handler: nil)
                alert.addAction(ok)
                alert.view.tintColor = UIColor.black
            }
        }
        */
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
