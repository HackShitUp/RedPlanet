//
//  CapturedVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

// Video URL
var capturedURLS = [URL]()

class CapturedVideo: UIViewController, PlayerDelegate {
    
    // Initializae Player
    var player: Player!
    
    @IBOutlet weak var exitButton: UIButton!
    @IBAction func leave(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: false)
    }
    @IBOutlet weak var continueButton: UIButton!
    @IBAction func continueAction(_ sender: Any) {
        
        // Traverse url to Data
        let tempImage = capturedURLS.last! as NSURL?
        _ = tempImage?.relativePath
        let videoData = NSData(contentsOfFile: (tempImage?.relativePath!)!)
        
        // Save video to
        let newsfeeds = PFObject(className: "Newsfeeds")
        newsfeeds["byUser"] = PFUser.current()!
        newsfeeds["username"] = PFUser.current()!.username!
        newsfeeds["contentType"] = "itm"
        newsfeeds["videoAsset"] = PFFile(name: "video.mp4", data: videoData! as Data)
        newsfeeds.saveInBackground {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully saved")
                
                // Send Notification
                NotificationCenter.default.post(name: friendsNewsfeed, object: nil)
                
                // Push Show MasterTab
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let masterTab = storyboard.instantiateViewController(withIdentifier: "theMasterTab") as! UITabBarController
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
                UIApplication.shared.keyWindow?.rootViewController = masterTab
                
            } else {
                print(error?.localizedDescription as Any)
                
                
            }
        }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player = Player()
        self.player.delegate = self
        self.player.view.frame = self.view.bounds
        
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParentViewController: self)
        
        self.player.setUrl(capturedURLS.last!)
        self.player.fillMode = "AVLayerVideoGravityResizeAspect"
        self.player.playFromBeginning()
        
        // Add tap method to pause and play again
        let pauseTap = UITapGestureRecognizer(target: self, action: #selector(player.playFromBeginning))
        pauseTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(pauseTap)
        
        self.view.bringSubview(toFront: self.exitButton)
        self.view.bringSubview(toFront: self.continueButton)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
