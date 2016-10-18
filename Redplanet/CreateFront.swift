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


class CreateFront: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoLibrary: UIButton!
    @IBOutlet weak var textPost: UIButton!
    
    
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
            
            let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
            self.present(cameraVC, animated: true, completion: nil)
            
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true {
                    // User granted camera access
                    print("Authorized")
                    
                    let cameraVC = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CustomCamera
                    self.present(cameraVC, animated: true, completion: nil)
                    
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
        // TODO::
        // Load new Text Post View Controller
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
                
                // TODO::
                // Load user's photos

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
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make buttons circular...
        // (1) Camera
        self.cameraButton.layer.cornerRadius = self.cameraButton.frame.size.width/2
        self.cameraButton.clipsToBounds = true
        // (2) Photo library
        self.photoLibrary.layer.cornerRadius = self.photoLibrary.frame.size.width/2
        self.photoLibrary.clipsToBounds = true
        // (3) Text Post
        // (2) Photo library
        self.textPost.layer.cornerRadius = self.textPost.frame.size.width/2
        self.textPost.clipsToBounds = true
        
        
        // Add tap methods...
        
        // (1) CAMERA
        let cameraTap = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        cameraTap.numberOfTapsRequired = 1
        self.cameraButton.isUserInteractionEnabled = true
        self.cameraButton.addGestureRecognizer(cameraTap)
        
        // (2) TEXT POST
        let tpTap = UITapGestureRecognizer(target: self, action: #selector(newTextPost))
        tpTap.numberOfTapsRequired = 1
        self.textPost.isUserInteractionEnabled = true
        self.textPost.addGestureRecognizer(tpTap)
        
        // (3) PHOTO LIBRARY
        let libraryTap = UITapGestureRecognizer(target: self, action: #selector(loadLibrary))
        libraryTap.numberOfTapsRequired = 1
        self.photoLibrary.isUserInteractionEnabled = true
        self.photoLibrary.addGestureRecognizer(libraryTap)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
