//
//  NewMedia.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit
import Photos

import Parse
import ParseUI
import Bolts

import OneSignal
import SwipeNavigationController

class NewMedia: UIViewController {
    
    // MARK: - Class Variables
    var mediaType = String()
    var mediaAsset = PHAsset()
    var mediaURL: URL?
    
    
    
    // MARK: - UIView Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check mediaType
        if self.mediaType == "photo" {
            
        } else if self.mediaType == "video" {
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
