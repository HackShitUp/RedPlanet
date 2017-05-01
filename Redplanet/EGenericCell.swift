//
//  EGenericCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

import Parse
import ParseUI
import Bolts

import SDWebImage

class EGenericCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var randoms = [PFObject]()
    var geoCodes = [PFObject]()
    
    var fetchType: String?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    func fetchRandoms() -> [PFObject] {
        let people = PFUser.query()!
        people.whereKey("private", equalTo: false)
        people.whereKey("proPicExists", equalTo: false)
        people.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.randoms.removeAll(keepingCapacity: false)
                for object in objects!.shuffled() {
                    self.randoms.append(object)
                }
                
                self.collectionView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        return self.randoms
    }
    
    
    func fetchPeople(_ completionHandler: @escaping ([PFObject]) -> ()) {
        let people = PFUser.query()!
        people.whereKey("private", equalTo: true)
        people.whereKey("proPicExists", equalTo: true)
        people.findObjectsInBackground { (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.randoms.removeAll(keepingCapacity: false)
                for object in objects!.shuffled() {
                    self.randoms.append(object)
                }
                
                self.collectionView!.reloadData()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(self.randoms)
                })
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    
    // Function to fetch geoLocation
    func fetchGeocodes() {
        // Find location
        let discover = PFUser.query()!
        discover.whereKey("objectId", notEqualTo: PFUser.current()!.objectId!)
//        discover.limit = self.page
        discover.order(byAscending: "createdAt")
        discover.whereKey("location", nearGeoPoint: PFUser.current()!.value(forKey: "location") as! PFGeoPoint, withinMiles: 50)
        discover.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    if !blockedUsers.contains(where: {$0.objectId == object.objectId}) {
                        self.geoCodes.append(object)
                    }
                }
                

                // Reload data
                self.collectionView!.reloadData()
                
            } else {
                if (error?.localizedDescription.hasPrefix("The Internet connection appears to be offline."))! || (error?.localizedDescription.hasPrefix("NetworkConnection failed."))! {
                    // MARK: - SVProgressHUD
//                    SVProgressHUD.dismiss()
                }
            }
        })
    }
    
    
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 125, height: 125)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        self.collectionView!.collectionViewLayout = layout
        
        
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
    }
    
    
    
    func setCollectionViewDataSourceDelegate
        <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>
        (dataSourceDelegate: D, forRow row: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
    
    
    
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.fetchType == "randoms" {
            print("Randoms Count: \(self.randoms.count)")
            return randoms.count
        } else {
            print("Geo_Codes Count: \(self.geoCodes.count)")
            return geoCodes.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCell", for: indexPath) as! ExploreCell
        
        cell.rpUserProPic.makeCircular(imageView: cell.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.randomColor())

        
        if self.fetchType == "random" {
            
            if let proPic = self.randoms[indexPath.item].value(forKey: "userProfilePicture") as? PFFile {
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            cell.rpUsername.text = "\(self.randoms[indexPath.item].value(forKey: "realNameOfUser") as! String)"
            
        } else if self.fetchType == "geoCodes" {
            
            if let proPic = self.geoCodes[indexPath.item].value(forKey: "userProfilePicture") as? PFFile {
                cell.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            
            cell.rpUsername.text = "\(self.geoCodes[indexPath.item].value(forKey: "realNameOfUser") as! String)"
        }
        
        return cell
    }

}
