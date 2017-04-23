//
//  TimelineCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/22/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage
import SVProgressHUD
import OneSignal

class TimelineCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {

    
    var postObject: PFObject?
    
    var delegate: UINavigationController?
    
//    var posts = [PFObject]()
//    var likes = [PFObject]()
//    var shares = [PFObject]()
    
    
    @IBOutlet weak var tableView: UITableView!

    
    func configureView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    

    // MARK: - UITableViewDataSource Method
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(667)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure initial setup for time
        let from = self.postObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])

        // *************************************************************************************************************
        // TEXT POST ***************************************************************************************************
        // *************************************************************************************************************
        let tpCell = Bundle.main.loadNibNamed("TimeTextPostCell", owner: self, options: nil)?.first as! TimeTextPostCell
        
        // (1) SET USER DATA
        // MARK: - RPHelpers extension
        tpCell.rpUserProPic.makeCircular(imageView: tpCell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        if let proPic = (self.postObject!.object(forKey: "byUser") as! PFUser).value(forKey: "userProfilePicture") as? PFFile {
            // MARK: - SDWebImage
            tpCell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
        }
        // (1B) realNameOfUser for FRIENDS && username for FOLLOWING
        tpCell.rpUsername.text! = (self.postObject!.object(forKey: "byUser") as! PFUser).value(forKey: "realNameOfUser") as! String
        // (1C) User's Object
        tpCell.userObject = self.postObject!.object(forKey: "byUser") as! PFUser
        // (2) SET POST OBJECT
        tpCell.postObject = self.postObject!
        //            // (3) SET CELL'S DELEGATE
        //            tpCell.delegate = self.parentNavigator
        tpCell.delegate = self.delegate
        
        // (4) SET TEXT POST
        tpCell.textPost.text! = self.postObject!.value(forKey: "textPost") as! String
        
        // (5) SET TIME
        // MARK: - RPHelpers
        tpCell.time.text = difference.getFullTime(difference: difference, date: from)
        
        
        
        return tpCell   // return TimeTextPostCell.swift
        
    }
    
}

