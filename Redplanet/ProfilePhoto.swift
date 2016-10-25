//
//  ProfilePhoto.swift
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



// Define identifier
let profileNotification = Notification.Name("profileLike")


class ProfilePhoto: UITableViewController, UINavigationControllerDelegate {
    
    // Array to hold likers, and commentators
    var likes = [PFObject]()
    var comments = [PFObject]()
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: AnyObject) {
        // Reload data
        self.tableView!.reloadData()
    }
    
    
        
    // Fetch interactions
    func fetchInteractions() {
        // Likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
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
        
        // Comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: textPostObject.last!.objectId!)
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
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Profile Photo"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set tableView height
        self.tableView!.estimatedRowHeight = 540
        self.tableView!.rowHeight = UITableViewAutomaticDimension

        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: profileNotification, object: nil)
        
        // Stylize title
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "proPicCell", for: indexPath) as! ProfilePhotoCell
        
        // Declare parent VC
        cell.delegate = self


        // (1) Set likes
        if self.likes.count == 0 {
            cell.numberOfLikes.setTitle("likes", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfLikes.setTitle("1 like", for: .normal)
        } else {
            cell.numberOfLikes.setTitle("\(self.likes.count) likes", for: .normal)
        }
        
        // (1A) Manipulate likes
        if self.likes.contains(PFUser.current()!) {
            cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
            cell.likeButton.setTitle("liked", for: .normal)
        } else {
            cell.likeButton.setImage(UIImage(named: "Like-100"), for: .normal)
            cell.likeButton.setTitle("notLiked", for: .normal)
        }
        

        // (2) Count comments
        if self.comments.count == 0 {
            cell.numberOfComments.setTitle("comments", for: .normal)
        } else if self.likes.count == 1 {
            cell.numberOfComments.setTitle("1 comment", for: .normal)
        } else {
            cell.numberOfComments.setTitle("\(self.likes.count) comments", for: .normal)
        }
        
        
        return cell
    }
    



}
