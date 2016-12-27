//
//  StackModel.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/27/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts



// Array to hold objects
var stackObjects = [PFObject]()

// Array to hold view controllers
var postControllers = [UIViewController]()

// Variable to return selected index
var returnIndex: Int? = 0

class StackModel: EZSwipeController, UINavigationControllerDelegate {
    
    // Pop vc
    func leave() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    
    override func setupView() {
        datasource = self
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color
        self.view.backgroundColor = UIColor.white
        
        // Double tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(leave))
        doubleTap.numberOfTapsRequired = 2
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(doubleTap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}




extension StackModel: EZSwipeControllerDataSource {
    
    
//    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
//        
//        var navigator: UINavigationBar!
//        
//        for i in postControllers {
//            
//            i.navigationController!.setNavigationBarHidden(true, animated: false)
//            navigator = i.navigationController!.navigationBar
//        }
//        
//        
//        return navigator
//    }
//    
    
    
//    func indexOfStartingPage() -> Int {
//        print("returning: \(returnIndex!)")
//        return returnIndex!
//    }
    
    
    
    
    
    
    func viewControllerData() -> [UIViewController] {
        
    
        
        // Loop through objects to determine which view controller to show
        for postObject in stackObjects {
            
            if postObject.value(forKey: "contentType") as! String == "tp" {
                // I) TEXT POST
                textPostObject.append(postObject)
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                // Append VC
                postControllers.append(textPostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "ph" {
                // II) PHOTO
                photoAssetObject.append(postObject)
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                // Append VC
                postControllers.append(photoVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "pp" {
                // III) PROFILE PHOTO
                proPicObject.append(postObject)
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                // Append VC
                postControllers.append(proPicVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "sh" {
                // IV) SHARED POST
                sharedObject.append(postObject)
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                // Append VC
                postControllers.append(sharedPostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "sp" {
                // V) SPACE POST
                spaceObject.append(postObject)
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                // Append VC
                postControllers.append(spacePostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "itm" {
                // VI) MOMENT
                itmObject.append(postObject)
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                // Append VC
                postControllers.append(itmVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "vi" {
                // VII) VIDEO
                videoObject.append(postObject)
                let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                // Append VC
                postControllers.append(videoVC)
                
            }
            
        }
        
        
        
//        let redVC = UIViewController()
//        redVC.view.backgroundColor = UIColor.red
//        let blueVC = UIViewController()
//        blueVC.view.backgroundColor = UIColor.blue
//        let greenVC = UIViewController()
//        greenVC.view.backgroundColor = UIColor.green
//        return [redVC, blueVC, greenVC]
        
        print("***VIEW CONTROLLERS:***\n\(postControllers)\n\n")        
        return postControllers
    }
}
