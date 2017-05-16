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
    
    // Array to hold people
    var geocodeUsers = [PFObject]()
    var randomUsers = [PFObject]()
    
    let appDelegate = AppDelegate()
    // UIRefreshControl
    var refresher: UIRefreshControl!
    // PFQuery pipeline method
    var page: Int = 30
    
    
    var exploreTitles = ["Featured", "Promoted", "Near Me", "Suggested"]
    
    @IBOutlet weak var searchBar: UITextField!
    
    func refresh() {
        self.refresher.endRefreshing()
    }
    
    // Fetch Users and shuffle results
    func fetchDiscover() {
        // Fetch blocked users
        _ = appDelegate.queryRelationships()
        
        let publicWProPic = PFUser.query()!
        publicWProPic.whereKey("private", equalTo: false)
        publicWProPic.whereKey("proPicExists", equalTo: true)
        
        let privateWProPic = PFUser.query()!
        privateWProPic.whereKey("private", equalTo: true)
        privateWProPic.whereKey("proPicExists", equalTo: true)

        let both = PFQuery.orQuery(withSubqueries: [publicWProPic, privateWProPic])
        both.limit = self.page
        both.whereKey("objectId", notEqualTo: "mWwx2cy2H7")
        both.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.randomUsers.removeAll(keepingCapacity: false)
                let shuffled = objects!.shuffled()
                
                for object in shuffled {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) {
                        self.randomUsers.append(object)
                    }
                }
                
                // FETCH nearby users
                if PFUser.current()!.value(forKey: "location") != nil {
                    self.discoverGeoCodes()
                }

            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            
            }
        })
    }
    

    
    // Function to fetch geoLocation
    func discoverGeoCodes() {
        // Find location
        let discover = PFUser.query()!
        discover.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
        discover.limit = self.page
        discover.order(byAscending: "createdAt")
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear array
                self.geocodeUsers.removeAll(keepingCapacity: false)
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) && !self.geocodeUsers.contains(where: {$0.objectId! == object.objectId!}) {
                        self.geocodeUsers.append(object)
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
            // Reload data in main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show geoCodes
        fetchDiscover()
        
        // Configure UITableView
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
        
        // Configure UITextField
        searchBar.delegate = self
        searchBar.backgroundColor = UIColor.groupTableViewBackground
        searchBar.font = UIFont(name: "AvenirNext-Medium", size: 15)
        searchBar.text = "Search"
        searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 32, height: 30)
        searchBar.textAlignment = .center
        searchBar.textColor = UIColor.darkGray
        searchBar.roundAllCorners(sender: searchBar)
        
        // Configure UIRefreshControl
        refresher = UIRefreshControl()
        refresher.backgroundColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        refresher.tintColor = UIColor.white
        refresher.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.tableView.addSubview(refresher)
        
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
        // Push to Search
        let searchVC = self.storyboard?.instantiateViewController(withIdentifier: "searchVC") as! Search
        self.navigationController?.pushViewController(searchVC, animated: true)
    }

    // MARK: - UITableView Data Source Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.backgroundColor = UIColor.white
        header.textColor = UIColor(red: 0, green: 0.63, blue: 1, alpha: 1)
        header.font = UIFont(name: "AvenirNext-Bold", size: 12)
        header.textAlignment = .left
        if section == 0 {
            header.text = "      FEATURED"
        } else if section == 1 {
            header.text = "      NEAR YOU"
        } else {
            header.text = "      SUGGESTED"
        }
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 175
        } else {
            return 125
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableCollectionCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let ehCell = self.tableView.dequeueReusableCell(withIdentifier: "eHeaderCell", for: indexPath) as! EHeaderCell
            ehCell.fetchStories()
            ehCell.delegate = self
            return ehCell
        } else {
            let tCell = self.tableView.dequeueReusableCell(withIdentifier: "tableCollectionCell", for: indexPath) as! TableCollectionCell
            // The below code is "unecessary"
            tCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
            return tCell
        }
    }
}



// MARK: - Explore Extension for UITableViewCell --> TableCollectionCell
extension Explore: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return self.randomUsers.count
        } else {
            return self.geocodeUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
            //set contentView frame and autoresizingMask
            cell.contentView.frame = cell.bounds
            
            // MARK: - RPHelpers extension
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
            // (1) Set username
            cell.rpUsername.text! = (self.geocodeUsers[indexPath.row].value(forKey: "username") as! String).lowercased()
            
            // (2) Set fullName
            cell.rpFullName.text! = (self.geocodeUsers[indexPath.row].value(forKey: "realNameOfUser") as! String)
            
            // (3) Get and set profile photo
            // Handle optional chaining
            if let proPic = self.geocodeUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_addActivityIndicator()
                cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
            //set contentView frame and autoresizingMask
            cell.contentView.frame = cell.bounds
            
            // MARK: - RPHelpers extension
            cell.rpUserProPic.makeCircular(forView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            
            // (1) Set username
            cell.rpUsername.text! = (self.randomUsers[indexPath.row].value(forKey: "username") as! String).lowercased()
            
            // (2) Set fullName
            cell.rpFullName.text! = (self.randomUsers[indexPath.row].value(forKey: "realNameOfUser") as! String)
            
            // (3) Get and set profile photo
            // Handle optional chaining
            if let proPic = self.randomUsers[indexPath.row].value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                cell.rpUserProPic.sd_addActivityIndicator()
                cell.rpUserProPic.sd_setIndicatorStyle(.gray)
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
