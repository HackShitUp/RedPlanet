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

class UserSettings: UITableViewController, UINavigationControllerDelegate {

    @IBOutlet weak var privacy: UISwitch!
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
    
    
    
    
    
    
    // Function to set privacy
    func setPrivacy(sender: UISwitch) {
        
        print("Touched")
        
        if sender.isOn {
            // Private account
            // (1) Friends request must be confirmed
            // (2) Follow requests must be confirmed
            let alert = UIAlertController(title: "Private Account",
                                          message: "• Friend requests must be accepted. \n • Follow requests must be confirmed.",
                                          preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "ok",
                                         style: .default,
                                         handler: { (UIAlertAction) -> Void in
                                            // Save objects in parse
                                            let user = PFUser.current()
                                            user!["private"] = true
                                            user!.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully made private")
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
            })
            
            
            alert.addAction(okAction)
            alert.view.tintColor = UIColor.black
            self.present(alert, animated: true, completion: nil)
            
        } else {
            // Public account
            // (1) Friends Requests must be confirmed
            // (2) Follow requests do not have to be confirmed
            
            let alert = UIAlertController(title: "Public Account",
                                          message: "• Friend requests must be accepted. \n • Anyone can follow you and see your content.",
                                          preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ok",
                                         style: .default,
                                         handler: { (UIAlertAction) -> Void in
                                            
                                            // Save object in parse
                                            let user = PFUser.current()
                                            user!["private"] = false
                                            user!.saveInBackground(block: {
                                                (success: Bool, error: Error?) in
                                                if success {
                                                    print("Successfully made public")
                                                } else {
                                                    print(error?.localizedDescription as Any)
                                                }
                                            })
            })
            
            
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Stylize title
        configureView()
        
        // Add function method to 'privacy'
        self.privacy.addTarget(self, action: #selector(setPrivacy), for: .allEvents)
        
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
        if section == 0 {
            return 6
        } else {
            return 7
        }
    }
    

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            
            if indexPath.row == 0 {
                // Edit Profile
                let editProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "editProfileVC") as! ProfileEdit
                self.navigationController?.pushViewController(editProfileVC, animated: true)
            }
            
            if indexPath.row == 1 {
                // Relationship Requests
                let rRequestsVC = self.storyboard?.instantiateViewController(withIdentifier: "relationshipsVC") as! RelationshipRequests
                self.navigationController?.pushViewController(rRequestsVC, animated: true)
            }
            
            if indexPath.row == 2 {
                // Friends in Contacts
                // TODO::
            }
            
            if indexPath.row == 3 {
                // Reset Password
                let passwordVC = self.storyboard?.instantiateViewController(withIdentifier: "passwordVC") as! ResetPassword
                self.navigationController?.pushViewController(passwordVC, animated: true)
            }
            
            if indexPath.row == 4 {
                // Privacy
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
                // Confetti
                // TODO::
                // ????
            }
            
            if indexPath.row == 1 {
                // Icons Guideline
                
                // Push VC
                let iconsVC = self.storyboard?.instantiateViewController(withIdentifier: "iconsVC") as! RPIconsGuideline
                self.navigationController!.pushViewController(iconsVC, animated: true)
                
            }
            
            if indexPath.row == 2 {
                
                // Show Activity
                let textToShare = "🤗 Let's be friends on Redplanet, my username is \(PFUser.current()!.username!)"
                if let myWebsite = NSURL(string: "https://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8") {
                    let objectsToShare = [textToShare, myWebsite] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }
                
            }
            
            if indexPath.row == 3 {
                // TODO::
                
                // Push to AboutUs
                let aboutVC = self.storyboard?.instantiateViewController(withIdentifier: "aboutVC") as! AboutUs
                self.navigationController!.pushViewController(aboutVC, animated: true)

            }
            
            if indexPath.row == 4 {
                // FAQ
                
            }
            
            if indexPath.row == 5 {
                // TOS
            }
            
            if indexPath.row == 6 {
                // Privacy Policy
            }
            
        } // end indexPath
        
        
        
        
    }
    
    

}
