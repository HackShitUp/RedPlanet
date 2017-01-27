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
                      UIImage(named: "CSpacePost"),                  // Space Post
                      UIImage(named: "ITM"),                        // ITM
        UIImage(named: "VideoIcon")     // Video
    ]
    
    // Arrays to hold titles
    var iconNames = ["Text Post",
                     "Photo",
                     "Shared Post",
                     "Profile Photo",
                     "Space Post",
                     "Moment",
                     "Video"]
    
    // Arrays to hold description
    var iconDescripts = ["This is a post focused and concentrated on just text.",
                         "Photos have a corner radius around its thumbnail.",
                         "This is a post that’s been shared by someone publicly.",
                         "Circular photo thumbnails indicate that someone has a new Profile Photo.",
                         "Comets with a red gradient background indicate that someone wrote in someone else’s Space. Only friends can write in each other’s Space.",
                         "Circular previews with a red border around it are called Moments. These are photos or videos captured directly with the camera and last for 24 hours on Redplanet.",
                         "Purple circles with a triangle in it indicate that someone shared a video."
                         ]

    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        _ = self.navigationController?.popViewController(animated: false)
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.setNeedsStatusBarAppearanceUpdate()
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
        return 7
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
        
        // Set iconicPreview default configs
        cell.icon.layer.borderColor = UIColor.clear.cgColor
        cell.icon.layer.borderWidth = 0.00
        cell.icon.contentMode = .scaleAspectFill
        
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
            cell.icon.layer.cornerRadius = cell.icon.frame.size.width/2
            cell.icon.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
            cell.icon.layer.borderWidth = 3.50
            cell.icon.contentMode = .scaleAspectFill
            cell.icon.clipsToBounds = true
            
        } else if indexPath.row == 6 {
            cell.icon.layer.cornerRadius = cell.icon.frame.size.width/2
            cell.icon.clipsToBounds = true
        }
        
        
        

        return cell
    }
    



}
