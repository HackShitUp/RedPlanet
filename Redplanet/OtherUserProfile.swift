//
//  OtherUserProfile.swift
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



// Global variable to hold other user's object
var otherObject = [PFObject]()
// Global variable to hold other user's username
var otherName = [String]()


class OtherUserProfile: UICollectionViewController, UINavigationControllerDelegate {
    

    // Other User's Friends
    var oFriends = [PFObject]()
    
    // Other User's Followers
    var oFollowers = [PFObject]()
    
    // Other User's Following
    var oFollowing = [PFObject]()
    

    
    // Variable to hold other user's space posts
    var spaceObjects = [PFObject]()
    
    
    // Function to query other user's Space Posts
    func querySpace() {
        let wall = PFQuery(className: "Wall")
        wall.whereKey("toUser", equalTo: otherObject.last!)
        wall.order(byDescending: "createdAt")
        wall.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.spaceObjects.removeAll(keepingCapacity: false)
                
                
                for object in objects! {
                    self.spaceObjects.append(object)
                }
                
                
                
            } else {
                print(error?.localizedDescription)
            }
            
            // Reload data
            self.collectionView!.reloadData()
        })
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.spaceObjects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherContentCell", for: indexPath) as! OtherContentCell
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
