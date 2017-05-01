//
//  Explore.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage

class Explore: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchBar: UITextField!
    // UIRefreshControl
    var refresher: UIRefreshControl!

    
    func refresh() {
        self.refresher.endRefreshing()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure UITextField
        self.searchBar.delegate = self
        self.searchBar.font = UIFont(name: "AvenirNext-Medium", size: 17)
        self.searchBar.placeholder = "Search..."
        self.searchBar.leftViewMode = .always
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Search")
        self.searchBar.leftView = imageView
        self.searchBar.addSubview(imageView)
        self.searchBar.backgroundColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red:0.74, green:0.06, blue:0.88, alpha:1.0)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refresher)

        // Configure UITableView
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: - UITextField Delegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Push to SearchEngine
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! SearchEngine
        self.navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 175
        } else {
            return 125
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let ehCell = self.tableView.dequeueReusableCell(withIdentifier: "eHeaderCell", for: indexPath) as! EHeaderCell
            ehCell.fetchStories()
            ehCell.delegate = self
            return ehCell
        }
        
        
        let eCell = self.tableView.dequeueReusableCell(withIdentifier: "eGenericCell", for: indexPath) as! EGenericCell
        
        
        if indexPath.section == 1 && indexPath.row == 0 {
            eCell.fetchType = "randoms"
            eCell.fetchPeople({ (_: [PFObject]) in
                eCell.collectionView.reloadData()
            })
        } else if indexPath.section == 2 && indexPath.row == 0 {
            eCell.fetchType = "geoCodes"
            eCell.fetchGeocodes()
        } else {
            print("?")
        }
        
//        eCell.collectionView.reloadData()
        
        return eCell
        
        
    }

}
