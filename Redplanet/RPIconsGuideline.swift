//
//  RPIconsGuideline.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/8/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


class RPIconsGuideline: UITableViewController, UINavigationControllerDelegate {
    
    
    // Arrays to hold icon images
    var iconImages = [UIImage(named: "TextPostIcon"),               // Text Post
                      UIImage(named: "PhotoGuide"),                 // Photo
                      UIImage(named: "SharedPostIcon"),                 // Shared
                      UIImage(named: "Gender Neutral User-100"),    // Profile Photo
                      UIImage(named: "SpacePost"),                  // Space Post
                      UIImage(named: "ITM")]                        // ITM
    
    // Arrays to hold titles
    var iconNames = ["Text Post",
                     "Photo",
                     "Shared Post",
                     "Profile Photo",
                     "Space Post",
                     "Moment"]
    
    // Arrays to hold description
    var iconDescripts = ["This is a post focused and concentrated on just text.",
                         "Photo posts have a corner radius around its thumbnail.",
                         "This is a post that’s been shared by someone publicly.",
                         "Circular photo thumbnails indicate that someone has a new Profile Photo.",
                         "Comets with a red gradient background indicate that someone wrote in someone else’s Space. Only friends can write in each other’s Space.",
                         "Rectangular photos are what we call Moments. These are photos captured directly from the custom camera and shared on Redplanet."
                         ]

    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController?.popViewController(animated: false)
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName:  UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Iconic Previews"
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 117
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Stylize title
        configureView()
        
        // show nav bsr
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        
        // Set lightcontent
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

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
        return 6
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 117
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rpIconsCell", for: indexPath) as! RPIconsCell

        // Configure cell
        cell.icon.image = iconImages[indexPath.row]
        cell.iconName.text! = iconNames[indexPath.row]
        cell.iconDescription.text! = iconDescripts[indexPath.row]
        
        
        if indexPath.row == 1 {
            cell.icon.layer.cornerRadius = 10.00
            cell.icon.clipsToBounds = true
        } else if indexPath.row == 3 {
            cell.icon.layer.cornerRadius = cell.icon.frame.size.width/2
            cell.icon.clipsToBounds = true
        } else if indexPath.row == 4 {
            cell.icon.layer.cornerRadius = cell.icon.frame.size.width/2
            cell.icon.clipsToBounds = true
        } else if indexPath.row == 5 {
            cell.icon.contentMode = .scaleAspectFit
        }
        
        
        

        return cell
    }
    



}
