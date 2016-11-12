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

    @IBAction func backButton(_ sender: Any) {
        // Pop view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "I C O N S"
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set estimated row height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 175
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        
        // Stylize title
        configureView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Status bar
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 5
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 175
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rpIconsCell", for: indexPath) as! RPIconsCell

        
        // INTRO
        if indexPath.row == 0 {
            
            cell.background.image = UIImage(named: "Wide")
            cell.icon.isHidden = true
            cell.iconName.text = "Our Icons Legend"
            cell.iconName.textColor = UIColor.white
            cell.iconDescription.isHidden = true
            
        }
        
        
        
        // TEXT POST
        if indexPath.row == 1 {
            cell.icon.image = UIImage(named: "TextPostIcon")
            cell.iconName.text = "Text Post"
            cell.iconDescription.text = "This is content focused on just text, and nothing else."
            
        }
        
        
        
        // PHOTO
        if indexPath.row == 2 {
            
            cell.icon.backgroundColor = UIColor.white
            cell.icon.layer.cornerRadius = 4.00
            cell.icon.layer.borderColor = UIColor.black.cgColor
            cell.icon.layer.borderWidth = 2.00
            cell.icon.clipsToBounds = true
            
            cell.iconName.text = "Photo"
            cell.iconDescription.text = "This is content concentrated on a photo. Photos will have a corner radius around the photo's thumbnail."
        }
        
        
        
        // SHARED
        if indexPath.row == 3 {
            
            cell.icon.image = UIImage(named: "BlueShared")
            cell.icon.clipsToBounds = true
            
            cell.iconName.text = "Shared"
            cell.iconDescription.text = "This is content that's been indirectly shared by someone."
        }
        
        
        // PROFILE PHOTO
        if indexPath.row == 4 {
            
            cell.background.image = nil
            
            cell.icon.isHidden = false
            cell.iconName.isHidden = false
            cell.iconDescription.isHidden = false
            
            cell.icon.backgroundColor = UIColor.white
            cell.icon.layer.cornerRadius = cell.icon.frame.size.width/2
            cell.icon.layer.borderColor = UIColor.black.cgColor
            cell.icon.layer.borderWidth = 2.00
            cell.icon.clipsToBounds = true
            
            
            cell.iconName.text = "Profile Photo"
            cell.iconDescription.text = "Circular thumbnails indicate that someone updated his or her Profile Photo."
        }
        
        
        
        

        return cell
    }
    



}
