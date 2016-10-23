//
//  NewTextPost.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Social

import Parse
import ParseUI
import Bolts

// #ff004f

class NewTextPost: UIViewController, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Dismiss VC
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var fbShare: UIButton!
    @IBOutlet weak var twitterShare: UIButton!
    
    // Share
    func postTextPost() {
        let newsfeeds = PFObject(className: "Newsfeeds")
        newsfeeds["byUser"]  = PFUser.current()!
        newsfeeds["username"] = PFUser.current()!.username!
        newsfeeds["textPost"] = self.textView!.text!
        newsfeeds.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                print("Saved \(newsfeeds)")
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "New Text Post"
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Stylize title
        configureView()
        
        // Set textView to first responder
        self.textView!.becomeFirstResponder()
        
        // Tap to save
        let tap = UITapGestureRecognizer(target: self, action: #selector(postTextPost))
        tap.numberOfTapsRequired = 1
        self.shareButton.isUserInteractionEnabled = true
        self.shareButton.addGestureRecognizer(tap)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if self.textView!.text! == "What are you doing?" {
            self.textView.text! = ""
        }
    }


}
