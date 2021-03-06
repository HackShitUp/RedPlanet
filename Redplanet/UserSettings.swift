//
//  UserSettings.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import SDWebImage
import OneSignal


/*
 UITableViewController class that shows the settings options for the current user.
 */

class UserSettings: UITableViewController, UINavigationControllerDelegate, OSPermissionObserver, OSSubscriptionObserver {

    @IBOutlet weak var privacy: UISwitch!
    @IBAction func privacyOptionsAction(_ sender: Any) {
        
        // Private Account
        if self.privacy.isOn {
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Private Account",
                                                          message: "\n• Follow requests must be confirmed.\n• Only your followers can view your posts now.")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = false
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.layer.masksToBounds = true
            }
            // Ok Action
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // MARK: - Parse
                let user = PFUser.current()
                user!["private"] = true
                user!.saveEventually()
                // Dismiss
                dialog.dismiss()
            }))
            dialogController.show(in: self)
            
        } else {
            // Public account
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Public Account",
                                                          message: "\n• Anyone can now follow you and see your posts.\n• Your profile and posts will also be part of Explore's 'Featued Posts.'")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = false
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.layer.masksToBounds = true
            }
            // Ok Action
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // MARK: - Parse
                let user = PFUser.current()
                user!["private"] = false
                user!.saveEventually()
                // Dismiss
                dialog.dismiss()
            }))
            dialogController.show(in: self)
        }
    }
    
    @IBOutlet weak var launchOptions: UISwitch!
    @IBAction func launchOptionsAction(_ sender: Any) {
        // Private Account
        if launchOptions.isOn {
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Launch on Camera",
                                                          message: "Redplanet will open to the camera when you first launch the app.")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = false
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.layer.masksToBounds = true
            }
            // Ok Action
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Set UserDefaults' "launchOnCamera" to true
                UserDefaults.standard.set(true, forKey: "launchOnCamera")
                UserDefaults.standard.synchronize()
                // Dismiss
                dialog.dismiss()
            }))
            dialogController.show(in: self)
            
        } else {
            // Public account
            // MARK: - AZDialogViewController
            let dialogController = AZDialogViewController(title: "Launch on Home",
                                                          message: "Redplanet will open to the home feed and the main interface when you first launch the app.")
            dialogController.dismissDirection = .bottom
            dialogController.dismissWithOutsideTouch = false
            dialogController.showSeparator = true
            // Configure style
            dialogController.buttonStyle = { (button,height,position) in
                button.setTitleColor(UIColor.white, for: .normal)
                button.layer.borderColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1).cgColor
                button.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
                button.layer.masksToBounds = true
            }
            // Ok Action
            dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                // Set UserDefaults' "launchOnCamera" to false
                UserDefaults.standard.set(false, forKey: "launchOnCamera")
                UserDefaults.standard.synchronize()
                // Dismiss
                dialog.dismiss()
            }))
            dialogController.show(in: self)
        }
    }
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func invitePeople(_ sender: Any) {
        // Track when user taps the invite button
        Heap.track("TappedInvite", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        // Show Activity
        let textToShare = "Yo this app is 🔥! Follow me on Redplanet, my username is @\(PFUser.current()!.username!)"
        if let myWebsite = NSURL(string: "https://redplanetapp.com/download/") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }

    // FUNCTION - Stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem!.title = "Settings"
        }
        // Configure UINavigationBar via extension
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.tabBarController?.tabBar.isTranslucent = true
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    // Deep link user to change settings
    func openSettings() {
        let url = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(url!)
    }
    
    
    
    // MARK: - OneSignal
    /*
     Called when the user changes Notifications Access from "off" --> "on"
     REQUIRED
     */
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            print("Subscribed for OneSignal push notifications!")
            
            let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
            let userID = status.subscriptionStatus.userId
            print("THE userID = \(String(describing: userID))\n\n\n")
            
            // MARK: - Parse
            // Save user's apnsId to server
            if PFUser.current() != nil {
                PFUser.current()!["apnsId"] = userID
                PFUser.current()!.saveInBackground()
            }
        }
    }
    
    func onOSPermissionChanged(_ stateChanges: OSPermissionStateChanges!) {
        if stateChanges.from.status == .notDetermined || stateChanges.from.status == .denied {
            if stateChanges.to.status == .authorized {
                print("-AUTHORIZED")
            }
        }
    }
    /**/
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // MARK: - SwipeNavigationController
        self.containerSwipeNavigationController?.shouldShowCenterViewController = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UISwitch...
        // (1) Privacy; Current User's Privacy Settings and show in UISwitch; privacy
        if PFUser.current()!.value(forKey: "private") as! Bool == true {
            self.privacy.setOn(true, animated: false)
        } else {
            self.privacy.setOn(false, animated: false)
        }
        
        // (2) Launch Preference; Current User's Launch Preferences and show in UISwitch; launchOptions
        if UserDefaults.standard.bool(forKey: "launchOnCamera") == false {
            self.launchOptions.setOn(false, animated: false)
        } else {
            self.launchOptions.setOn(true, animated: false)
        }
        
        // Add UITableFooterView
        let versionView = UIView()
        let title = UILabel()
        title.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 60)
        title.font = UIFont(name: "AvenirNext-Demibold", size: 12)
        title.textColor = UIColor.black
        title.backgroundColor = UIColor.white
        title.numberOfLines = 0
        title.text = "Redplanet version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)\nMade with ❤ in NYC.\n🗽 rp 🌉"
        title.textAlignment = .center
        versionView.addSubview(title)
        self.tableView.tableFooterView = versionView
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }


    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // ACCOUNT
            return 7
        } else if section == 1 {
            // DEVICE
            return 3
        } else if section == 2{
            // MORE
            return 3
        } else {
            // ABOUT
            return 4
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let title = UILabel()
        title.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30)
        title.font = UIFont(name: "AvenirNext-Heavy", size: 12)
        title.textColor = UIColor.darkGray
        title.backgroundColor = UIColor.groupTableViewBackground
        title.text = "      \(self.tableView(tableView, titleForHeaderInSection: section)!)"
        title.textAlignment = .natural
        view.addSubview(title)
        return view
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
        // ====================================================================
        // ACCOUNT ============================================================
        // ====================================================================
            if indexPath.row == 0 {
            // Edit Profile
                let editProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "profileEditVC") as! ProfileEdit
                self.navigationController?.pushViewController(editProfileVC, animated: true)
            } else if indexPath.row == 1 {
            // Relationship Requests
                let rRequestsVC = self.storyboard?.instantiateViewController(withIdentifier: "followRequestsVC") as! FollowRequests
                self.navigationController?.pushViewController(rRequestsVC, animated: true)
            } else if indexPath.row == 2 {
            // Friends in Contacts
                let contactsVC = self.storyboard?.instantiateViewController(withIdentifier: "contactsVC") as! Contacts
                self.navigationController!.pushViewController(contactsVC, animated: true)
                
            } else if indexPath.row == 3 {
            // Reset Password
                let passwordVC = self.storyboard?.instantiateViewController(withIdentifier: "passwordVC") as! ResetPassword
                self.navigationController?.pushViewController(passwordVC, animated: true)
            } else if indexPath.row == 4 {
            // Blocked Users
                let blockedVC = self.storyboard?.instantiateViewController(withIdentifier: "blockedVC") as! BlockedUsers
                self.navigationController?.pushViewController(blockedVC, animated: true)
            } else if indexPath.row == 5 {
            // Privacy
            } else if indexPath.row == 6 {
            // LOGOUT
                // Remove logged in user from app memory
                PFUser.logOutInBackground(block: { (error: Error?) in
                    if error == nil {
                        // Logout
                        let logoutToStart = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
                        self.present(logoutToStart, animated: true, completion: nil)
                    }
                })
            }
            
        } else if indexPath.section == 1 {
        // ====================================================================
        // DEVICE =============================================================
        // ====================================================================
            if indexPath.row == 0 {
                // Clear cache first
                PFQuery.clearAllCachedResults()
                PFFile.clearAllCachedDataInBackground()
                URLCache.shared.removeAllCachedResponses()
                SDImageCache.shared().clearMemory()
                SDImageCache.shared().clearDisk()

                // MARK: - AZDialogViewController
                let dialogController = AZDialogViewController(title: "Cleared Cache",
                                                              message: "Redplanet's network cache policy and storage was successfully reset!")
                dialogController.dismissDirection = .bottom
                dialogController.dismissWithOutsideTouch = false
                dialogController.showSeparator = true
                // Configure style
                dialogController.buttonStyle = { (button,height,position) in
                    button.setTitleColor(UIColor.white, for: .normal)
                    button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                    button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                    button.layer.masksToBounds = true
                }
                // Add Delete button
                dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
                    // Dismiss
                    dialog.dismiss()
                    // Clear cache again
                    PFQuery.clearAllCachedResults()
                    PFFile.clearAllCachedDataInBackground()
                    URLCache.shared.removeAllCachedResponses()
                    SDImageCache.shared().clearMemory()
                    SDImageCache.shared().clearDisk()

                }))
                
                dialogController.show(in: self)
                
            } else if indexPath.row == 1 {
            // PERMISSIONS
                // Show Settings
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            } else {
            // SET LAUNCH OPTIONS
            }
            
            
        } else if indexPath.section == 2 {
        // ====================================================================
        // MORE ===============================================================
        // ====================================================================
            if indexPath.row == 0 {
                // Track when user taps the invite button
                Heap.track("TappedInvite", withProperties:
                    ["byUserId": "\(PFUser.current()!.objectId!)",
                        "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                    ])
                // Show Activity
                let textToShare = "Yo this app is 🔥! Follow me on Redplanet, my username is @\(PFUser.current()!.username!)"
                if let myWebsite = NSURL(string: "https://redplanetapp.com/download/") {
                    let objectsToShare = [textToShare, myWebsite] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }
            } else if indexPath.row == 1 {

                // FEEDBACK
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/contact/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)
                
            } else {
                // VERIFICATION
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/verification/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)
            }
            
        
        } else {
        // ====================================================================
        // ABOUT ==============================================================
        // ====================================================================
            if indexPath.row == 0 {
                // ABOUT US
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/about/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)

            } else if indexPath.row == 1 {
                // LICENSES
                // Track when user views license
                Heap.track("ViewedLicense", withProperties:
                    ["byUserId": "\(PFUser.current()!.objectId!)",
                        "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                    ])
                
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/licenses/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)
                
            } else if indexPath.row == 2 {
                // TOS
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/terms-of-service/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)
            } else {
                // PRIVACY POLICY
                // MARK: - SafariServices
                let webVC = SFSafariViewController(url: URL(string: "https://redplanetapp.com/privacy-policy/")!, entersReaderIfAvailable: false)
                self.present(webVC, animated: true, completion: nil)
            }
            
        }
        
    }// end didSelectRowAt

}
