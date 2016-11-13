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

import SVProgressHUD


class CreateFront: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate, IGCMenuDelegate {
    
    
    
    
    // NOTIFICATIONs
    // Array to hold my notifications
    var myActivity = [PFObject]()
    
    // Array to hold fromUser Objects
    var fromUsers = [PFObject]()
    
    
    // AppDelegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    // Refresher
    var refresher: UIRefreshControl!
    
    
    // MARK: - IGCMenu
    // Initialize IGCMenu and UIButton
    let igcMenu = IGCMenu()
    let menuButton = UIButton()
    
    
    // Page size
    var page: Int = 25
    
    
    @IBOutlet weak var tableView: UITableView!

    
    
    
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
                // Push VC
                let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
                self.navigationController!.pushViewController(cameraVC, animated: true)
            })
            
            
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true {
                    // User granted camera access
                    print("Authorized")
                    
                    // Load Camera
                    DispatchQueue.main.async(execute: {
                        let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
                        self.navigationController!.pushViewController(cameraVC, animated: true)
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
                print(error?.localizedDescription as Any)
            }
            
            // Reload Data
            self.tableView!.reloadData()
        })
    }
    
    
    
    
    // Show Grid menu on tap
    // MARK: - UITabBarControllerDelegate Method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        // Dismiss Progress
        SVProgressHUD.dismiss()
        
        if self.navigationController?.tabBarController?.selectedIndex == 2 {
            // Hide navigationbar
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            // Hide tabBarController
            self.navigationController?.tabBarController?.tabBar.isHidden = false
            // Show Grid Menu
            igcMenu.showGridMenu()
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
    
    
    // Status bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
            self.title = "Notifications"
        }
    }
    
    
    
    // Refresh function
    func refresh() {
        // Query notifications
        queryNotifications()
        
        // End refresher
        self.refresher.endRefreshing()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set tabBarController's delegate to self
        self.navigationController?.tabBarController?.delegate = self
        
        // Hide navigationbar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Stylize title
        configureView()
        
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

        
        // Set initial query
        self.queryNotifications()
        

        // Pull to refresh action
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
        
        
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
        
        // query Notifications
        queryNotifications()
        
        // Stylize title
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Show tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        // Stylize title
        configureView()
        
        // Query notifications
        queryNotifications()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("returning: \(myActivity.count)")
        return myActivity.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        
        
        // Initialize and set parent vc
        cell.delegate = self
        
        // Declare content's object
        // in Notifications' <forObjectId>
        cell.contentObject = myActivity[indexPath.row]
        

        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Give Profile Photo Corner Radius
        cell.rpUserProPic.layer.cornerRadius = 8.00
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        // (1) Set user's object
        cell.userObject = fromUsers[indexPath.row]
        
       
        // (2) Fetch User Object
        fromUsers[indexPath.row].fetchIfNeededInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Set Username
                cell.rpUsername.setTitle("\(object!["realNameOfUser"] as! String)", for: .normal)
                
                // (2) Get and user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set Profile Photo
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // Set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-100")
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        
        // (3) Set title of activity
        
        // =================================================================================================================================
        // =================================================================================================================================
        // START TITLE =====================================================================================================================
        // =================================================================================================================================
        // =================================================================================================================================
        

        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== R E L A T I O N S H I P S ---------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------
        
        
        
        // (1) Friend Requested
        if myActivity[indexPath.row].value(forKey: "type") as! String == "friend requested" {
            cell.activity.setTitle("asked to be friends", for: .normal)
        }
        
        // (2) Friended
        if myActivity[indexPath.row].value(forKey: "type") as! String == "friended" {
            cell.activity.setTitle("is now friends with you", for: .normal)
        }
        
        // (3) Follow Requested
        if myActivity[indexPath.row].value(forKey: "type") as! String == "follow requested" {
            cell.activity.setTitle("asked to follow you", for: .normal)
        }
        
        // (4) Followed
        if myActivity[indexPath.row].value(forKey: "type") as! String == "followed" {
            cell.activity.setTitle("started following you", for: .normal)
        }
        
        
        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== S P A C E -------------------------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------

        // Space
        if myActivity[indexPath.row].value(forKey: "type") as! String == "space" {
            cell.activity.setTitle("wrote in your Space", for: .normal)
        }

        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== L I K E ---------------------------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------

        
        // (1) Text Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like tp" {
            cell.activity.setTitle("liked your text post", for: .normal)
        }
        
        
        // TODO::
        // Remove "like pv" once everyone has the new update
        // (2) Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like ph" || myActivity[indexPath.row].value(forKey: "type") as! String == "like pv" {
            cell.activity.setTitle("liked your photo", for: .normal)
        }
        
        // (3) Profile Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like pp" {
            cell.activity.setTitle("liked your profile photo", for: .normal)
        }
        
        // (4) Space Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like sp" {
            cell.activity.setTitle("liked your space post", for: .normal)
        }
        
        // (5) Shared
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like sh" {
            cell.activity.setTitle("liked your shared post", for: .normal)
        }
        
        
        // (6) Moment
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like itm" {
            cell.activity.setTitle("liked your moment", for: .normal)
        }
        
        // (7)  Liked Comment
        if myActivity[indexPath.row].value(forKey: "type") as! String == "like co" {
            cell.activity.setTitle("liked your comment", for: .normal)
        }
        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== T A G -----------------------------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------
        
        // (1) Text Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "tag tp" {
            cell.activity.setTitle("tagged you in a text post", for: .normal)
        }

        // (2) Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "tag ph" {
            cell.activity.setTitle("tagged you in a photo", for: .normal)
        }
        
        // (3) Profile Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "tag pp" {
            cell.activity.setTitle("tagged you in a profile photo", for: .normal)
        }
        
        // (4) Space Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "tag sp" {
            cell.activity.setTitle("tagged you in a space post", for: .normal)
        }
        
        // (5) Comment
        if myActivity[indexPath.row].value(forKey: "type") as! String == "tag co" {
            cell.activity.setTitle("tagged you in a comment", for: .normal)
        }
        
        
        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== C O M M E N T ---------------------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------
        // Comment
        if myActivity[indexPath.row].value(forKey: "type") as! String == "comment" {
            cell.activity.setTitle("commented on your post", for: .normal)
        }
        
        
        
        // --------------------------------------------------------------------------------------------------------------------------------
        // ==================== S H A R E D -----------------------------------------------------------------------------------------------
        // --------------------------------------------------------------------------------------------------------------------------------
        
        // (1) Text Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share tp" {
            cell.activity.setTitle("shared your text post", for: .normal)
        }
        
        // (2) Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share ph" {
            cell.activity.setTitle("shared your photo", for: .normal)
        }
        
        // (3) Profile Photo
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share pp" {
            cell.activity.setTitle("shared your profile photo", for: .normal)
        }
        
        // (4) Space Post
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share sp" {
            cell.activity.setTitle("shared your space post", for: .normal)
        }
        
        // (5) Share
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share sh" {
            cell.activity.setTitle("re-shared your shared post", for: .normal)
        }
        
        // (6) Moment
        if myActivity[indexPath.row].value(forKey: "type") as! String == "share itm" {
            cell.activity.setTitle("shared your moment", for: .normal)
        }
        
        
        
        // =================================================================================================================================
        // =================================================================================================================================
        // END TITLE =======================================================================================================================
        // =================================================================================================================================
        // =================================================================================================================================
        
        
        
        // (4) Set time
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
        if page <= myActivity.count {
            
            // Increase page size to load more posts
            page = page + 25

            
            // Fetch Notifications
            queryNotifications()


        }
    }
    

}
