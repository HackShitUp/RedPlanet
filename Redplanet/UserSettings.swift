//
//  UserSettings.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

// Global variable to dictate what to send to notifications....
// State of user's anonymity
var anonymity = true

class UserSettings: UITableViewController, UINavigationControllerDelegate, EPSignatureDelegate {

    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Settings"
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Stylize title
        configureView()
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            
            if indexPath.row == 0 {
                // Edit Profile
                let editProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "editProfileVC") as! ProfileEdit
                self.navigationController?.pushViewController(editProfileVC, animated: true)
            }
            
            if indexPath.row == 1 {
                
            }
            
            if indexPath.row == 2 {
                
            }
            
            if indexPath.row == 3 {
                // Reset Password
                let passwordVC = self.storyboard?.instantiateViewController(withIdentifier: "passwordVC") as! ResetPassword
                self.navigationController?.pushViewController(passwordVC, animated: true)
            }
            
            if indexPath.row == 4 {
                
            }
            
            if indexPath.row == 5 {
                // LOGOUT
                
                // Remove logged in user from app memory
                PFUser.logOutInBackground(block: {
                    (error: Error?) in
                    if error == nil {
                        // Remove logged in user from App Memory
                        UserDefaults.standard.removeObject(forKey: "username")
                        UserDefaults.standard.synchronize()

                        DispatchQueue.main.async(execute: { 
                            let logoutToStart: LoginOrSignUp = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! LoginOrSignUp
                            self.present(logoutToStart, animated: true, completion: nil)
                        })
                        
                        // Clear array
                        username.removeAll()
                    }

                })
            }
            
        } else {
            
            
            if indexPath.row == 0 {
                let confettiView = SAConfettiView(frame: self.view.bounds)
                self.view.addSubview(confettiView)
                confettiView.type = .Confetti
                confettiView.colors = [UIColor.red, UIColor.green, UIColor.blue]
                confettiView.intensity = 0.75
                confettiView.startConfetti()

            }
            
            if indexPath.row == 1 {
                // Show Activity
                let textToShare = "🤗 Let's be friends on Redplanet, my username is \(PFUser.current()!.username!)"
                if let myWebsite = NSURL(string: "https://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8") {
                    let objectsToShare = [textToShare, myWebsite] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
            
            if indexPath.row == 2 {
                // Push to AboutUs
                let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "aboutVC") as! AboutUs
                self.navigationController!.pushViewController(aboutVC, animated: true)
            }
            
            if indexPath.row == 3 {
                let signatureVC = EPSignatureViewController(signatureDelegate: self, showsDate: true, showsSaveSignatureOption: true)
                signatureVC.subtitleText = "I agree to the Terms & Conditions"
                signatureVC.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                signatureVC.showsDate = true
                signatureVC.tintColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
                self.present(signatureVC, animated: true, completion: nil)
            }
            
            if indexPath.row == 4 {
                
            }
            
            if indexPath.row == 5 {
                
            }
            
        }
    }
    
    
    // MARK: - EPSignatureDelegates
    func epSignature(_: EPSignatureViewController, didCancel error: NSError) {
        print("Canceled")
        // Dismiss VC
        self.dismiss(animated: true, completion: nil)
    }
    
    func epSignature(_: EPSignatureViewController, didSign signatureImage: UIImage, boundingRect: CGRect) {
        // TODO:: Save Signature image
        // Dismiss VC
        self.dismiss(animated: true, completion: nil)
    }
    

}
