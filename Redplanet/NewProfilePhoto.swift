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


import SVProgressHUD


// Array to hold changed profile photo
var changedProPicImg = [UIImage]()

class NewProfilePhoto: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLImageEditorDelegate {

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var proPicCaption: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func edit(_ sender: AnyObject) {
        // MARK: - CLImageEditor
        let editor = CLImageEditor(image: self.rpUserProPic.image!)
        editor?.theme.toolbarTextFont = UIFont(name: "AvenirNext-Medium", size: 12.00)
        editor?.delegate = self
        let tool = editor?.toolInfo.subToolInfo(withToolName: "CLEmoticonTool", recursive: false)
        tool?.title = "Emoji"
        self.present(editor!, animated: true, completion: nil)
    }
    
    
    
    // MARK: - CLImageEditor
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        // Set image
        self.rpUserProPic.image = image
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    func imageEditorDidCancel(_ editor: CLImageEditor) {
        // Dismiss view controller
        editor.dismiss(animated: true, completion: { _ in })
    }
    
    
    
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
    

    // MARK: - UITextViewDelegate method
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.proPicCaption.text! == "Say something about your profile photo..." {
            self.proPicCaption.text! = ""
        }
    }
    
    
    func textViewDidChange(_ textView: UITextView) -> Bool {
        // Set bool for caption
        didChangeCaption = true
        
        return didChangeCaption
    }
    

    // Function to zoom
    func zoom(sender: AnyObject) {
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpUserProPic.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self)
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
            self.title = "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)'s Profile Photo"
        }
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // If NOT NEW Profile Photo, don't set caption
        if isNewProPic == false {
            
            // Get profile photo's caption
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
            newsfeeds.whereKey("contentType", equalTo: "pp")
            newsfeeds.order(byDescending: "createdAt")
            newsfeeds.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
                        // Profile Photo Exists
                        // Handle optional chaining for profile photo's caption
                        if let caption = object!["textPost"] as? String {
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
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            self.proPicCaption.text! = "Say something about your profile photo..."
        }
        
        
        
        
        
        
        // Stylize title
        configureView()
        

        // Set initial image
        self.rpUserProPic.image = changedProPicImg.last!
        
        // MARK: - RPHelpers extension
        self.rpUserProPic.makeCircular(imageView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // Design profile photo's borders and border colors
        self.rpUserProPic.layer.cornerRadius = self.rpUserProPic.frame.size.width/2
        self.rpUserProPic.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
        self.rpUserProPic.layer.borderWidth = 1.00
        self.rpUserProPic.clipsToBounds = true
        
        // Design button corners
        self.doneButton.layer.cornerRadius = 25.00
        self.doneButton.clipsToBounds = true
        
        // Set method tap to handle caption
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(complete))
        captionTap.numberOfTapsRequired = 1
        self.doneButton.isUserInteractionEnabled = true
        self.doneButton.addGestureRecognizer(captionTap)
        
        // Add method tap to zoom
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(zoomTap)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // If NOT NEW Profile Photo, don't set caption
        if isNewProPic == false {
            
            // Get profile photo's caption
            let newsfeeds = PFQuery(className: "Newsfeeds")
            newsfeeds.whereKey("byUser", equalTo: PFUser.current()!)
            newsfeeds.whereKey("contentType", equalTo: "pp")
            newsfeeds.order(byDescending: "createdAt")
            newsfeeds.getFirstObjectInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    if PFUser.current()!.value(forKey: "proPicExists") as! Bool == true {
                        // Profile Photo Exists
                        // Handle optional chaining for profile photo's caption
                        if let caption = object!["textPost"] as? String {
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
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            self.proPicCaption.text! = "Say something about your profile photo..."
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Append caption for user to save
        if self.proPicCaption.text!.isEmpty {
            profilePhotoCaption.append(" ")
        }  else {
            profilePhotoCaption.append(self.proPicCaption.text!)
        }
        
        if self.proPicCaption.text! == "Say something about your profile photo..." {
            profilePhotoCaption.append(" ")
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
