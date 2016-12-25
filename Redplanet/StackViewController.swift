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


class StackViewController: UIViewController {
    
    
    
    // Arrays to hold likes, comments, and shares
    var likes = [PFObject]()
    var comments = [PFObject]()
    var shares = [PFObject]()
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
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
    
    // Function to fetch interactions
    func fetchInteractions() {
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle content type
        // (I) Text Post
        if stackObject.last!.value(forKey: "contentType") as! String == "tp" {
            // (1) Hide mediaAsset
            self.mediaAsset.isHidden = true
            // (2) Set text post
            self.textPost.text! = stackObject.last!.value(forKey: "textPost") as! String
            self.textPost.sizeToFit()
            self.textPost.setNeedsLayout()
            self.textPost.setNeedsDisplay()
        } else if stackObject.last!.value(forKey: "contentType") as! String == "ph" {
            
        } else if stackObject.last!.value(forKey: "contentType") as! String == "ph" {
        
        } else if stackObject.last!.value(forKey: "contentType") as! String == "ph" {
        
        }
        
        // (2) Photo
        // (3) Profile Photo
        // (4) Space Post
        // (5) Shared Post
        // (6) Video
        // (7) Moment

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Hide tab bar controller
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        
        // Create corner radius
        self.view.layer.cornerRadius = 12.00
        self.view.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset corner radius
        self.view.layer.cornerRadius = 0.0
        self.view.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
