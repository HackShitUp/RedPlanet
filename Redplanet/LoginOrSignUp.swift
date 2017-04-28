//
//  LoginOrSignUp.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SafariServices


class LoginOrSignUp: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var privacyPolicy: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var welcome: UILabel!
    
    @IBAction func signUp(_ sender: Any) {
        // Push VC
        let signUpVC = self.storyboard?.instantiateViewController(withIdentifier: "signUpVC") as! SignUp
        self.navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    @IBAction func logIn(_ sender: Any) {
        // Push VC
        let logInVC = self.storyboard?.instantiateViewController(withIdentifier: "logInVC") as! LogIn
        self.navigationController?.pushViewController(logInVC, animated: true)
    }
    
    func showPolicy() {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/privacy-policy/")!, entersReaderIfAvailable: false)
        self.present(webVC, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Adjust cornerRadius
        self.view.layer.cornerRadius = 8
        self.view.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set welcome text
        self.welcome.text = "Welcome to\nRedplanet"
        
        // Design logo
        self.logo.layer.cornerRadius = 8.00
        self.logo.clipsToBounds = true

        // Design logInButton
        self.logInButton.layer.cornerRadius = 25.00
        self.logInButton.clipsToBounds = true
        
        // Design signUpButton
        self.signUpButton.layer.cornerRadius = 25.00
        self.signUpButton.setTitleColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
        self.signUpButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        self.signUpButton.layer.borderWidth = 3.50
        self.signUpButton.clipsToBounds = true
        
        // Add method to show privacy policy and terms of services
        let policyTap = UITapGestureRecognizer(target: self, action: #selector(showPolicy))
        policyTap.numberOfTapsRequired = 1
        self.privacyPolicy.isUserInteractionEnabled = true
        self.privacyPolicy.addGestureRecognizer(policyTap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
