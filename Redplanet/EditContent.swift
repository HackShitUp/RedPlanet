//
//  EditContent.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/7/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Array 
var editObjects = [PFObject]()

class EditContent: UIViewController {
    
    
    // Array to hold fetched content
    var editContent = [PFObject]()
    
    // Function to fetch content
    func fetchContent() {
        
        // Fetch content
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("objectId", equalTo: editObjects.last!.objectId!)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear Arrays
                self.editContent.remove
                
                for object in objects! {
                    
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fi
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
