//
//  PermissionsScope.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Photos
import PhotosUI
import AVFoundation
import AVKit
import Contacts

class PermissionsScope: UITableViewController {
    
    let titles = [
                "Camera",
                "Contacts",
                "Location",
                "Microphone",
                "Notifications",
                "Photos",
                  ]
    
    let descriptions = [
                "To capture Moments and share them with the people you love.",
                "To help you find your friends easily.",
                "To share Moments with location-based filters, and help your friends find you!",
                "To record Moments and share them with the people you love.",
                "To receive notifications about Chats, likes, comments, shares, and more.",
                "To share photos from your library and save photos to your Camera Roll."
    ]
    
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Permission Scope"
        }
        
        // Show statusBar
        UIApplication.shared.isStatusBarHidden = false
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO::
        // CAMERA
        // CONTACTS
        // LOCATION
        // MIC
        // NOTIFICATIONS
        // PHOTOS
        
        // Stylize nav bar
        configureView()
        // Configure tableView
        self.tableView!.estimatedRowHeight = 75
        self.tableView!.rowHeight = UITableViewAutomaticDimension
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "permissionsCell", for: indexPath) as! PermissionsCell

        // Set title
        cell.title.text! = self.titles[indexPath.row]
        // Set descriptions
        cell.reason.text! = self.descriptions[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(url!)
    }
}
