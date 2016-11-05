//
//  Views.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/23/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import DZNEmptyDataSet


// Array to hold views
var viewsObject = [PFObject]()


class Views: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    // Array to hold objects
    var viewers = [PFObject]()
    
    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func refresh(_ sender: Any) {
        // Query views
        queryViews()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Query views
    func queryViews() {
        
        // Query Views
        let views = PFQuery(className: "Views")
        views.whereKey("forObjectId", equalTo: viewsObject.last!.objectId!)
        views.includeKey("byUser")
        views.order(byDescending: "createdAt")
        views.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss progress
                SVProgressHUD.dismiss()
                
                // Clear array
                viewsObject.removeAll(keepingCapacity: false)
                
                
                // Append objects
                for object in objects! {
                    if self.viewers.contains(object) || object["byUser"] as! PFUser == PFUser.current()! {
                        print("Already exists: \(object)")
                    } else {
                        self.viewers.append(object["byUser"] as! PFUser)
                    }
                }
                
                
                // Set DZNEmptyDataSet
                if self.viewers.count == 0 {
                    self.tableView!.emptyDataSetSource = self
                    self.tableView!.emptyDataSetDelegate = self
                }
                
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Dismiss progress
                SVProgressHUD.dismiss()
            }
            
            // Reload data
            self.tableView!.reloadData()
        }
    }
    
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Views"
        }
    }
    
    
    
    
    // MARK: DZNEmptyDataSet Framework
    // DataSource Methods
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if self.viewers.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "🙈\nNo Views Yet"
        let font = UIFont(name: "AvenirNext-Medium", size: 30.00)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Query views
        queryViews()
        
        // Show progress
        SVProgressHUD.show()
        
        // Stylize title
        configureView()
        
        // Set tablefooter view
        self.tableView!.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Stylize title again
        configureView()
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
        return self.viewers.count
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "viewsCell", for: indexPath) as! ViewsCell
        
        
        // Layout views
        cell.rpUserProPic.layoutIfNeeded()
        cell.rpUserProPic.layoutSubviews()
        cell.rpUserProPic.setNeedsLayout()
        
        // Make profile photo circular
        cell.rpUserProPic.layer.cornerRadius = cell.rpUserProPic.frame.size.width/2
        cell.rpUserProPic.layer.borderColor = UIColor.lightGray.cgColor
        cell.rpUserProPic.layer.borderWidth = 0.5
        cell.rpUserProPic.clipsToBounds = true
        
        
        
        // Fetch users
        self.viewers[indexPath.row].fetchIfNeededInBackground {
            (object: PFObject?, error: Error?) in
            if error == nil {
                // (1) Get and set user's profile photo
                if let proPic = object!["userProfilePicture"] as? PFFile {
                    proPic.getDataInBackground(block: {
                        (data: Data?, error: Error?) in
                        if error == nil {
                            // Set user's proPic
                            cell.rpUserProPic.image = UIImage(data: data!)
                        } else {
                            print(error?.localizedDescription as Any)
                            // set default
                            cell.rpUserProPic.image = UIImage(named: "Gender Neutral User-96")
                        }
                    })
                }
                
                
                // (2) Set username
                cell.rpUsername.text! = object!["username"] as! String
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }

        

        return cell
    }
    
    
    
    // MARK: - UITableview delegate method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Append user's object
        otherObject.append(self.viewers[indexPath.row])
        // Append user's username
        otherName.append(self.viewers[indexPath.row].value(forKey: "username") as! String)
        
        // Push VC
        let otherVC = self.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUserProfile
        self.navigationController?.pushViewController(otherVC, animated: true)
    }
    


}
