//
//  NewProfilePhoto.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/27/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Array to hold changed profile photo
var changedProPicImg = [UIImage]()

class NewProfilePhoto: UIViewController, UITextViewDelegate, CLImageEditorDelegate {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var proPicCaption: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    
    
    // Function to handle caption
    func complete() {
        // Append caption for user to save
        if self.proPicCaption.text!.isEmpty {
            profilePhotoCaption.append(" ")
        }  else {
            profilePhotoCaption.append(self.proPicCaption.text!)
        }
        
        if self.proPicCaption.text! == "Say something about your profile photo..." {
            profilePhotoCaption.append(" ")
        }
        
        // Dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: - CLImageEditor delegate method
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        self.rpUserProPic.image = image
        editor.dismiss(animated: true, completion: { _ in })
    }
    

    // MARK: - UITextViewDelegate method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.proPicCaption.text! == "Say something about your profile photo..." {
            self.proPicCaption.text! = ""
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Get profile photo's caption
        let proPic = PFQuery(className: "ProfilePhoto")
        proPic.whereKey("fromUser", equalTo: PFUser.current()!)
        proPic.getFirstObjectInBackground(block: {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
                    // Profile Photo Exists
                    // Handle optional chaining for profile photo's caption
                    if let caption = object!["proPicCaption"] as? String {
                        if caption == " " {
                            self.proPicCaption.text! = "Say something about your profile photo..."
                        } else {
                            self.proPicCaption.text! = caption
                        }
                        
                    } else {
                        self.proPicCaption.text! = "Say something about your profile photo..."
                    }
                } else {
                    // Profile Photo DOES NOT Exist
                    self.proPicCaption.text! = "Say something about your profile photo..."
                }
                
                
            } else {
                print(error?.localizedDescription)
            }
        })
        

        // Set initial image
        self.rpUserProPic.image = changedProPicImg.last!
        
        // Set layouts
        self.rpUserProPic.layoutIfNeeded()
        self.rpUserProPic.layoutSubviews()
        self.rpUserProPic.setNeedsLayout()
        
        // Load user's current profile picture
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        self.rpUserProPic.layer.borderWidth = 0.5
        self.rpUserProPic.clipsToBounds = true
        
        // Design profile photo's borders and border colors
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
        self.rpUserProPic.layer.borderWidth = 1.0
        self.rpUserProPic.clipsToBounds = true
        
        // Design button corners
        self.doneButton.layer.cornerRadius = 2.0
        self.doneButton.clipsToBounds = true
        self.doneButton.layer.cornerRadius = 15.0
        self.doneButton.clipsToBounds = true
        
        // Set method tap to handle caption
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(complete))
        captionTap.numberOfTapsRequired = 1
        self.doneButton.isUserInteractionEnabled = true
        self.doneButton.addGestureRecognizer(captionTap)
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
