//
//  CreateFront.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import PhotosUI

import Parse
import ParseUI
import Bolts


class CreateFront: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate, IGCMenuDelegate {
    
    @IBOutlet weak var activityType: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    
    // FRIENDS
    // Array to hold friends' notifications
    var friendActivity = [PFObject]()
    
    // Array to hold <fromUser> pointer objects
    var friendFromUsers = [PFObject]()
    
    // Array to hold fromUser Objects
    var toUsers = [PFObject]()
    
    
    // NOTIFICATIONs
    // Array to hold my notifications
    var myActivity = [PFObject]()
    
    // Array to hold fromUser Objects
    var fromUsers = [PFObject]()
    
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // IGCMenu!!!
    let igcMenu = IGCMenu()
    let menuButton = UIButton()
    
    
    // Page size
    var page: Int = 25
    
    


    @IBAction func switchSource(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            queryNotifications()
            
        case 1:
            queryActivity()
            
        default:
            break;
        }
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Function to access camera
    func takePhoto() {
        // Check Auhorization
        cameraAuthorization()
        // and show camera depending on status...
    }
    
    
    // Function to check authorization
    func cameraAuthorization() {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized {
            // Already Authorized
            print("Already Authroized")
            
            // Load Camera
            DispatchQueue.main.async(execute: {
                let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
                self.present(cameraVC, animated: true, completion: nil)
            })
            
            
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true {
                    // User granted camera access
                    print("Authorized")
                    
                    // Load Camera
                    DispatchQueue.main.async(execute: {
                        let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
                        self.present(cameraVC, animated: true, completion: nil)
                    })
                    
                } else {
                    // User denied camera access
                    print("Denied")
                    let alert = UIAlertController(title: "Camera Access Denied",
                                                  message: "Please allow Redplanet to use your camera.",
                                                  preferredStyle: .alert)
                    
                    let settings = UIAlertAction(title: "Settings",
                                                 style: .default,
                                                 handler: {(alertAction: UIAlertAction!) in
                                                    
                                                    let url = URL(string: UIApplicationOpenSettingsURLString)
                                                    UIApplication.shared.openURL(url!)
                    })
                    
                    let deny = UIAlertAction(title: "Later",
                                             style: .destructive,
                                             handler: nil)
                    
                    alert.addAction(settings)
                    alert.addAction(deny)
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    
    
    // Function to create new text post
    func newTextPost() {
        // Load New TextPost
        let newTP = self.storyboard?.instantiateViewController(withIdentifier: "newTextPost") as! NewTextPost
        self.navigationController?.pushViewController(newTP, animated: true)
    }
    
    // Function to load user's photos
    func loadLibrary() {
        // Request access to Photos
        photosAuthorization()
        // and load view controllers depending on status
    }
    
    
    // Function to ask for permission to the PhotoLibrary
    func photosAuthorization() {
        PHPhotoLibrary.requestAuthorization({(status:PHAuthorizationStatus) in
            switch status{
            case .authorized:
                print("Authorized")
                
                // Load Photo Library
                DispatchQueue.main.async(execute: { 
                    let library = self.storyboard?.instantiateViewController(withIdentifier: "photoLibraryVC") as! PhotoLibrary
                    self.navigationController!.pushViewController(library, animated: true)
                })
                

                break
            case .denied:
                print("Denied")
                let alert = UIAlertController(title: "Photos Access Denied",
                                              message: "Please allow Redplanet access your Photos.",
                                              preferredStyle: .alert)
                
                let settings = UIAlertAction(title: "Settings",
                                             style: .default,
                                             handler: {(alertAction: UIAlertAction!) in
                                                
                                                let url = URL(string: UIApplicationOpenSettingsURLString)
                                                UIApplication.shared.openURL(url!)
                })
                
                let deny = UIAlertAction(title: "Later",
                                         style: .destructive,
                                         handler: nil)
                
                alert.addAction(settings)
                alert.addAction(deny)
                self.present(alert, animated: true, completion: nil)

                break
            default:
                print("Default")

                break
            }
        })
    }

    
    
    
    // Query Friends' Activity
    func queryActivity() {
        
        // Fetch Relationships appDelegate
        appDelegate.queryRelationships()
        
        // Fetch Friends' Activity
        let notifications = PFQuery(className: "Notifications")
        notifications.includeKey("fromUser")
        notifications.includeKey("toUser")
        notifications.whereKey("fromUser", containedIn: myFriends)
        notifications.whereKey("toUser", notEqualTo: PFUser.current()!)
        notifications.limit = self.page
        notifications.order(byDescending: "createdAt")
        notifications.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friendActivity.removeAll(keepingCapacity: false)
                self.friendFromUsers.removeAll(keepingCapacity: false)
                self.toUsers.removeAll(keepingCapacity: false)
                
                
                // Append objects
                for object in objects! {
                    self.friendActivity.append(object)
                    self.friendFromUsers.append(object["fromUser"] as! PFUser)
                    self.toUsers.append(object["toUser"] as! PFUser)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload Data
            self.tableView!.reloadData()
        })
    }
    
    
    
    // Query Notifications
    func queryNotifications() {

        // Fetch your notifications
        let notifications = PFQuery(className: "Notifications")
        notifications.includeKey("toUser")
        notifications.whereKey("toUser", equalTo: PFUser.current()!)
        
        notifications.order(byDescending: "createdAt")
        notifications.limit = self.page
        notifications.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.myActivity.removeAll(keepingCapacity: false)
                self.fromUsers.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.myActivity.append(object)
                    self.fromUsers.append(object["fromUser"] as! PFUser)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload Data
            self.tableView!.reloadData()
        })
    }
    
    
    
    
    // Show Grid menu on tap
    // MARK: - UITabBarControllerDelegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        if self.navigationController?.tabBarController?.selectedIndex == 2 {
            // Hide navigationbar
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            // Hide tabBarController
            self.navigationController?.tabBarController?.tabBar.isHidden = true
            // Show Grid Menu
            igcMenu.showGridMenu()
//            igcMenu.showCircularMenu()

        }
    }

    
    // MARK: - IGCMenuDelegate Method
    func igcMenuSelected(_ selectedMenuName: String, at index: Int) {
        
        if index == 0 {
            // Load photo library
            photosAuthorization()

        } else if index == 1 {
            // Access Camera
            cameraAuthorization()
            
        } else if index == 2{
            // Create new text post
            newTextPost()
            
        } else {
            // Show navigationbar
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            // Show tabBarController
            self.navigationController?.tabBarController?.tabBar.isHidden = false
            
            // Hide menu
            igcMenu.hideGridMenu()
//            igcMenu.hideCircularMenu()
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tabBarController's delegate to self
        self.navigationController?.tabBarController?.delegate = self
        
        // Hide navigationbar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        
        
        // MARK: - IGCMenuDataSource and Delegates
        menuButton.frame = CGRect(x: UIScreen.main.bounds.size.width/2 - 30, y: UIScreen.main.bounds.size.height-150, width: 60, height: 60)
        menuButton.backgroundColor = UIColor.white
        menuButton.layer.cornerRadius = self.menuButton.frame.size.width/2
        menuButton.clipsToBounds = true
        igcMenu.menuButton = self.menuButton
        igcMenu.menuSuperView = self.view!
        self.view!.bringSubview(toFront: menuButton)
        igcMenu.disableBackground = true
        igcMenu.numberOfMenuItem = 4
        igcMenu.delegate = self
        igcMenu.menuImagesNameArray = ["igcPhotos", "igcCamera", "igcText", "igcExit"]
        igcMenu.showGridMenu()
//        igcMenu.showCircularMenu()

        
        // Set initial queries
        if self.activityType.selectedSegmentIndex == 0 {
            // You
            self.queryNotifications()
        } else {
            // Friends
            self.queryActivity()
        }

        
        // Give tableView rounded corners
        self.tableView!.layer.cornerRadius = 10.00
        self.tableView!.layer.borderColor = UIColor.white.cgColor
        self.tableView!.layer.borderWidth = 0.75
        self.tableView!.clipsToBounds = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.activityType.selectedSegmentIndex == 0 {
            print("returning: \(myActivity.count)")
            return myActivity.count
            
        } else {
            
            print("returning: \(friendActivity.count)")
            return friendActivity.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        
        
        // Initialize and set parent vc
        cell.delegate = self
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // =======================================================================================================================
        // (I) ME ================================================================================================================
        // =======================================================================================================================
        if activityType.selectedSegmentIndex == 0 {
            
            // Set user's object
            cell.userObject = fromUsers[indexPath.row]
            
            
            // Fetch User Object
            fromUsers[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // (1) Set Username
                    cell.rpUsername.setTitle("\(object!["username"] as! String)", for: .normal)
                    
                    // (2) Get and user's profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set Profile Photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    }
                    
                } else {
                    print(error?.localizedDescription)
                }
            })
            
            
            
            // Friend Requested
            if myActivity[indexPath.row].value(forKey: "type") as! String == "friend requested" {
                cell.activity.setTitle("asked to be friends", for: .normal)
            }
            
            // Friended
            if myActivity[indexPath.row].value(forKey: "type") as! String == "friended" {
                cell.activity.setTitle("is now friends with you", for: .normal)
            }
            
            // Follow Requested
            if myActivity[indexPath.row].value(forKey: "type") as! String == "follow requested" {
                cell.activity.setTitle("asked to follow you", for: .normal)
            }
            
            // Followed
            if myActivity[indexPath.row].value(forKey: "type") as! String == "followed" {
                cell.activity.setTitle("is now following you", for: .normal)
            }
            
            
            // Space
            if myActivity[indexPath.row].value(forKey: "type") as! String == "wall" {
                cell.activity.setTitle("wrote in your Space", for: .normal)
            }
            
            // View
            // Friended
            if myActivity[indexPath.row].value(forKey: "type") as! String == "view" {
                cell.activity.setTitle("viewed your profile", for: .normal)
            }
            
            

            
            
            
            // Liked Media
            if myActivity[indexPath.row].value(forKey: "type") as! String == "like pv" {
                cell.activity.setTitle("liked your photo", for: .normal)
            }
            
            // Liked Text Post
            if myActivity[indexPath.row].value(forKey: "type") as! String == "like tp" {
                cell.activity.setTitle("liked your text post", for: .normal)
            }
            
            // Liked Profile Photo
            if myActivity[indexPath.row].value(forKey: "type") as! String == "like pp" {
                cell.activity.setTitle("liked your profile photo", for: .normal)
            }
            
            // Liked Space Post
            if myActivity[indexPath.row].value(forKey: "type") as! String == "like wa" {
                cell.activity.setTitle("liked your space post", for: .normal)
            }
            
            // Liked Comment
            if myActivity[indexPath.row].value(forKey: "type") as! String == "like co" {
                cell.activity.setTitle("liked your comment", for: .normal)
            }
            
            
            

            // Tag in Media
            if myActivity[indexPath.row].value(forKey: "type") as! String == "tag pv" {
                cell.activity.setTitle("tagged you in a photo", for: .normal)
            }
            
            // Tag in Text Post
            if myActivity[indexPath.row].value(forKey: "type") as! String == "tag tp" {
                cell.activity.setTitle("tagged you in a text post", for: .normal)
            }
            
            // Tag in Profile Photo
            if myActivity[indexPath.row].value(forKey: "type") as! String == "tag pp" {
                cell.activity.setTitle("tagged you in a profile photo", for: .normal)
            }
            
            // Tag in Space Post
            if myActivity[indexPath.row].value(forKey: "type") as! String == "tag wa" {
                cell.activity.setTitle("tagged you in a space post", for: .normal)
            }
            
            // Tag in comment
            if myActivity[indexPath.row].value(forKey: "type") as! String == "tag co" {
                cell.activity.setTitle("tagged you in a comment", for: .normal)
            }
            
            
            
            
            
            // Comment
            if myActivity[indexPath.row].value(forKey: "type") as! String == "comment" {
                cell.activity.setTitle("commented on your content", for: .normal)
            }
            
            
            // Set time
            let from = myActivity[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.time.text = "now"
            }
            
            if difference.second! > 0 && difference.minute! == 0 {
                cell.time.text = "\(difference.second!)s ago"
            }
            
            if difference.minute! > 0 && difference.hour! == 0 {
                cell.time.text = "\(difference.minute!)m ago"
            }
            
            if difference.hour! > 0 && difference.day! == 0 {
                cell.time.text = "\(difference.hour!)h ago"
            }
            
            if difference.day! > 0 && difference.weekOfMonth! == 0 {
                cell.time.text = "\(difference.day!)d ago"
            }
            
            if difference.weekOfMonth! > 0 {
                cell.time.text = "\(difference.weekOfMonth!)w ago"
            }
            
            
            
            
        } else {
            // =======================================================================================================================
            // (II) FRIENDS ==========================================================================================================
            // =======================================================================================================================
            
            // POINTER ===> <fromUser>
            // Point to User Object
            
            
            // Set user's object
            cell.userObject = friendFromUsers[indexPath.row]
            
            
            // (1) Set username
            cell.rpUsername.setTitle("\(friendFromUsers[indexPath.row].value(forKey: "username") as! String)", for: .normal)
            
            // (2) Get and set user's profile photo
            if let proPic = friendFromUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set Profile Photo
                        cell.rpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription)
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                })
            }
            
            
            // (3) Set activity titles...
            toUsers[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    // Friended, Followed,
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "friended" {
                        cell.activity.setTitle("is now friends with \(object!["username"] as! String)", for: .normal)
                    }
                    
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "followed" {
                        cell.activity.setTitle("is now following \(object!["username"] as! String)", for: .normal)
                    }
                    
                    
                    
                    
                    // Liked
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "like pv" {
                        cell.activity.setTitle("liked \(object!["username"] as! String)'s photo", for: .normal)
                    }
                    
                    
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "like tp" {
                        cell.activity.setTitle("liked \(object!["username"] as! String)'s text post", for: .normal)
                    }
                    
                    
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "like pp" {
                        cell.activity.setTitle("liked \(object!["username"] as! String)'s profile photo", for: .normal)
                    }
                    
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "like wa" {
                        cell.activity.setTitle("liked \(object!["username"] as! String)'s space post", for: .normal)
                    }
                    
                    
                    //            if friendActivity[indexPath.row].value(forKey: "type") as! String == "like co" {
                    //
                    //            }
                    
                    
                    
                    
                    // Comment
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "comment" {
                        cell.activity.setTitle("commented on \(object!["username"] as! String)'s content", for: .normal)
                    }
                    
                    // Space Post
                    if self.friendActivity[indexPath.row].value(forKey: "type") as! String == "wall" {
                        cell.activity.setTitle("wrote in \(object!["username"] as! String)'s space", for: .normal)
                    }
                } else {
                    print(error?.localizedDescription)
                }
            })
            
            
            
            
            // (4) Set time
            let from = friendActivity[indexPath.row].createdAt!
            let now = Date()
            let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
            let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
            
            // logic what to show : Seconds, minutes, hours, days, or weeks
            if difference.second! <= 0 {
                cell.time.text = "now"
            }
            
            if difference.second! > 0 && difference.minute! == 0 {
                cell.time.text = "\(difference.second!)s ago"
            }
            
            if difference.minute! > 0 && difference.hour! == 0 {
                cell.time.text = "\(difference.minute!)m ago"
            }
            
            if difference.hour! > 0 && difference.day! == 0 {
                cell.time.text = "\(difference.hour!)h ago"
            }
            
            if difference.day! > 0 && difference.weekOfMonth! == 0 {
                cell.time.text = "\(difference.day!)d ago"
            }
            
            if difference.weekOfMonth! > 0 {
                cell.time.text = "\(difference.weekOfMonth!)w ago"
            }
            
            
        }
        
        
        
        
        return cell
    }

    
    
    
    
    // Uncomment below lines to query faster by limiting query and loading more on scroll!!!
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - self.view.frame.size.height * 2 {
            loadMore()
        }
    }
    
    func loadMore() {
        // If posts on server are > than shown
        if page <= myActivity.count || page <= friendActivity.count {
            
            // Increase page size to load more posts
            page = page + 25
            
            
            if activityType.selectedSegmentIndex == 0 {
                queryNotifications()
            } else {
                queryActivity()
            }
        }
    }
    

}
