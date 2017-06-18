//
//  Onboarding.swift
//  Redplanet
//
//  Created by Joshua Choi on 6/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SwipeNavigationController
import SDWebImage

/*
 Class that allows users to follow public accounts before showing the Camera
 */

class Onboarding: UITableViewController, UINavigationControllerDelegate {
    // Array to hold user object
    var followObjects = [PFObject]()
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
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
                chats["Message"] = "🎊😜🚀👾👏\nHi \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), welcome to the community. Feel free to chat us @teamrp if you have any questions or concerns using Redplanet! You can also head over to https://www.redplanetapp.com/news to find tutorials if you need help. Thanks for you signing up!\n❤️, Redplanet"
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
                                                                      message: "Redplanet needs access for the following...\n\n• Location\n• Camera\n• Photos\n• Microphone")
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
                        
                        // Add settings button
                        dialogController.addAction(AZDialogAction(title: "OK", handler: { (dialog) -> (Void) in
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
//        _ = appDelegate.queryRelationships()
        
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
                    self.tableView!.reloadData()
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    
    
    // FUNCTION - Stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Bold", size: 17) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Follow Other Humans"
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
        // Stylize title
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.backgroundColor = UIColor.white
        self.tableView.separatorColor = UIColor.groupTableViewBackground
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 115
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        // Get rid of back button
        self.navigationController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Fetch users
        fetchUsers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: UITableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.followObjects.count
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 115
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "onboardingCell", for: indexPath) as! OnboardingCell
        
        // Query Relationships
//        _ = appDelegate.queryRelationships()
        
        // MARK: - RPHelpers extension
        cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
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
            cell.followButton.layer.cornerRadius = cell.followButton.frame.size.height/2
            cell.followButton.clipsToBounds = true
        } else {
            // FOLLOW
            // Set button's title and design
            cell.followButton.setTitle("Follow", for: .normal)
            cell.followButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.31, alpha: 1), for: .normal)
            cell.followButton.backgroundColor = UIColor.white
            cell.followButton.layer.cornerRadius = cell.followButton.frame.size.height/2
            cell.followButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.31, alpha: 1).cgColor
            cell.followButton.layer.borderWidth = 2
            cell.followButton.clipsToBounds = true
        }
        
        return cell
    }

}
