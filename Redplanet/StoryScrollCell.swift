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
