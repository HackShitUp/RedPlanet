//
//  ShareMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/29/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Photos
import PhotosUI
import AVFoundation

import Parse
import ParseUI
import Bolts


// Array to hold photo from library
var shareMediaAsset = [PHAsset]()

// When taken photo w RPCamera
var shareImageAssets = [UIImage]()



class ShareMedia: UIViewController, UINavigationControllerDelegate, CLImageEditorDelegate, CLImageEditorTransitionDelegate {
    
    @IBOutlet weak var mediaAsset: PFImageView!
    @IBOutlet weak var mediaCaption: UITextView!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    @IBAction func editPhoto(_ sender: AnyObject) {
        // Present CLImageEditor
        let editor = CLImageEditor(image: self.mediaAsset.image!)
        editor?.delegate = self
        self.present(editor!, animated: true, completion: nil)
    }
    
    // MARK: - CLImageEditorDelegate
    func imageEditor(_ editor: CLImageEditor, didFinishEdittingWith image: UIImage) {
        self.mediaAsset.image = image
        editor.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.mediaAsset.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
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
            self.title = "New Photo"
        }
    }
    
    
    // Function to save photo
    func savePhoto() {
        UIView.animate(withDuration: 0.5) { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.10, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
            
            self.saveButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI * 2))
            }, completion: nil)
        
        UIImageWriteToSavedPhotosAlbum(self.mediaAsset.image!, self, nil, nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // (1) Make shareButton circular
        self.shareButton.layer.cornerRadius = self.shareButton.frame.size.width/2
        self.shareButton.layer.borderColor = UIColor.lightGray.cgColor
        self.shareButton.layer.borderWidth = 0.5
        self.shareButton.clipsToBounds = true
        
        
        // (2) Add rounded corners and set clip within bounds
        self.mediaAsset.layer.cornerRadius = 6.0
        self.mediaAsset.layer.borderColor = UIColor.white.cgColor
        self.mediaAsset.layer.borderWidth = 0.5
        self.mediaAsset.clipsToBounds = true
        
        
        // (3) Set image
        // Set Image Request Options
        // Cancel pixelation
        // with Synchronous call
        let imageOptions = PHImageRequestOptions()
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.resizeMode = .exact
        imageOptions.isSynchronous = true
        // Set preferred size
        let targetSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        
        // Check whether the image was...
        // (A) Taken
        // (B) Selected from collection or photo library
        // Then, set image
        if shareMediaAsset.count != 0 {
            PHImageManager.default().requestImage(for: shareMediaAsset.last!,
                                                                 targetSize: targetSize,
                                                                 contentMode: .aspectFill,
                                                                 options: nil) {
                                                                    (img, _) -> Void in
                                                                    // Set image
                                                                    // Selected from library
                                                                    self.mediaAsset.image = img
            }
        } else {
            
            // Set image
            // Taken with RP Camera
            self.mediaAsset.image = shareImageAssets.last!
        }
        
        
        // (4) Stylize title
        configureView()
        
        
        // (5) Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.mediaAsset.isUserInteractionEnabled = true
        self.mediaAsset.addGestureRecognizer(zoomTap)
        
        // (6) Add tap to save photo
        let saveTap = UITapGestureRecognizer(target: self, action: #selector(savePhoto))
        saveTap.numberOfTapsRequired = 1
        self.saveButton.isUserInteractionEnabled = true
        self.saveButton.addGestureRecognizer(saveTap)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
}
