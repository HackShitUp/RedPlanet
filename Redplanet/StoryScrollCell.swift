//
//  StoryScrollCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/1/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import SDWebImage

/*
 MARK: - THIS CLASS RELATES TO POSTS SHARED ON REDPLANET
 UICollectionViewCell class that holds a UITableView, and a UITableViewCell IF the type of post is one of the following:
 • Text Post - "tp"
 • Photo - "ph"
 • Profile Photo - "pp"
 • Space Post - "sp"
 
 This class has a unique protocol, called "setTableViewDataSourceDelegate" that configures the parent's UICollectionViewController
 class to its extension that manages UITableViewDataSource and UITableViewDelegate Methods.
 
 FIXED (works) with "Stories.swift", "Hashtags.swift", and "Story.swift"
 */

class StoryScrollCell: UICollectionViewCell, UIScrollViewDelegate {

    // PFObject; used to determine post type
    var postObject: PFObject?
    // Parent UIViewController
    var delegate: UIViewController?

    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - StoryScrollCell Protocol Function; sets datasource and delegate methods
    func setTableViewDataSourceDelegate
        <D: UITableViewDataSource & UITableViewDelegate>
        (dataSourceDelegate: D, forRow row: Int) {
        // Configure UITableView
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = dataSourceDelegate
        tableView.dataSource = dataSourceDelegate
        tableView.tag = row
        tableView.alwaysBounceVertical = false
        tableView.reloadData()
    }

}
