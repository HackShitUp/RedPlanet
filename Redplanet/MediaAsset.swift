//
//  MediaAsset.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


// Global array to hold the object
var mediaAssetObject = [PFObject]()

class MediaAsset: UITableViewController, UINavigationControllerDelegate {
    
    
    // Arrays to hold likes and comments
    var likes = [PFObject]()
    var comments = [PFObject]()

    @IBAction func backButton(_ sender: AnyObject) {
        // Dismiss
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // Fetch interactions
    func fetchInteractions() {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: mediaAssetObject.last!.objectId!)
        likes.order(byDescending: "createdAt")
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.likes.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likes.append(object)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
        
        
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: mediaAssetObject.last!.objectId!)
        comments.order(byDescending: "createdAt")
        comments.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.comments.removeAll(keepingCapacity: false)
                
                // Append objects
                for object in objects! {
                    self.comments.append(object)
                }
                
            } else {
                print(error?.localizedDescription)
            }
            
            
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fetch interactions
        fetchInteractions()
        
        // Show navigationbar
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        // Set estimated row height
        self.tableView!.estimatedRowHeight = 180
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Reload data
        self.tableView!.reloadData()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()

        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController!.interactivePopGestureRecognizer!.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaAssetCell", for: indexPath) as! MediaAssetCell

        // Get Media Asset Object
        mediaAssetObject.last!.fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                if let media = object!["mediaAsset"] as? PFFile {
                    media.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // set media asset
                            cell.rpMedia.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription)
                        }
                    })
                }
            } else {
                print(error?.localizedDescription)
            }
        }

        return cell
    }
    



}
