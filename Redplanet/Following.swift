//
//  Following.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/18/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet


class Following: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // Array to hold following's content
    var followingContent = [PFObject]()
    
    
    // Initialize Parent navigationController
    var parentNavigator: UINavigationController!
    
    // Query Following
    func queryFollowing() {
        
        // Show Progress
        SVProgressHUD.show()
        
        let newsfeeds = PFQuery(className: "Newsfeeds")
        newsfeeds.whereKey("byUser", containedIn: myFollowing)
        newsfeeds.order(byDescending: "createdAt")
        newsfeeds.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                // Clear array
                self.followingContent.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    self.followingContent.append(object)
                }
                
                
                // DZNEmptyDataSet
                if self.followingContent.count == 0 {
                    self.tableView!.emptyDataSetDelegate = self
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.tableFooterView = UIView()
                }
                
                
            } else {
                print(error?.localizedDescription)
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Query Following
        self.queryFollowing()
        
        // Remove lines on load
        self.tableView!.tableFooterView = UIView()
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return followingContent.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followingCell", for: indexPath) as! FollowingCell
        
        
        // Initiliaze and set parent VC
        cell.delegate = self
        
        
        // LayoutViews
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make Profile Photo Circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        // Fetch content
        followingContent[indexPath.row].fetchInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get and set user's object
                if let user = object!["byUser"] as? PFUser {
                    // (A) Set usrername
                    cell.rpUsername.text! = user["username"] as! String
                    
                    // (B) Get user's profile photo
                    if let proPic = user["userProfilePicture"] as? PFFile {
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
                    }
                    
                    // (C) Set user's object
                    cell.userObject = user
                }
                
                
                
                // (2) Determine Content Type
                if object!["mediaAsset"] == nil {
                    cell.contentType.image = UIImage(named: "Text Height-96")
                } else {
                    cell.contentType.image = UIImage(named: "Stack of Photos-96")
                }
                
                
                
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
                
                
                
                /////
                // USER FOR LATER WHEN CONTENT IS DELETED EVERY 24 HOURS
                /////
                //                let dateFormatter = DateFormatter()
                //                dateFormatter.dateFormat = "EEEE"
                //                let timeFormatter = DateFormatter()
                //                timeFormatter.dateFormat = "h:mm a"
                //                let time = "\(dateFormatter.string(from: object!.createdAt!)) \(timeFormatter.string(from: object!.createdAt!))"
                //                cell.rpTime.text! = time

                
                
                
            } else{
                print(error?.localizedDescription)
            }
        }
        

        return cell
    }
 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.followingContent[indexPath.row].value(forKey: "mediaAsset") == nil {
            
            // Show Progress
//            SVProgressHUD.show()
            
            print("Tapped")
            /*
            // Save to Views
            let view = PFObject(className: "Views")
            view["byUser"] = PFUser.current()!
            view["username"] = PFUser.current()!.username!
            view["forObjectId"] = followingContent[indexPath.row].objectId!
            view.saveInBackground(block: {
                (success: Bool, error: Error?) in
                if success {
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                    
                    
                } else {
                    print(error?.localizedDescription)
                    
                    // Dismiss Progress
                    SVProgressHUD.dismiss()
                }
            })
            */
            
            // Append Object
            textPostObject.append(self.followingContent[indexPath.row])
            
            // Present VC
            let textPostVC = self.storyboard?.instantiateViewController(withIdentifier: "textPostVC") as! TextPost
            self.parentNavigator.pushViewController(textPostVC, animated: true)
            
            
        } else {
            
            /*
             // Save to Views
             let view = PFObject(className: "Views")
             view["byUser"] = PFUser.current()!
             view["username"] = PFUser.current()!.username!
             view["forObjectId"] = followingContent[indexPath.row].objectId!
             view.saveInBackground(block: {
             (success: Bool, error: Error?) in
             if error == nil {
             
             } else {
             print(error?.localizedDescription)
             }
             })
             */
            
            
            // Append Object
            mediaAssetObject.append(self.followingContent[indexPath.row])
            
            // Present VC
            let mediaVC = self.storyboard?.instantiateViewController(withIdentifier: "mediaAssetVC") as! MediaAsset
            self.parentNavigator.pushViewController(mediaVC, animated: true)
            
        }
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
