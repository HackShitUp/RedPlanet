//
//  EditContent.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/7/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


import SVProgressHUD

// Array 
var editObjects = [PFObject]()

class EditContent: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var textPost: UITextView!
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var completeButton: UIButton!
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    
    
    // Stylize title
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Edit"
        }
    }
    
    
    // Function to save changes
    func saveChanges(sender: UIButton) {
        
        // Show Progress
        SVProgressHUD.show()
        
        
        // Fetch object
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: editObjects.last!.objectId!)
        newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    // Found object
                    object["textPost"] = self.textPost.text!
                    object.saveInBackground(block: {
                        (success: Bool, error: Error?) in
                        if success {
                            print("Successfully saved changes")

                            // Dismiss Progress
                            SVProgressHUD.dismiss()
                            
                            // Pop view controller
                            self.navigationController!.popViewController(animated: true)
                            
                            
                            // Send to Text Post
                            NotificationCenter.default.post(name: photoNotification, object: nil)
                            
                            // Send to Photo Asset
                            NotificationCenter.default.post(name: textPostNotification, object: nil)
                            
                        } else {
                            print(error?.localizedDescription as Any)
                            
                            // Dismiss Progress
                            SVProgressHUD.dismiss()
                        }
                    })
                }
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
        })
        
        
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        
        // Set first responder
        self.textPost.becomeFirstResponder()
        
        // Add function to save changes tap
        let save = UITapGestureRecognizer(target: self, action: #selector(saveChanges))
        save.numberOfTapsRequired = 1
        self.completeButton.isUserInteractionEnabled = true
        self.completeButton.addGestureRecognizer(save)
        
        
        // Make complete button circular
        self.completeButton.layer.cornerRadius = self.completeButton.frame.size.width/2.0
        self.completeButton.clipsToBounds = true
        
        
        // Text
        if let text = editObjects.last!.value(forKey: "textPost") as? String {
            self.textPost.text! = text
        }
        
        
        // Add corner radius for thumbnail
        self.mediaAsset.layer.cornerRadius = 6.00
        self.mediaAsset.clipsToBounds = true
        
        
        // Fill in photo
        if editObjects.last!.value(forKey: "photoAsset") != nil {
            // Photo
            if let photo = editObjects.last!.value(forKeyPath: "photoAsset") as? PFFile {
                photo.getDataInBackground(block: {
                    (data: Data?, error: Error?) in
                    if error == nil {
                        // Set photo
                        self.mediaAsset.image = UIImage(data: data!)
                    } else {
                        print(error?.localizedDescription as Any)
                    }
                })
            }
            
        } else {
            // Video
            if let video = editObjects.last!.value(forKeyPath: "videoAsset") as? PFFile {
                // TODO::
                // Set video thumbnail
            }
            
        }
        
        
        
        
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
