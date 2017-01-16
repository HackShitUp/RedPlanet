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
var timelineVCS = [UIViewController]()

// Variable to return selected index
var returnIndex: Int? = 0

class Timeline: EZSwipeController, UINavigationControllerDelegate  {

    override func setupView() {
        datasource = self
        navigationBarShouldNotExist = false
        navigationBarShouldBeOnBottom = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.frame.origin.y = UIApplication.shared.statusBarFrame.height
        
        // Set background color
        self.view.backgroundColor = UIColor.white
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}



extension Timeline: EZSwipeControllerDataSource {
    
    func indexOfStartingPage() -> Int {
        print("\nINDEX: \(returnIndex!)\n")
        return returnIndex!
    }
    
    
    func viewControllerData() -> [UIViewController] {

        // Remove the first object
        timelineObjects.remove(at: 0)
        
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
        

        print("\nCOUNTING VCS: \(timelineVCS.count)\n")
        print("\nCOUNTING OBJECTS: \(timelineObjects.count)\n")
        return timelineVCS
    }
    
    
    
    
    // UINavigationBar DataSource
    func navigationBarDataForPageIndex(_ index: Int) -> UINavigationBar {
        
        return self.navigationController!.navigationBar
    }
    
}
