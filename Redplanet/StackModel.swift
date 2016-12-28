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

    
    override func setupView() {
        datasource = self
        navigationBarShouldNotExist = false
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color
        self.view.backgroundColor = UIColor.white
        
        print("\n\nStackObjects:\n\(stackObjects)\n\n")
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide tabBarController's tabBar
        self.navigationController!.tabBarController!.tabBar.isHidden = true
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // Hide tabBarController's tabBar
        self.navigationController!.tabBarController!.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}




extension StackModel: EZSwipeControllerDataSource {
    
    
    // UINavigationBar DataSource
    func navigationBarDataForPageIndex(_ index: Int) -> UINavigationBar {

        return self.navigationController!.navigationBar
    }
    
    
    
    func indexOfStartingPage() -> Int {
        print("RETURN INDEX: \(returnIndex!)")
        return returnIndex!
    }

    
    
    
    func viewControllerData() -> [UIViewController] {
        
//        // Loop through objects to determine which view controller to show
//        for postObject in stackObjects {
//            
//            print("***STACKOBJECTS:***\(stackObjects)\n****")
//            print("***POSTOBJECT: \(postObject)")
//            
//            if postObject.value(forKey: "contentType") as! String == "tp" {
//                // I) TEXT POST
//                textPostObject.append(postObject)
//                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
//                // Append VC
//                print("TP:\(postControllers)")
//                postControllers.append(textPostVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "ph" {
//                // II) PHOTO
//                photoAssetObject.append(postObject)
//                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
//                // Append VC
//                print("PH:\(postControllers)")
//                postControllers.append(photoVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "pp" {
//                // III) PROFILE PHOTO
//                proPicObject.append(postObject)
//                otherObject.append(postObject.value(forKey: "byUser") as! PFUser)
//                otherName.append(postObject.value(forKey: "username") as! String)
//                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
//                // Append VC
//                print("PP:\(postControllers)")
//                postControllers.append(proPicVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "sh" {
//                // IV) SHARED POST
//                sharedObject.append(postObject)
//                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
//                // Append VC
//                print("SH:\(postControllers)")
//                postControllers.append(sharedPostVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "sp" {
//                // V) SPACE POST
//                spaceObject.append(postObject)
//                otherObject.append(postObject.value(forKey: "toUser") as! PFUser)
//                otherName.append(postObject.value(forKey: "toUsername") as! String)
//                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
//                // Append VC
//                print("SP:\(postControllers)")
//                postControllers.append(spacePostVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "itm" {
//                // VI) MOMENT
//                itmObject.append(postObject)
//                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
//                // Append VC
//                print("ITM:\(postControllers)")
//                postControllers.append(itmVC)
//                
//            } else if postObject.value(forKey: "contentType") as! String == "vi" {
//                // VII) VIDEO
//                videoObject.append(postObject)
//                let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
//                // Append VC
//                print("VI:\(postControllers)")
//                postControllers.append(videoVC)
//                
//            }
//            
//        }

        
        print("***VIEW CONTROLLERS:***\n\(postControllers)\n\n")        
        return postControllers
    }
}
