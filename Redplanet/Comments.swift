//
//  Comments.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/25/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet


// Array to hold comments
var commentsObject = [PFObject]()

class Comments: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold comment objects
    var comments = [PFObject]()
    
    // Array to hold likers
    var likers = [PFObject]()
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var newComment: UITextView!
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop view controller
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
    }
    
    
    // Query comments
    func queryComments() {
        // Show Progress
        SVProgressHUD.show()
        
        // Fetch comments
        let comments = PFQuery(className: "Comments")
        comments.whereKey("forObjectId", equalTo: commentsObject.last!.objectId!)
        comments.order(byDescending: "createdAt")
        comments.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.comments.removeAll(keepingCapacity: false)
                
                
                for object in objects! {
                    self.comments.append(object)
                }
            } else {
                print(error?.localizedDescription)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            
            // Reload data
            self.tableView!.reloadData()
        })
    }
    
    
    
    
    // Send comment
    func sendComment() {
        let comments = PFObject(className: "Comments")
        comments["byUser"] = PFUser.current()!
        comments["byUsername"] = PFUser.current()!.username!
        comments["commentOfContent"] = self.newComment.text!
        comments["forObjectId"] = commentsObject.last!.objectId!
        comments["toUser"] = commentsObject.last!.value(forKey: "byUser") as! PFUser
        comments["to"] = commentsObject.last!.value(forKey: "to") as! String
        comments.saveInBackground {
            (success: Bool, error: Error?) in
            if success {
                print("Successfully saved comment: \(comments)")
                // Clear text
                self.newComment.text! = ""
                
                // TODO::
                // Send notification?
             
                
                
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 20.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.navigationController?.navigationBar.topItem?.title = "Comments"
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Query Comments
        queryComments()
        
        // Stylize navigation bar
        configureView()
        
        // Make tableview free-lined
        self.tableView!.tableFooterView = UIView()
        
        // Hide navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Stylize navigation bar
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        // Stylize navigation bar
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - UITextViewDelegate Method
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Clear placeholder
        self.newComment.text! = ""
    }
    
    

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            // Send comment
            sendComment()
            
            return false
        }
        
        
        return true
    }
    
    
    
    
    // MARK: - UITableViewDataSource  Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView!.dequeueReusableCell(withIdentifier: "commentsCell", for: indexPath) as! CommentsCell
        
        // Fetch comments objects
        comments[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Fetch user
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set username
                    cell.rpUsername.setTitle("\(user["username"] as! String)", for: .normal)
                    
                    // (B) Get and set profile photo
                    if let proPic = object!["userProfilePicture"] as? PFFile {
                        proPic.getDataInBackground(block: {
                            (data: Data?, error: Error?) in
                            if error == nil {
                                // Set profile photo
                                cell.rpUserProPic.image = UIImage(data: data!)
                            } else {
                                print(error?.localizedDescription)
                                // Set default
                                cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                            }
                        })
                    } else {
                        // Set default
                        cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                    }
                }
                
                
                // (2) Set comment
                cell.comment.text! = object!["commentOfContent"] as! String

                
                // (3) Set time
                let from = object!.createdAt!
                let now = Date()
                let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                
                // logic what to show : Seconds, minutes, hours, days, or weeks
                if difference.second! <= 0 {
                    cell.time.text = "now"
                }
                
                if difference.second! > 0 && difference.minute! == 0 {
                    cell.time.text = "\(difference.second!)s ago"
                }
                
                if difference.minute! > 0 && difference.hour! == 0 {
                    cell.time.text = "\(difference.minute!)m ago"
                }
                
                if difference.hour! > 0 && difference.day! == 0 {
                    cell.time.text = "\(difference.hour!)h ago"
                }
                
                if difference.day! > 0 && difference.weekOfMonth! == 0 {
                    cell.time.text = "\(difference.day!)d ago"
                }
                
                if difference.weekOfMonth! > 0 {
                    cell.time.text = "\(difference.weekOfMonth!)w ago"
                }
                
                
                // (4) Set count title for likes
                let likes = PFQuery(className: "Likes")
                likes.includeKey("fromUser")
                likes.whereKey("forObjectId", equalTo: self.comments[indexPath.row].objectId!)
                likes.findObjectsInBackground(block: {
                    (objects: [PFObject]?, error: Error?) in
                    if error == nil {
                        // Clear arrays
                        self.likers.removeAll(keepingCapacity: false)
                        
                        for object in objects! {
                            self.likers.append(object["fromUser"] as! PFUser)
                        }
                    } else {
                        print(error?.localizedDescription)
                    }
                    
                    // Set number of likes
                    cell.numberOfLikes.text! = "\(self.likers.count)"
                    
                    
                    // Check whether user has liked it or not
                    if self.likers.contains(PFUser.current()!) {
                        // unlike
                        cell.likeButton.setTitle("liked", for: .normal)
                        cell.likeButton.setImage(UIImage(named: "Like Filled-100"), for: .normal)
                    } else {
                        // like
                        cell.likeButton.setTitle("notliked", for: .normal)
                        cell.likeButton.setTitle("Like-100", for: .normal)
                    }
                    
                    
                })
                
                
            } else {
                print(error?.localizedDescription)
            }
        }
        
        return cell
    }
    



}
