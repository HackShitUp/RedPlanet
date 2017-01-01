//
//  Timeline.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/31/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Array to hold objects
var timelineObjects = [PFObject]()

// Array to hold view controllers
var postControllers = [UIViewController]()

var timelineVCS = [UIViewController]()

// Variable to return selected index
var returnIndex: Int? = 0

class Timeline: EZSwipeController, UINavigationControllerDelegate  {

    override func setupView() {
        datasource = self
        navigationBarShouldNotExist = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color
        self.view.backgroundColor = UIColor.white
        
        
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}



/*
 if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "tp" {
 
 // Append Object
 textPostObject.append(self.friendsContent[indexPath.row])
 
 // Present VC
 let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
 postControllers.append(textPostVC)
 
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "ph" {
 
 // Append Object
 photoAssetObject.append(self.friendsContent[indexPath.row])
 
 // Present VC
 let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
 postControllers.append(photoVC)
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "sh" {
 
 // Append object
 sharedObject.append(self.friendsContent[indexPath.row])
 
 // Push VC
 let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
 postControllers.append(sharedPostVC)
 
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "pp" {
 // Append user's object
 otherObject.append(self.friendsContent[indexPath.row].value(forKey: "byUser") as! PFUser)
 // Append user's username
 otherName.append(self.friendsContent[indexPath.row].value(forKey: "username") as! String)
 
 // Append object
 proPicObject.append(self.friendsContent[indexPath.row])
 
 // Push VC
 let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
 postControllers.append(proPicVC)
 
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "sp" {
 // Append object
 spaceObject.append(self.friendsContent[indexPath.row])
 
 // Append otherObject
 otherObject.append(self.friendsContent[indexPath.row].value(forKey: "toUser") as! PFUser)
 
 // Append otherName
 otherName.append(self.friendsContent[indexPath.row].value(forKey: "toUsername") as! String)
 
 // Push VC
 let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
 postControllers.append(spacePostVC)
 
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "itm" {
 // Append content object
 itmObject.append(self.friendsContent[indexPath.row])
 
 // Push VC
 let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
 postControllers.append(itmVC)
 
 } else if self.friendsContent[indexPath.row].value(forKey: "contentType") as! String == "vi" {
 // Append content object
 videoObject.append(self.friendsContent[indexPath.row])
 
 // Push VC
 let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
 postControllers.append(videoVC)
 }
 */



extension Timeline: EZSwipeControllerDataSource {
    
    
    // UINavigationBar DataSource
    func navigationBarDataForPageIndex(_ index: Int) -> UINavigationBar {
        
        return self.navigationController!.navigationBar
    }
    
    
    
    func indexOfStartingPage() -> Int {
        
        return returnIndex!
    }
    
    

    
    
    func viewControllerData() -> [UIViewController] {
        
        // Loop through objects to determine which view controller to show
        for postObject in timelineObjects {
            if postObject.value(forKey: "contentType") as! String == "tp" {
                // I) TEXT POST
                textPostObject.append(postObject)
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                // Append VC
                timelineVCS.append(textPostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "ph" {
                // II) PHOTO
                photoAssetObject.append(postObject)
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                // Append VC
                timelineVCS.append(photoVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "pp" {
                // III) PROFILE PHOTO
                proPicObject.append(postObject)
                otherObject.append(postObject.value(forKey: "byUser") as! PFUser)
                otherName.append(postObject.value(forKey: "username") as! String)
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                // Append VC
                timelineVCS.append(proPicVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "sh" {
                // IV) SHARED POST
                sharedObject.append(postObject)
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                // Append VC
                timelineVCS.append(sharedPostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "sp" {
                // V) SPACE POST
                spaceObject.append(postObject)
                otherObject.append(postObject.value(forKey: "toUser") as! PFUser)
                otherName.append(postObject.value(forKey: "toUsername") as! String)
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                // Append VC
                timelineVCS.append(spacePostVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "itm" {
                // VI) MOMENT
                itmObject.append(postObject)
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                // Append VC
                timelineVCS.append(itmVC)
                
            } else if postObject.value(forKey: "contentType") as! String == "vi" {
                // VII) VIDEO
                videoObject.append(postObject)
                let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "videoVC") as! VideoAsset
                // Append VC
                timelineVCS.append(videoVC)
                
            }

        }
        
        
        /*
        textPostObject.removeAll(keepingCapacity: false)
        photoAssetObject.removeAll(keepingCapacity: false)
        proPicObject.removeAll(keepingCapacity: false)
        sharedObject.removeAll(keepingCapacity: false)
        spaceObject.removeAll(keepingCapacity: false)
        otherObject.removeAll(keepingCapacity: false)
        otherName.removeAll(keepingCapacity: false)
        itmObject.removeAll(keepingCapacity: false)
        videoObject.removeAll(keepingCapacity: false)
        
        print("\nTP_OBJECT:\(textPostObject)\n")
        print("\nPH_OBJECT:\(photoAssetObject)\n")
        print("\nSH_OBJECT:\(sharedObject)\n")
        print("\nSP_OBJECT:\(spaceObject)\n")
        print("\nPP_OBJECT:\(proPicObject)\n")
        print("\nITM_OBJECT:\(itmObject)\n")
        print("\nVI_OBJECT:\(videoObject)\n")
        */
        
        
        print("TIMELINEVCS: \(timelineVCS)")
        return timelineVCS
    }
    
    
}
