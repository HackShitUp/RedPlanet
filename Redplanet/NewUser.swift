//
//  NewUser.swift
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

class NewUser: UIViewController, UIImagePickerControllerDelegate, UITextViewDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUserBio: UITextView!
    @IBOutlet weak var continueButton: UIButton!
    
    
    // Function to onboard the user
    func saveUser(sender: Any) {
        // Convert image to PFFile
        let userPhoto = UIImageJPEGRepresentation(self.rpUserProPic.image!, 0.5)
        let parseFile = PFFile(data: userPhoto!)
        
        // Save user's data
        PFUser.current()!["userProfilePicture"] = parseFile
        PFUser.current()!["userBiography"] = self.rpUserBio.text!
        if self.rpUserProPic.image == UIImage(named: "Gender Neutral User-100") {
            // false
            PFUser.current()!["proPicExists"] = false
        } else {
            // true
            PFUser.current()!["proPicExists"] = true
        }
        PFUser.current()!.saveInBackground(block: {
            (success: Bool, error: Error?) in
            if success {
                print("Saved user's data!: \(PFUser.current()!)")
                
                // Show alert, and load onboarding
                let alert = UIAlertController(title: "😁\nAlmost Finished",
                                              message: "Please check your email when you can. We've sent you something!",
                                              preferredStyle: .alert)
                let ok = UIAlertAction(title: "next",
                                       style: .default,
                                       handler: {(alertAction: UIAlertAction!) in
                                        
                                        // Load Onboarding tutorial
                                        // Perform segueue
                                        let firstPage = OnboardingContentViewController(title: "Hello \(PFUser.current()!.value(forKey: "realNameOfUser") as! String),", body: "Welcome to Redplanet, a new social media app that filters your news feeds.", image: nil, buttonText: nil) { () -> Void in
                                            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
                                        }
                                        
                                        let secondPage = OnboardingContentViewController(title: "How?", body: "By dividng your news feeds in two: One for your friends, and one for the things you're following.", image: nil, buttonText: nil) { () -> Void in
                                            // do something here when users press the button, like ask for location services permissions, register for push notifications, connect to social media, or finish the onboarding process
                                        }
                                        
                                        let thirdPage = OnboardingContentViewController(title: "Friends OR Following", body: "You can't be friends and follow someone at the same time on Redplanet.", image: nil, buttonText: nil) { () -> Void in
                                        }
                                        
                                        
                                        //
                                        let fourthPage = OnboardingContentViewController(title: "Key Differences", body: "Friends are mutual relationships, while following is not.\nWe built many cool features that clarify these differences.", image: nil, buttonText: nil) { () -> Void in
                                            
                                        }
                                        
                                        
                                        let lastPage = OnboardingContentViewController(title: nil, body: "Add the people in your life as friends.\nFollow the things you love.", image: nil, buttonText: "continue") { () -> Void in
                                            
                                            // Load Things to Follow interface
                                            let onBoardVC = self.storyboard?.instantiateViewController(withIdentifier: "onBoardVC") as! OnboardFollow
                                            self.navigationController?.pushViewController(onBoardVC, animated: true)
                                        }
                                        
                                        // Set bottom padding for button
                                        lastPage.bottomPadding = 50
                                        
                                        let onboardingVC = OnboardingViewController(backgroundImage: UIImage(named: "WeWelcome"), contents: [firstPage, secondPage, thirdPage, fourthPage, lastPage])
                                        onboardingVC?.shouldFadeTransitions = true
                                        
                                        self.navigationController!.pushViewController(onboardingVC!, animated: true)
                })
                
                
                alert.addAction(ok)
                alert.view.tintColor = UIColor.black
                self.present(alert, animated: true, completion: nil)

            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    

    // Function to resign first responder
    func dismissKeyboard(sender: Any) {
        self.rpUserBio.resignFirstResponder()
    }
    
    // Function to add a profile photo
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
        
        // Edit changes
        PFUser.current()!["proPicExists"] = true
        PFUser.current()!.saveEventually()

        
        // Set image
        self.rpUserProPic.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Save bool
        PFUser.current()!["proPicExists"] = false
        PFUser.current()!.saveEventually()
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    // MARK: - UITextViewDelegate method
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if self.rpUserBio.text! == "Introduce yourself!" {
            self.rpUserBio.text! = ""
        }
        return true
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set first responder
        self.rpUserBio.becomeFirstResponder()
        
        // Design button's corner radius
        self.continueButton.layer.cornerRadius = 25.00
        
        // Design pro pic
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        self.rpUserProPic.layer.borderWidth = 0.5
        self.rpUserProPic.clipsToBounds = true
        
        // Function to dismiss keyboard
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(dismissTap)
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



}
