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

class StoryScrollCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    // PFObject; used to determine post type
    var postObject: PFObject?
    // Parent UIViewController
    var parentDelegate: UIViewController?
    
    // UIRefreshControl
    var refresher: UIRefreshControl!

    @IBOutlet weak var tableView: UITableView!
    
    
    func refresh() {
        self.refresher.endRefreshing()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Configure UITableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        refresher.tintColor = UIColor.clear
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView!.addSubview(refresher)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - UITableView Data Source Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.postObject!.value(forKey: "contentType") as! String == "tp" {
            // Text Post
            let tpCell = Bundle.main.loadNibNamed("TextPostCell", owner: self, options: nil)?.first as! TextPostCell
            
            tpCell.postObject = self.postObject!
            tpCell.superDelegate = self.parentDelegate
            tpCell.updateView(postObject: self.postObject!)
            
            return tpCell
            
        } else {
            // Profile Photo
            let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell
            
            ppCell.postObject = self.postObject!
            ppCell.superDelegate = self.parentDelegate
            ppCell.updateView(postObject: self.postObject!)
            
            return ppCell
        }
    }
    
    // MARK: - UIScrollView Delegate Methods
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -90 {
            self.parentDelegate?.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
}
