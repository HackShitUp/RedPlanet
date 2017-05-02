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

    @IBOutlet weak var tableView: UITableView!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Configure UITableView
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView()
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
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
        
        let ppCell = Bundle.main.loadNibNamed("ProfilePhotoCell", owner: self, options: nil)?.first as! ProfilePhotoCell

        ppCell.innerPostObject = self.postObject!
        ppCell.updateView(postObject: self.postObject!)
        ppCell.superDelegate = self.parentDelegate
        
        return ppCell
    }
    
    // MARK: - UIScrollView Delegate Methods
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.tableView!.contentOffset.y <= -100 {
            self.parentDelegate?.dismiss(animated: true, completion: nil)
        }
    }
    
    
}
