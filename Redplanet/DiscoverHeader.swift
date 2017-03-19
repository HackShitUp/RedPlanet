//
//  DiscoverHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/26/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SDWebImage

class DiscoverHeader: UICollectionReusableView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Parent VC
    var delegate: UIViewController?
    // Array to hold Selected Stories
    var sStories = [PFObject]()
    
    @IBOutlet weak var ssTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Function to update UI
    func updateUI() {
        // Set dataSource and delegate
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
        
        // ADS
        let ads = PFQuery(className: "Ads")
        ads.order(byAscending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.sStories.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.sStories.append(object)
                }
                
                // Reload data
                self.collectionView!.reloadData()
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.size.width/3, height: UIScreen.main.bounds.size.width/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        self.collectionView!.collectionViewLayout = layout
    }

    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.sStories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "discoverHeaderCell", for: indexPath) as! DiscoverHeaderCell
        
        // Optionaly chain photos
        if let photo = self.sStories[indexPath.row].value(forKey: "photo") as? PFFile {
            // MARK: - SDWebImage
            cell.coverPhoto.sd_setIndicatorStyle(.gray)
            cell.coverPhoto.sd_showActivityIndicatorView()
            cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
        }
        
        // Configure cover photo
        cell.coverPhoto.layer.cornerRadius = 4.00
        cell.coverPhoto.clipsToBounds = true
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Track Who Tapped a story
        Heap.track("TappedSelectedStories", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
        // Append mediaName and storyUrl
        mediaName.append(self.sStories[indexPath.row].value(forKey: "adName") as! String)
        storyURL.append(self.sStories[indexPath.row].value(forKey: "URL") as! String)
        
        // SS VC
        let ssVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "selectedStoriesVC") as! SelectedStories
        self.delegate?.navigationController?.pushViewController(ssVC, animated: true)
    }
    
}
