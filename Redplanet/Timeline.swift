//
//  Timeline.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/21/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


var timelineObjects = [PFObject]()
var timelineVCS = [UIViewController]()
var currentIndex: Int?

class Timeline: UIViewController, StackViewDataSource {

    @IBOutlet weak var stackPageView: StackPageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackPageView.dataSource = self
        stackPageView.parentViewController = self
        
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
        
        
        
        print("CURRENT INDEX: \(currentIndex!)")
        print("VCS: \(timelineVCS.count)")
        
        stackPageView.currentContainer.viewController = timelineVCS[0]
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stackViewNext(_ currentViewController: UIViewController?) -> UIViewController? {
        currentIndex = currentIndex! - 1
        
        return timelineVCS[1]
    }
    
    func stackViewPrev(_ currentViewController: UIViewController?) -> UIViewController? {
        currentIndex = currentIndex! + 1
        
        return timelineVCS[0]
    }
}

//class DummyViewController: UIViewController {
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.backgroundColor = getRandomColor()
//    }
//    
//    func getRandomColor() -> UIColor{
//        let randomRed:CGFloat = CGFloat(drand48())
//        let randomGreen:CGFloat = CGFloat(drand48())
//        let randomBlue:CGFloat = CGFloat(drand48())
//        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
//    }
//}
