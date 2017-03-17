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
    let codeIds = [
        "nytimes061620160702",
        "wsj061620160702",
        "cnn0702061620160622",
        "theeconomist127060622",
        
        "buzzfeed061620161456",
        "mtv06162016070297",
        "mashable986306162016",
        "entertainmentweekly061123",
        
        "tnw0701923801239",
        "natgeo81039706162016",
        "ign070206220905",
        "espn0616201609632"
                   ]
    
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
                    if object.value(forKey: "code") as! String == self.codeIds[indexPath.item] && indexPath.item == self.codeIds.index(of: self.codeIds[indexPath.item]) {
                        // Set photo
                        let photo = object.value(forKey: "photo") as! PFFile
                        // MARK: - SDWebImage
                        cell.coverPhoto.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: UIImage())
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        
        // Configure covers
        cell.coverPhoto.layer.cornerRadius = 8.00
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
            mediaName.append("The New York Times")
            storyURL.append("https://newsapi.org/v1/articles?source=the-new-york-times&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")

        } else if indexPath.item == 1 {
            // WSJ
            mediaName.append("The Wall Street Journal")
            storyURL.append("https://newsapi.org/v1/articles?source=the-wall-street-journal&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")

        } else if indexPath.item == 2 {
            // CNN
            mediaName.append("CNN")
            storyURL.append("https://newsapi.org/v1/articles?source=cnn&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 3 {
            // THE ECONOMIST
            mediaName.append("The Economist")
            storyURL.append("https://newsapi.org/v1/articles?source=the-economist&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 4 {
            // BUZZFEED
            mediaName.append("BuzzFeed")
            storyURL.append("https://newsapi.org/v1/articles?source=buzzfeed&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 5 {
            // MTV
            mediaName.append("MTV")
            storyURL.append("https://newsapi.org/v1/articles?source=mtv-news&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 6 {
            // MASHABLE
            mediaName.append("Mashable")
            storyURL.append("https://newsapi.org/v1/articles?source=mashable&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 7 {
            // ENTERTAINMENT WEEKLY
            mediaName.append("Entertainment Weekly")
            storyURL.append("https://newsapi.org/v1/articles?source=entertainment-weekly&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
            
        } else if indexPath.item == 8 {
            // TNW
            mediaName.append("The Next Web")
            storyURL.append("https://newsapi.org/v1/articles?source=the-next-web&sortBy=latest&apiKey=eb568b2491d1431194e224121f7c4f03")

        } else if indexPath.item == 9 {
            // NATGEO
            mediaName.append("National Geographic")
            storyURL.append("https://newsapi.org/v1/articles?source=national-geographic&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")

        } else if indexPath.item == 10 {
            // IGN
            mediaName.append("IGN")
            storyURL.append("https://newsapi.org/v1/articles?source=ign&sortBy=latest&apiKey=eb568b2491d1431194e224121f7c4f03")
        } else if indexPath.item == 11 {
            // ESPN
            mediaName.append("ESPN")
            storyURL.append("https://newsapi.org/v1/articles?source=espn&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
        }
        
        let ssVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "newsVC") as! NewsController
        self.delegate?.navigationController?.pushViewController(ssVC, animated: true)
//        let ssVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "selectedStoriesVC") as! SelectedStories
//        self.delegate?.navigationController?.pushViewController(ssVC, animated: true)
    }
    
}
