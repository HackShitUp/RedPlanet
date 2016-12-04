//
//  LikesAndShares.swift
//  Redplanet
//
//  Created by Joshua Choi on 12/3/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import OneSignal
import SVProgressHUD
import DZNEmptyDataSet

class LikesAndShares: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Array to hold likes
    var likedStrings = [String]()
    
    // Array to hold liked posts
    var likedPosts = [PFObject]()
    var sharedPosts = [PFObject]()
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Fetch likes and shares again
        fetchLikesAndShares()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    // Function to fetch liked posts
    func fetchLikesAndShares() {
        let likesAndShares = PFQuery(className: "Newsfeeds")
        likesAndShares.includeKey("byUser")
        likesAndShares.includeKey("pointObject")
        likesAndShares.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear arrays
                self.likedPosts.removeAll(keepingCapacity: false)
                self.sharedPosts.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    for i in self.likedStrings {
                        if object.objectId! == i {
                            
                            // Liked
                            self.likedPosts.append(object)
                        }
                    }
                    
                    if object["contentType"] as! String == "sh" && object["byUser"] as! PFUser == PFUser.current()! {
                        // Shared
                        self.sharedPosts.append(object["pointObject"] as! PFObject)
                    }
                }
                
                
                // Set DZN
                if self.likedPosts.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
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
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Likes & Shares"
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        // Clear tableView
        self.tableView!.tableFooterView = UIView()
        
        // Show Progress
        SVProgressHUD.show()

        // Fetch likes
        let likes = PFQuery(className: "Likes")
        likes.whereKey("fromUser", equalTo: PFUser.current()!)
        likes.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.likedStrings.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.likedStrings.append(object["forObjectId"] as! String)
                }
                
                // Fetch posts
                self.fetchLikesAndShares()
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
        }
        
        
        // Back swipe implementation
        let backSwipe = UISwipeGestureRecognizer(target: self, action: #selector(backButton))
        backSwipe.direction = .right
        self.view.addGestureRecognizer(backSwipe)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // stylize title again
        configureView()
        
        // Show navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Hide tabBarController
        self.navigationController?.tabBarController?.tabBar.isHidden = true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
         if likedPosts.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "💔\nNo Likes Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Liked
            return self.likedPosts.count
        } else {
            // Shared
            return self.sharedPosts.count
        }
        
    }

    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
        label.font = UIFont(name: "AvenirNext-Medium", size: 19.00)
        
        if section == 0 {
            
            label.text = " • Liked Posts"
            return label
            
        } else {
            
            label.text = " • Shared Posts"
            return label
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44
        } else {
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "likedSharedCell", for: indexPath) as! LikesAndSharesCell

        // LayoutViews for mediaPreview
        cell.iconicPreview.layoutIfNeeded()
        cell.iconicPreview.layoutSubviews()
        cell.iconicPreview.setNeedsLayout()
        
        // Set aspectFill by default
        cell.iconicPreview.contentMode = .scaleAspectFill
        
        if indexPath.section == 0 {
            // Liked
            likedPosts[indexPath.row].fetchInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // (1) Set names
                    if let user = object!["byUser"] as? PFUser {
                        if let fullName = user["realNameOfUser"] as? String {
                            cell.rpFullName.text! = fullName
                        } else {
                            cell.rpFullName.text! = user["username"] as! String
                        }
                    }
                    
                    
                    // (2) Set iconicPreviews
                    // (2A) Text Posts
                    if object!["contentType"] as! String == "tp" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = 10.00
                        cell.iconicPreview.clipsToBounds = true
                        // Show iconicPreview
                        cell.iconicPreview.isHidden = false
                        // Set iconicPreview's icon
                        cell.iconicPreview.image = UIImage(named: "TextPostIcon")
                    }
                    
                    // (2B) Photos
                    if object!["contentType"] as! String == "ph" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = 10.00
                        cell.iconicPreview.clipsToBounds = true
                        
                        // Fetch photo
                        if let photo = object!["photoAsset"] as? PFFile {
                            photo.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                        }
                    }
                    
                    // (2C) Profile Photos
                    if object!["contentType"] as! String == "pp" {
                        // Make iconicPreview circular
                        cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.layer.frame.size.width/2
                        cell.iconicPreview.clipsToBounds = true
                        
                        
                        // Fetch Profile photo
                        if let iconicPreview = object!["photoAsset"] as? PFFile {
                            iconicPreview.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                    }
                    
                    // (2D) Space Posts
                    if object!["contentType"] as! String == "sp" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                        cell.iconicPreview.clipsToBounds = true
                        
                        // Show iconicPreview
                        cell.iconicPreview.isHidden = false
                        
                        // Set background color for iconicPreview
                        cell.iconicPreview.backgroundColor = UIColor.clear
                        // and set icon for indication
                        cell.iconicPreview.image = UIImage(named: "SpacePost")
                    }
                    
                    // (2F) Moments
                    if object!["contentType"] as! String == "itm" {
                        cell.iconicPreview.layer.cornerRadius = 0
                        cell.iconicPreview.backgroundColor = UIColor.clear
                        cell.iconicPreview.contentMode = .scaleAspectFit
                        cell.iconicPreview.clipsToBounds = true
                        
                        
                        // Fetch photo
                        if let itm = object!["photoAsset"] as? PFFile {
                            itm.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                    }
                    
                    
                    // (3) Set time
                    let from = object!.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        cell.time.text = "right now"
                    }
                    
                    if difference.second! > 0 && difference.minute! == 0 {
                        if difference.second! == 1 {
                            cell.time.text = "1 second ago"
                        } else {
                            cell.time.text = "\(difference.second!) seconds ago"
                        }
                    }
                    
                    if difference.minute! > 0 && difference.hour! == 0 {
                        if difference.minute! == 1 {
                            cell.time.text = "1 minute ago"
                        } else {
                            cell.time.text = "\(difference.minute!) minutes ago"
                        }
                    }
                    
                    if difference.hour! > 0 && difference.day! == 0 {
                        if difference.hour! == 1 {
                            cell.time.text = "1 hour ago"
                        } else {
                            cell.time.text = "\(difference.hour!) hours ago"
                        }
                    }
                    
                    if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        if difference.day! == 1 {
                            cell.time.text = "1 day ago"
                        } else {
                            cell.time.text = "\(difference.day!) days ago"
                        }
                    }
                    
                    if difference.weekOfMonth! > 0 {
                        let createdDate = DateFormatter()
                        createdDate.dateFormat = "MMM d, yyyy"
                        cell.time.text = createdDate.string(from: object!.createdAt!)
                    }

                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
            
        } else {
            // Shared
            sharedPosts[indexPath.row].fetchIfNeededInBackground(block: {
                (object: PFObject?, error: Error?) in
                if error == nil {
                    
                    // (1) Set names
                    if let user = object!["byUser"] as? PFUser {
                        if let fullName = user["realNameOfUser"] as? String {
                            cell.rpFullName.text! = fullName
                        } else {
                            cell.rpFullName.text! = user["username"] as! String
                        }
                    }

                    
                    // (2) Set iconicPreviews
                    // (2A) Text Posts
                    if object!["contentType"] as! String == "tp" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = 10.00
                        cell.iconicPreview.clipsToBounds = true
                        // Show iconicPreview
                        cell.iconicPreview.isHidden = false
                        // Set iconicPreview's icon
                        cell.iconicPreview.image = UIImage(named: "TextPostIcon")
                    }
                    
                    // (2B) Photos
                    if object!["contentType"] as! String == "ph" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = 10.00
                        cell.iconicPreview.clipsToBounds = true
                        
                        // Fetch photo
                        if let photo = object!["photoAsset"] as? PFFile {
                            photo.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                            
                        }
                    }
                    
                    // (2C) Profile Photos
                    if object!["contentType"] as! String == "pp" {
                        // Make iconicPreview circular
                        cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.layer.frame.size.width/2
                        cell.iconicPreview.clipsToBounds = true
                        
                        
                        // Fetch Profile photo
                        if let iconicPreview = object!["photoAsset"] as? PFFile {
                            iconicPreview.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                    }
                    
                    // (2D) Space Posts
                    if object!["contentType"] as! String == "sp" {
                        // Make iconicPreview cornered square
                        cell.iconicPreview.layer.cornerRadius = cell.iconicPreview.frame.size.width/2
                        cell.iconicPreview.clipsToBounds = true
                        
                        // Show iconicPreview
                        cell.iconicPreview.isHidden = false
                        
                        // Set background color for iconicPreview
                        cell.iconicPreview.backgroundColor = UIColor.clear
                        // and set icon for indication
                        cell.iconicPreview.image = UIImage(named: "SpacePost")
                    }
                    
                    // (2F) Moments
                    if object!["contentType"] as! String == "itm" {
                        cell.iconicPreview.layer.cornerRadius = 0
                        cell.iconicPreview.backgroundColor = UIColor.clear
                        cell.iconicPreview.contentMode = .scaleAspectFit
                        cell.iconicPreview.clipsToBounds = true
                        
                        
                        // Fetch photo
                        if let itm = object!["photoAsset"] as? PFFile {
                            itm.getDataInBackground(block: {
                                (data: Data?, error: Error?) in
                                if error == nil {
                                    
                                    // Show iconicPreview
                                    cell.iconicPreview.isHidden = false
                                    // Set media
                                    cell.iconicPreview.image = UIImage(data: data!)
                                    
                                } else {
                                    print(error?.localizedDescription as Any)
                                }
                            })
                        }
                    }
                    
                    
                    // (3) Set time
                    let from = object!.createdAt!
                    let now = Date()
                    let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
                    let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
                    
                    // logic what to show : Seconds, minutes, hours, days, or weeks
                    if difference.second! <= 0 {
                        cell.time.text = "right now"
                    }
                    
                    if difference.second! > 0 && difference.minute! == 0 {
                        if difference.second! == 1 {
                            cell.time.text = "1 second ago"
                        } else {
                            cell.time.text = "\(difference.second!) seconds ago"
                        }
                    }
                    
                    if difference.minute! > 0 && difference.hour! == 0 {
                        if difference.minute! == 1 {
                            cell.time.text = "1 minute ago"
                        } else {
                            cell.time.text = "\(difference.minute!) minutes ago"
                        }
                    }
                    
                    if difference.hour! > 0 && difference.day! == 0 {
                        if difference.hour! == 1 {
                            cell.time.text = "1 hour ago"
                        } else {
                            cell.time.text = "\(difference.hour!) hours ago"
                        }
                    }
                    
                    if difference.day! > 0 && difference.weekOfMonth! == 0 {
                        if difference.day! == 1 {
                            cell.time.text = "1 day ago"
                        } else {
                            cell.time.text = "\(difference.day!) days ago"
                        }
                    }
                    
                    if difference.weekOfMonth! > 0 {
                        let createdDate = DateFormatter()
                        createdDate.dateFormat = "MMM d, yyyy"
                        cell.time.text = createdDate.string(from: object!.createdAt!)
                    }
                    
                    
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        
        

        return cell
    } // end cellForRowAt
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // TEXT POST
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                
                // Append Object
                textPostObject.append(self.likedPosts[indexPath.row])
                
                // Present VC
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                self.navigationController?.pushViewController(textPostVC, animated: true)
            }
            
            // PHOTO
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "ph" {
                
                // Append Object
                photoAssetObject.append(self.likedPosts[indexPath.row])
                
                // Present VC
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                self.navigationController?.pushViewController(photoVC, animated: true)
            }
            
            // SHARED
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                
                // Append object
                sharedObject.append(self.likedPosts[indexPath.row])
                // Push VC
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                self.navigationController?.pushViewController(sharedPostVC, animated: true)
                
            }
            
            // PROFILE PHOTO
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "pp" {
                // Append user's object
                otherObject.append(self.likedPosts[indexPath.row].value(forKey: "byUser") as! PFUser)
                // Append user's username
                otherName.append(self.likedPosts[indexPath.row].value(forKey: "username") as! String)
                
                // Append object
                proPicObject.append(self.likedPosts[indexPath.row])
                
                // Push VC
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                self.navigationController?.pushViewController(proPicVC, animated: true)
                
            }
            
            
            // SPACE POST
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                // Append object
                spaceObject.append(self.likedPosts[indexPath.row])
                
                // Append otherObject
                otherObject.append(self.likedPosts[indexPath.row].value(forKey: "toUser") as! PFUser)
                
                // Append otherName
                otherName.append(self.likedPosts[indexPath.row].value(forKey: "toUsername") as! String)
                
                // Push VC
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                self.navigationController?.pushViewController(spacePostVC, animated: true)
            }
            
            // ITM
            if self.likedPosts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                // Append content object
                itmObject.append(self.likedPosts[indexPath.row])
                
                // Push VC
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                self.navigationController?.pushViewController(itmVC, animated: true)
            }
        } else {
            // Shared Posts
            
            
            // TEXT POST
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "tp" {
                
                // Append Object
                textPostObject.append(self.sharedPosts[indexPath.row])
                
                // Present VC
                let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
                self.navigationController?.pushViewController(textPostVC, animated: true)
            }
            
            // PHOTO
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "ph" {
                
                // Append Object
                photoAssetObject.append(self.sharedPosts[indexPath.row])
                
                // Present VC
                let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "photoAssetVC") as! PhotoAsset
                self.navigationController?.pushViewController(photoVC, animated: true)
            }
            
            // SHARED
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "sh" {
                
                // Append object
                sharedObject.append(self.sharedPosts[indexPath.row])
                // Push VC
                let sharedPostVC = self.storyboard?.instantiateViewController(withIdentifier: "sharedPostVC") as! SharedPost
                self.navigationController?.pushViewController(sharedPostVC, animated: true)
                
            }
            
            // PROFILE PHOTO
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "pp" {
                // Append user's object
                otherObject.append(self.sharedPosts[indexPath.row].value(forKey: "byUser") as! PFUser)
                // Append user's username
                otherName.append(self.sharedPosts[indexPath.row].value(forKey: "username") as! String)
                
                // Append object
                proPicObject.append(self.sharedPosts[indexPath.row])
                
                // Push VC
                let proPicVC = self.storyboard?.instantiateViewController(withIdentifier: "profilePhotoVC") as! ProfilePhoto
                self.navigationController?.pushViewController(proPicVC, animated: true)
                
            }
            
            
            // SPACE POST
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "sp" {
                // Append object
                spaceObject.append(self.sharedPosts[indexPath.row])
                
                // Append otherObject
                otherObject.append(self.sharedPosts[indexPath.row].value(forKey: "toUser") as! PFUser)
                
                // Append otherName
                otherName.append(self.sharedPosts[indexPath.row].value(forKey: "toUsername") as! String)
                
                // Push VC
                let spacePostVC = self.storyboard?.instantiateViewController(withIdentifier: "spacePostVC") as! SpacePost
                self.navigationController?.pushViewController(spacePostVC, animated: true)
            }
            
            // ITM
            if self.sharedPosts[indexPath.row].value(forKey: "contentType") as! String == "itm" {
                // Append content object
                itmObject.append(self.sharedPosts[indexPath.row])
                
                // Push VC
                let itmVC = self.storyboard?.instantiateViewController(withIdentifier: "itmVC") as! InTheMoment
                self.navigationController?.pushViewController(itmVC, animated: true)
            }
        }
        
    } // end didSelectRow
    

    

}
