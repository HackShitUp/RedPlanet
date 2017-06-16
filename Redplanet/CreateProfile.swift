//
//  CreateProfile.swift
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

import Onboard
import OneSignal

/*
 Class that asks the user to create their bio and add their profile photo.
 Both are optional.
 */

class CreateProfile: UIViewController, UIImagePickerControllerDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    // MARK: - Class variable; used to store new user's attributes as they sign up and enter their credentials
    var newUserObject: PFUser?
    
    @IBOutlet weak var newUsername: UITextField!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUserBio: UITextView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Function to onboard the user
    func saveUser(sender: Any) {

        // Check if user's bio exists
        if self.rpUserBio.textColor == UIColor.darkGray {
            self.rpUserBio.text = ""
        }
        
        // (1) Check if user's username exists
        if self.newUsername.text!.isEmpty {
            // Show Alert
            self.showAlert(title: "Invalid Username", message: "Please enter a valid value for your username.")
            
        } else if self.newUsername.text!.characters.count < 6 {
        // (2) Check if username is AT LEAST 8 characters
            // Show Alert
            self.showAlert(title: "Invalid Username", message: "Your username must be at least 6 characters long.")
            
        } else {
        // (2) Passed, create new user
            // Create new PFObject; PFUser, and pass attributes from class variable, "newUserObject"
            /*
             • realNameOfUser
             • birthday
             • email
             • password
             • userBiography
             • userProfilePicture
             • proPicExists
             • username
             */
            
            let newUser = PFUser()
            newUser["realNameOfUser"] = self.newUserObject!.value(forKey: "realNameOfUser") as! String
            newUser["birthday"] = self.newUserObject!.value(forKey: "birthday") as! String
            newUser["email"] = self.newUserObject!.value(forKey: "email") as! String
            newUser["password"] = self.newUserObject!.value(forKey: "password") as! String
            newUser["userProfilePicture"] = PFFile(data: UIImageJPEGRepresentation(self.rpUserProPic.image!, 0.5)!)
            newUser["proPicExists"] = self.newUserObject!.value(forKey: "proPicExists") as! Bool
            newUser["userBiography"] = self.rpUserBio.text!
            newUser["username"] = self.newUsername.text!.lowercased().replacingOccurrences(of: " ", with: "")
            newUser["private"] = false
            newUser.signUpInBackground(block: { (success: Bool, error: Error?) in
                if success {
                    print("Successfully signed up user...")
                    
                    // Create PFInstallation
                    let installation = PFInstallation.current()
                    installation!["user"] = PFUser.current()
                    installation!["username"] = PFUser.current()!.username!
                    installation!.saveEventually()

                    // MARK: - AZDialogViewController
                    let dialogController = AZDialogViewController(title: "😅\nAlmost Finished",
                                                                  message: "We're almost done. But first, a tutorial!")
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
                    dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                        // Dismiss
                        dialog.dismiss()
                        // Resign keyboard
                        self.rpUserBio.resignFirstResponder()
                        
                        // Load Onboarding tutorial
                        // Perform segueue
                        let firstPage = OnboardingContentViewController(title: "Hello, \(PFUser.current()!.value(forKey: "realNameOfUser") as! String)", body: "Welcome to Redplanet, a place to share stories that are meant to be spread.", image: nil, buttonText: nil) { () -> Void in
                        }
                        let secondPage = OnboardingContentViewController(title: "Ephemeral", body: "By default, your stories disappear in 24 hours. You can save them to your profile later.", image: nil, buttonText: nil) { () -> Void in
                        }
                        let lastPage = OnboardingContentViewController(title: "Stories", body: "There are 2 types of stories: One by your friends, and one created by the people you're following.", image: nil, buttonText: "Continue") { () -> Void in
                            // Load Things to Follow interface
                            let onBoardVC = self.storyboard?.instantiateViewController(withIdentifier: "onboardingVC") as! Onboarding
                            self.navigationController?.pushViewController(onBoardVC, animated: true)
                        }
                        
                        // Set fonts and padding
                        firstPage.titleLabel.font = UIFont(name: "AvenirNext-Demibold", size: 30)
                        firstPage.bodyLabel.font = UIFont(name: "AvenirNext-Medium", size: 30)
                        firstPage.topPadding = 0
                        firstPage.underIconPadding = 0
                        secondPage.titleLabel.font = UIFont(name: "AvenirNext-Demibold", size: 30)
                        secondPage.bodyLabel.font = UIFont(name: "AvenirNext-Medium", size: 30)
                        secondPage.topPadding = 0
                        secondPage.underIconPadding = 0
                        lastPage.titleLabel.font = UIFont(name: "AvenirNext-Demibold", size: 30)
                        lastPage.bodyLabel.font = UIFont(name: "AvenirNext-Medium", size: 30)
                        lastPage.topPadding = 0
                        lastPage.underIconPadding = 0
                        // Continue button
                        lastPage.actionButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 25)
                        lastPage.bottomPadding = 50
                        // Show Onboarding
                        let onboardingVC = OnboardingViewController(backgroundImage: UIImage(), contents: [firstPage, secondPage, lastPage])
                        onboardingVC?.view.frame = self.view.bounds
                        onboardingVC?.view.clipsToBounds = true
                        onboardingVC?.shouldFadeTransitions = true
                        self.navigationController?.pushViewController(onboardingVC!, animated: true)
                    }))
                    
                    dialogController.show(in: self)

                    
                } else {
                    print(error?.localizedDescription as Any)
                    // MARK: - RPHelpers
                    let rpHelpers = RPHelpers()
                    rpHelpers.showError(withTitle: "Network Error")
                }
            })
        }
    }
    
    
    // FUNCTION - Show Alert
    func showAlert(title: String, message: String) {
        
        // MARK: - AZDialogViewController
        let dialogController = AZDialogViewController(title: "💩\n\(title)",
                                                      message: "\(message)")
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
        dialogController.addAction(AZDialogAction(title: "Ok", handler: { (dialog) -> (Void) in
            // Dismiss
            dialog.dismiss()
            
        }))
        dialogController.show(in: self)
    }
    
    
    // FUNCTION - Generate Random String for username
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    // FUNCTION - Add a profile photo
    func addProPic(sender: Any) {
        // Initialize UIImagePickerController
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = true
        image.navigationBar.tintColor = UIColor.black
        image.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        self.present(image, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerController Delegate method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Set image
        self.rpUserProPic.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // Set newUserObject's proPicExists boolean
        self.newUserObject!["proPicExists"] = true
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Set newUserObject's proPicExists boolean
        self.newUserObject!["proPicExists"] = false
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextViewDelegate method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.rpUserBio.textColor == UIColor.darkGray {
            self.rpUserBio.text! = ""
            self.rpUserBio.textColor = UIColor.black
        }
    }
    
    
    // MARK: - UIView Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize user's proPicExists boolean to false
        self.newUserObject!["proPicExists"] = false
        
        // Set username
        let firstName = (self.newUserObject!.value(forKey: "realNameOfUser") as! String).components(separatedBy: " ").first!
        let generatedName = "_\(randomString(length: 4))"
        
        // Set up generated username
        self.newUsername.text = "\(firstName.appending(generatedName).lowercased())"

        // Configure UITextView
        self.rpUserBio.text = "Create your bio..."
        self.rpUserBio.textColor = UIColor.darkGray
        
        // Design button's corner radius
        self.continueButton.layer.cornerRadius = 25.00
        
        // MARK: - RPHelpers extension
        self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Design backButton
        self.backButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        // MARK: - RPExtensions
        self.backButton.makeCircular(forView: self.backButton, borderWidth: 1.5, borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
        
        // Function to add profile photo
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(addProPic))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // Function to save user
        let doneTap = UITapGestureRecognizer(target: self, action: #selector(saveUser))
        doneTap.numberOfTapsRequired = 1
        self.continueButton.isUserInteractionEnabled = true
        self.continueButton.addGestureRecognizer(doneTap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Resign keyboards
        self.newUsername.resignFirstResponder()
        self.rpUserBio.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
