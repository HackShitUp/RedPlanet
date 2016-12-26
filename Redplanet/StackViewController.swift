//
//  StackViewController.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/25/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Photos
import PhotosUI
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts
import KILabel
import SimpleAlert
import OneSignal
import SVProgressHUD



// Array to hold object
var stackObject = [PFObject]()



/*
class MySwipeVC: EZSwipeController, EZSwipeControllerDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        print("LOADED")
    }
    
    override func setupView() {
        datasource = self
    }
    
    
    // Array to hold view controllers
    
    func viewControllerData() -> [UIViewController] {
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.red
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blue
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.green
        
        return [redVC, blueVC, greenVC]
    }
    
    
    func indexOfStartingPage() -> Int {
        return 0 // EZSwipeController starts from 2nd, green page
    }
}
*/


/*
extension MySwipeVC: EZSwipeControllerDataSource {
    
    // Array to hold view controllers
    
    func viewControllerData() -> [UIViewController] {
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.red
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blue
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.green
        
        return [redVC, blueVC, greenVC]
    }
    
    
    func indexOfStartingPage() -> Int {
        return 0 // EZSwipeController starts from 2nd, green page
    }
}
*/



/*
class ViewController: UIViewController, StackViewDataSource {
    
    var stackPageView: StackPageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackPageView.dataSource = self
        stackPageView.parentViewController = self
    }
    
    func stackViewNext(_ currentViewController: UIViewController?) -> UIViewController? {

        var viewController: UIViewController?
        
        for content in Friends().friendsContent {
            if content.value(forKey: "contentType") as! String == "tp" {
                // Append Object
                textPostObject.append(content)
                
                // Present VC
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost

                // Set view controller
                viewController = textPostVC
                
            } else if content.value(forKey: "contentType") as! String == "ph" {
                
                // Append Object
                photoAssetObject.append(content)
                
                // Present VC
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                
                // Set view controller
                viewController = photoVC
            
            } else if content.value(forKey: "contentType") as! String == "pp" {
                
                // Append user's object
                otherObject.append(content.value(forKey: "byUser") as! PFUser)
                // Append user's username
                otherName.append(content.value(forKey: "username") as! String)
                
                // Append object
                proPicObject.append(content)
                
                // Push VC
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto

                
                // Set view controller
                viewController = proPicVC
            
            } else if content.value(forKey: "contentType") as! String == "sh" {
                
                // Append object
                sharedObject.append(content)
                
                // Push VC
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                
                // Set view controller
                viewController = sharedPostVC
            
            } else if content.value(forKey: "contentType") as! String == "sp" {
                
                // Append object
                spaceObject.append(content)
                
                // Append otherObject
                otherObject.append(content.value(forKey: "toUser") as! PFUser)
                
                // Append otherName
                otherName.append(content.value(forKey: "toUsername") as! String)
                
                // Push VC
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                
                // Set view controller
                viewController = spacePostVC
                
            } else if content.value(forKey: "contentType") as! String == "itm" {
                
                // Append content object
                itmObject.append(content)
                
                // Push VC
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                
                // Set view controller
                viewController = itmVC
                
            } else if content.value(forKey: "contentType") as! String == "vi" {
                
                // Append content object
                videoObject.append(content)
                
                // Push VC
                let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                
                // Set view controller
                viewController = videoVC
            
            }
        }
        
        return viewController!
    }
    
    func stackViewPrev(_ currentViewController: UIViewController?) -> UIViewController? {
        var viewController: UIViewController?
        
        for content in Friends().friendsContent {
            if content.value(forKey: "contentType") as! String == "tp" {
                // Append Object
                textPostObject.append(content)
                
                // Present VC
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                
                // Set view controller
                viewController = textPostVC
                
            } else if content.value(forKey: "contentType") as! String == "ph" {
                
                // Append Object
                photoAssetObject.append(content)
                
                // Present VC
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                
                // Set view controller
                viewController = photoVC
                
            } else if content.value(forKey: "contentType") as! String == "pp" {
                
                // Append user's object
                otherObject.append(content.value(forKey: "byUser") as! PFUser)
                // Append user's username
                otherName.append(content.value(forKey: "username") as! String)
                
                // Append object
                proPicObject.append(content)
                
                // Push VC
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                
                
                // Set view controller
                viewController = proPicVC
                
            } else if content.value(forKey: "contentType") as! String == "sh" {
                
                // Append object
                sharedObject.append(content)
                
                // Push VC
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                
                // Set view controller
                viewController = sharedPostVC
                
            } else if content.value(forKey: "contentType") as! String == "sp" {
                
                // Append object
                spaceObject.append(content)
                
                // Append otherObject
                otherObject.append(content.value(forKey: "toUser") as! PFUser)
                
                // Append otherName
                otherName.append(content.value(forKey: "toUsername") as! String)
                
                // Push VC
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                
                // Set view controller
                viewController = spacePostVC
                
            } else if content.value(forKey: "contentType") as! String == "itm" {
                
                // Append content object
                itmObject.append(content)
                
                // Push VC
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                
                // Set view controller
                viewController = itmVC
                
            } else if content.value(forKey: "contentType") as! String == "vi" {
                
                // Append content object
                videoObject.append(content)
                
                // Push VC
                let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                
                // Set view controller
                viewController = videoVC
                
            }
        }
        
        return viewController!
    }
    
}
*/




class StackViewController: EZSwipeController, EZSwipeControllerDataSource {
    
    

    override func setupView() {
        datasource = self
    }
    
    
    // Array to hold view controllers
    
    func viewControllerData() -> [UIViewController] {
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.red
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blue
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.green
        
        return [redVC, blueVC, greenVC]
    }
    
    
    func indexOfStartingPage() -> Int {
        return 0 // EZSwipeController starts from 2nd, green page
    }
    
    
    
    
    // Variable to hold text for the post
    var layoutText: String?
    
    
    // Arrays to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    // @IBOutlet functions
    @IBAction func showLikes(_ sender: Any) {
    }
    @IBAction func likePost(_ sender: Any) {
    }
    @IBAction func showComments(_ sender: Any) {
    }
    @IBAction func comment(_ sender: Any) {
    }
    @IBAction func moreButton(_ sender: Any) {
    }
    @IBAction func showShares(_ sender: Any) {
    }
    
    // Function to leave view
    func backButton(sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to fetch interactions
    func fetchInteractions() {
        
    }
    
    
    // Function to determine size of iphone
    func createTextSize() -> String {
        
        // Check for textPost & handle optional chaining
        if stackObject.last!.value(forKey: "textPost") != nil {
            
            // (A) Set textPost
            // Calculate screen height
            if UIScreen.main.nativeBounds.height == 960 {
                // iPhone 4
                layoutText = "\n\n\n\n\n\n\n\n\n\(stackObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 1136 {
                // iPhone 5 √
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\(stackObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 1334 {
                // iPhone 6 √
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(stackObject.last!.value(forKey: "textPost") as! String)"
            } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                // iPhone 6+ √???
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\(stackObject.last!.value(forKey: "textPost") as! String)"
            }
            
        } else {
            // Caption DOES NOT exist
            
            // (A) Set textPost
            // Calculate screen height
            if UIScreen.main.nativeBounds.height == 960 {
                // iPhone 4
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 1136 {
                // iPhone 5
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 1334 {
                // iPhone 6
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            } else if UIScreen.main.nativeBounds.height == 2201 || UIScreen.main.nativeBounds.height == 2208 {
                // iPhone 6+
                layoutText = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
            }
        }
        
        return layoutText!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.yellow
        print("LOADED")
        
        // (I) Fetch profile photo
        if let user = stackObject.last!.value(forKey: "byUser") as? PFUser {
            
            // Design profile photo
            self.rpUserProPic.layoutIfNeeded()
            self.rpUserProPic.layoutSubviews()
            self.rpUserProPic.setNeedsLayout()
            
            // Make circular
            self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
            self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
            self.rpUserProPic.layer.borderWidth = 0.5
            self.rpUserProPic.clipsToBounds = true
            
            // Get and set profile photo
            if let proPic = user["userProfilePicture"] as? PFFile {
                proPic.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Fetched, set user's profile photo
                        self.rpUserProPic.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                        // Couldn't fetch, set default for now
                        self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                })
            } else {
                // Set default
                self.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
            }
            
            // Set name
            self.rpUsername.text! = user["realNameOfUser"] as! String
        }
        
        // Handle content type
        // (II) Text Post
        if stackObject.last!.value(forKey: "contentType") as! String == "tp" {
            
            // (1) Hide mediaAsset
            self.mediaAsset.isHidden = true
            
            // (2) Set text post
            self.textPost.layoutIfNeeded()
            self.textPost.layoutSubviews()
            self.textPost.setNeedsLayout()
            self.textPost.font = UIFont(name: "AvenirNext-Medium", size: 21.00)
            self.textPost.text! = "\n\(stackObject.last!.value(forKey: "textPost") as! String)\n"
        
        } else if stackObject.last!.value(forKey: "contentType") as! String == "ph" {
            
            // (1) Get photo
            if let photoAsset = stackObject.last!.value(forKey: "photoAsset") as? PFFile {
                photoAsset.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set photo
                        self.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
            // (2) Set caption
            // Call function
            _ = createTextSize()
            // Design
            self.textPost.layoutIfNeeded()
            self.textPost.layoutSubviews()
            self.textPost.setNeedsLayout()
            // Set
            self.textPost.font = UIFont(name: "AvenirNext-Medium", size: 15.00)
            self.textPost.text! = self.layoutText!

            
        } else if stackObject.last!.value(forKey: "contentType") as! String == "pp" {
            
        } else if stackObject.last!.value(forKey: "contentType") as! String == "sp" {
        
        }
        
        
        // (2) Photo
        // (3) Profile Photo
        // (4) Space Post
        // (5) Shared Post
        // (6) Video
        // (7) Moment
        
        
        // Swipe to leave
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(backSwipe)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
