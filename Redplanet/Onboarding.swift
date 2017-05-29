//
//  Onboarding.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/22/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SwipeNavigationController
import SDWebImage

class Onboarding: UICollectionViewController {
    
    // Array to hold user object
    var followObjects = [PFObject]()
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch users
        fetchUsers()
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func done(_ sender: Any) {
        // Disable button
        self.doneButton.isEnabled = false
        
        // Send user chat from TeamRP
        PFUser.query()!.getObjectInBackground(withId: "NgIJplW03t") {
            (object: PFObject?, error: Error?) in
            if error == nil {
                let chats = PFObject(className: "Chats")
                chats["sender"] = object!
                chats["senderUsername"] = "teamrp"
                chats["receiver"] = PFUser.current()!
                chats["receiverUsername"] = PFUser.current()!.username!
                chats["read"] = false
                chats["saved"] = false
                chats["Message"] = "Hi \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), welcome to the community! Feel free to chat us @teamrp if you have any questions or concerns using Redplanet. If you're having difficulty using Redplanet, head over to https://medium.com/@redplanetmedia to find tutorials.\n Redplanet"
                chats.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        // Enable button
                        self.doneButton.isEnabled = true
                        
                        // MARK: - RPHelpers
                        let rpHelpers = RPHelpers()
                        rpHelpers.updateQueue(chatQueue: chats, userObject: object!)
                        
                        // MARK: - HEAP Analytics
                        // Track who signed up
                        Heap.track("SignedUp", withProperties:
                            ["byUserId": "\(PFUser.current()!.objectId!)",
                                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
                            ])
                        
                        
                        
                        // MARK: - AZDialogViewController
                        let dialogController = AZDialogViewController(title: "🙈\nPlease Allow Access",
                                                                      message: "Before you begin using Redplanet, we're going to ask you access for the following...\n• Location\n• Camera\n• Photos\n• Microphone")
                        dialogController.dismissDirection = .bottom
                        dialogController.dismissWithOutsideTouch = true
                        dialogController.showSeparator = true
                        // Configure style
                        dialogController.buttonStyle = { (button,height,position) in
                            button.setTitleColor(UIColor.white, for: .normal)
                            button.layer.borderColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0).cgColor
                            button.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
                            button.layer.masksToBounds = true
                        }
                        
                        // Add settings button
                        dialogController.addAction(AZDialogAction(title: "Continue", handler: { (dialog) -> (Void) in
                            // Dismiss
                            dialog.dismiss()
                            // Show main interface once succeeded
                            self.showMain()
                        }))
                        
                        dialogController.show(in: self)
                        
                    } else {
                        print(error?.localizedDescription as Any)
                        // Enable button
                        self.doneButton.isEnabled = true
                        // Show main interface if failed
                        self.showMain()
                    }
                })
            } else {
                print(error?.localizedDescription as Any)
                // Enable button
                self.doneButton.isEnabled = true
                // Show main interface if failed
                self.showMain()
            }
        }
    }

    // FUNCTION - Show main interface
    func showMain() {
        // :)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraVC = storyboard.instantiateViewController(withIdentifier: "center") as! UINavigationController
        let swipeNavigationController = SwipeNavigationController(centerViewController: cameraVC)
        swipeNavigationController.rightViewController = storyboard.instantiateViewController(withIdentifier: "right") as! UINavigationController
        swipeNavigationController.leftViewController = storyboard.instantiateViewController(withIdentifier: "left") as! UINavigationController
        swipeNavigationController.bottomViewController = storyboard.instantiateViewController(withIdentifier: "masterUI") as! MasterUI
        UIApplication.shared.keyWindow?.rootViewController = swipeNavigationController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }
    
    
    // FUNCTION - Fetch these users
    func fetchUsers() {
        // Fetch Relationships
        _ = appDelegate.queryRelationships()
        
        let people = PFUser.query()!
        people.whereKey("private", equalTo: false)
        people.order(byDescending: "createdAt")
        people.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.followObjects.removeAll(keepingCapacity: false)
                
                // Append object
                for object in objects!.reversed() {
                    self.followObjects.append(object)
                }
                
                // Reload data in main thread
                DispatchQueue.main.async {
                    self.collectionView!.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    
    // FUNCTION - Stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Follow People!"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - RPExtensions; Whiten UINavigationBar
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        self.collectionView?.backgroundColor = UIColor.groupTableViewBackground
        
        // Fetch users
        fetchUsers()
        
        // Get rid of back button
        self.navigationController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: UICollectionView DataSource Methods
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.followObjects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "onboardingCell", for: indexPath) as! OnboardingCell
    
        // Query Relationships
        _ = appDelegate.queryRelationships()
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // MARK: RPExteions; Round floatingView and apply ahdow
        cell.floatingView.roundAllCorners(sender: cell.floatingView)
        cell.floatingView.backgroundColor = UIColor.white
        
        // (1) Set user's object
        cell.userObject = self.followObjects[indexPath.row]
        // (2) Set user's fullName and username
        cell.rpFullName.text! = self.followObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
        cell.rpUsername.text! = self.followObjects[indexPath.row].value(forKey: "username") as! String
        // (3) Set user's bio
        if let biography = self.followObjects[indexPath.row].value(forKey: "userBiography") as? String {
            if biography != "" || biography != "Introduce yourself..." {
                cell.bio.text! = self.followObjects[indexPath.row].value(forKey: "userBiography") as! String
                cell.bio.textColor = UIColor.black
            } else {
                cell.bio.text! = "This person doesn't have a bio yet..."
                cell.bio.textColor = UIColor.lightGray
            }
         }
        
        // (4) Set Pro Pic
        if let proPic = self.followObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }

        if currentFollowing.contains(where: {$0.objectId! == self.followObjects[indexPath.row].objectId!}) {
        // FOLLOWING
            // Set button's title and design
            cell.followButton.setTitle("Following", for: .normal)
            cell.followButton.setTitleColor(UIColor.white, for: .normal)
            cell.followButton.backgroundColor =  UIColor(red: 1, green: 0, blue: 0.31, alpha: 1)
            cell.followButton.layer.cornerRadius = 20
            cell.followButton.clipsToBounds = true
        } else {
        // FOLLOW
            // Set button's title and design
            cell.followButton.setTitle("Follow", for: .normal)
            cell.followButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.31, alpha: 1), for: .normal)
            cell.followButton.backgroundColor = UIColor.white
            cell.followButton.layer.cornerRadius = 20
            cell.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
            cell.followButton.layer.borderWidth = 2
            cell.followButton.clipsToBounds = true
        }
    
        return cell
    }


}
