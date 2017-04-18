//
//  OnboardFollow.swift
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

import SwipeNavigationController
import SDWebImage

class OnboardFollow: UITableViewController, UINavigationControllerDelegate {
    
    
    // Array to hold user object
    var followObjects = [PFObject]()

    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func refresh(_ sender: Any) {
        // query relationships
        _ = appDelegate.queryRelationships()
        
        // Fetch users
        fetchUsers()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    @IBAction func doneButton(_ sender: Any) {
        
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
                chats["Message"] = "🚀👾☄️\nHi \(PFUser.current()!.value(forKey: "realNameOfUser") as! String), welcome to the community! Feel free to chat us @teamrp if you have any questions or concerns using Redplanet. If you're having difficulty using Redplanet, head over to https://medium.com/@redplanetmedia to find tutorials.\n❤️, Redplanet"
                chats.saveInBackground(block: {
                    (success: Bool, error: Error?) in
                    if success {
                        // Enable button
                        self.doneButton.isEnabled = true
                        
                        
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
    
    
    // Function to show main interface
    func showMain() {
        // :)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraVC = storyboard.instantiateViewController(withIdentifier: "center") as! UINavigationController
        let swipeNavigationController = SwipeNavigationController(centerViewController: cameraVC)
        swipeNavigationController.topViewController = storyboard.instantiateViewController(withIdentifier: "top") as! UINavigationController
        swipeNavigationController.rightViewController = storyboard.instantiateViewController(withIdentifier: "right") as! UINavigationController
        swipeNavigationController.leftViewController = storyboard.instantiateViewController(withIdentifier: "left") as! UINavigationController
        swipeNavigationController.bottomViewController = storyboard.instantiateViewController(withIdentifier: "mainUITab") as! MainUITab
        UIApplication.shared.keyWindow?.rootViewController = swipeNavigationController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }
    
    
    // Function to fetch these users
    func fetchUsers() {
        let people = PFUser.query()!
        people.whereKey("private", equalTo: false)
        people.order(byAscending: "createdAt")
        people.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.followObjects.removeAll(keepingCapacity: false)

                // Append object
                for object in objects! {
                    self.followObjects.append(object)
                }
                
                // Reload data
                self.tableView!.reloadData()
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }

    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Follow People"
        }
        
        // Configure nav bar && show tab bar (last line)
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        // Show UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 115
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Fetch users
        fetchUsers()
        
        // Get rid of back button
        self.navigationController?.navigationItem.leftBarButtonItem = UIBarButtonItem(title:"", style: .plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followObjects.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "onBoardCell", for: indexPath) as! OnBoardFollowCell
        
//        _ = appDelegate.queryRelationships()
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Give Profile Photo Corner Radius
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
    
        // (1) Set user's object
        cell.userObject = self.followObjects[indexPath.row]
        // (2) Set User's Name
        cell.name.text! = self.followObjects[indexPath.row].value(forKey: "realNameOfUser") as! String
        // (3) Set user's bio
        if self.followObjects[indexPath.row].value(forKey: "userBiography") != nil {
            cell.bio.text! = self.followObjects[indexPath.row].value(forKey: "userBiography") as! String
        } else {
            cell.bio.text! = ""
        }
        // (4) Set Pro Pic
        if let proPic = self.followObjects[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "Gender Neutral User-100"))
        }
        
        
        if myFollowing.contains(where: {$0.objectId! == self.followObjects[indexPath.row].objectId!}) {
            // FOLLOWING
            // Set button's title and design
            cell.followButton.setTitle("Following", for: .normal)
            cell.followButton.setTitleColor(UIColor.white, for: .normal)
            cell.followButton.backgroundColor =  UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            cell.followButton.layer.cornerRadius = 22.0
            cell.followButton.clipsToBounds = true
        } else {
            // FOLLOW
            // Set button's title and design
            cell.followButton.setTitle("Follow", for: .normal)
            cell.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
            cell.followButton.backgroundColor = UIColor.white
            cell.followButton.layer.cornerRadius = 22.00
            cell.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            cell.followButton.layer.borderWidth = 2.00
            cell.followButton.clipsToBounds = true
        }
    
        return cell
    }
 

}
