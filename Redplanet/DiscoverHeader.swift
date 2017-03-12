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
    
    // Codes to get cover photos
    let codeIds = ["nytimes061620160702",
                   "wsj061620160702",
                   "buzzfeed061620161456",
                   "mtv06162016070297"]
    
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Set dataSource and delegate
        self.collectionView!.delegate = self
        self.collectionView!.dataSource = self
        
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.codeIds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "discoverHeaderCell", for: indexPath) as! DiscoverHeaderCell
        
        // MARK: - SDWebImage
        cell.coverPhoto.sd_setIndicatorStyle(.gray)
        cell.coverPhoto.sd_showActivityIndicatorView()
        
        // ADS
        let ads = PFQuery(className: "Ads")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    // (1) NYTIMES
                    if object.value(forKey: "code") as! String == self.codeIds[0] && indexPath.item == 0 {
                        // Set photo
                        if let photo = object.value(forKey: "photo") as? PFFile {
                            // MARK: - SDWebImage
                            cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
                        }
                    } else if object.value(forKey: "code") as! String == self.codeIds[1] && indexPath.item == 1 {
                    // (2) WSJ
                        // Set photo
                        if let photo = object.value(forKey: "photo") as? PFFile {
                            // MARK: - SDWebImage
                            cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
                        }
                    } else if object.value(forKey: "code") as! String == self.codeIds[2] && indexPath.item == 2 {
                    // (3) BuzzFeed
                        // Set photo
                        if let photo = object.value(forKey: "photo") as? PFFile {
                            // MARK: - SDWebImage
                            cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
                        }
                    } else if object.value(forKey: "code") as! String == self.codeIds[3] && indexPath.item == 3 {
                    // (4) MTV
                        // Set photo
                        if let photo = object.value(forKey: "photo") as? PFFile {
                            // MARK: - SDWebImage
                            cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
                        }
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // Configure covers
        cell.coverPhoto.layer.cornerRadius = 6.00
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
        
        if indexPath.item == 0 {
            // NYTIMES
            storyURL.append("http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/1.json?api-key=9510e9823f194040b75af0012d79277c")
        } else if indexPath.item == 1 {
            // WSJ
            storyURL.append("https://newsapi.org/v1/articles?source=the-wall-street-journal&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
        } else if indexPath.item == 2 {
            // BUZZFEED
            storyURL.append("https://newsapi.org/v1/articles?source=buzzfeed&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
        } else if indexPath.item == 3 {
            // MTV
            storyURL.append("https://newsapi.org/v1/articles?source=mtv-news&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
        }
        
        let nytimesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "newsVC") as! NewsController
        self.delegate?.navigationController?.pushViewController(nytimesVC, animated: true)
    }
    
}
