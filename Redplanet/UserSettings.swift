//
//  UserSettings.swift
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

// Global variable to dictate what to send to notifications....
// State of user's anonymity
var anonymity = true

class UserSettings: UITableViewController, UINavigationControllerDelegate {

    @IBAction func backButton(_ sender: AnyObject) {
        self.navigationController!.popViewController(animated: true)
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            
            if indexPath.row == 0 {
                
            }
            
            if indexPath.row == 1 {
                
            }
            
            if indexPath.row == 2 {
                
            }
            
            if indexPath.row == 3 {
                
            }
            
            if indexPath.row == 4 {
                
            }
            
            if indexPath.row == 5 {
                
            }
            
        } else {
            
            
            if indexPath.row == 0 {
                
            }
            
            if indexPath.row == 1 {
                
            }
            
            if indexPath.row == 2 {
                
            }
            
            if indexPath.row == 3 {
                
            }
            
            if indexPath.row == 4 {
                
            }
            
            if indexPath.row == 5 {
                
            }
            
        }
    }

}
