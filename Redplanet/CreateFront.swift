//
//  CreateFront.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

class CreateFront: UIViewController {

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photoLibrary: UIButton!
    @IBOutlet weak var textPost: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Make buttons circular...
        // (1) Camera
        self.cameraButton.layer.cornerRadius = self.cameraButton.frame.size.width/2
        self.cameraButton.clipsToBounds = true
        // (2) Photo library
        self.photoLibrary.layer.cornerRadius = self.photoLibrary.frame.size.width/2
        self.photoLibrary.clipsToBounds = true
        // (3) Text Post
        // (2) Photo library
        self.textPost.layer.cornerRadius = self.textPost.frame.size.width/2
        self.textPost.clipsToBounds = true
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
