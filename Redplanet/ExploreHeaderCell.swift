//
//  ExploreHeaderCell.swift
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

class ExploreHeaderCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var publisherNames = [String]()
    var coverPhotos = [String]()
    var coverTitles = [String]()
    
    // initialize String array
    var sourceURLS: [String] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    
    func fetchStories() {
        self.collectionView!.dataSource = self
        self.collectionView!.delegate = self
        
        let ads = PFQuery(className: "Ads")
        ads.order(byAscending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.publisherNames.removeAll(keepingCapacity: false)
                self.coverPhotos.removeAll(keepingCapacity: false)
                self.coverTitles.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.publisherNames.append(object.value(forKey: "adName") as! String)
                    
                    let session = URLSession.shared
                    let task = session.dataTask(with: URL(string: object.value(forKey: "URL") as! String)!) {
                        (data: Data?, response: URLResponse?, error: Error?) in
                        if error == nil {
                            
                            if let webContent = data {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                                    
                                    // Optional Chaining: JSON Data
                                    if let items = json.value(forKey: "articles") as? Array<Any> {
                                        
                                        if let imageURL = (items[0] as AnyObject).value(forKey: "urlToImage") as? String {
                                            self.coverPhotos.append(imageURL)
                                        }
                                        
                                        if let title = (items[0] as AnyObject).value(forKey: "title") as? String {
                                            self.coverTitles.append(title)
                                        }
                                        
//                                        print("TITLE: \((items[0] as AnyObject).value(forKey: "title") as! String)")
//                                        self.collectionView!.reloadData()
                                    }
                                    
                                    
                                    // Reload data in the main thread
                                    DispatchQueue.main.async {
                                        self.collectionView!.reloadData()
                                    }
                                    
                                } catch {
                                    print("ERROR: Unable to read JSON data.")
                                    // MARK: - SVProgressHUD
                                    //                        SVProgressHUD.dismiss()
                                }
                            }
                        } else {
                            print(error?.localizedDescription as Any)
                            // MARK: - SVProgressHUD
                            //                SVProgressHUD.dismiss()
                        }
                    }
                    // Resume query if ended
                    task.resume()
                }
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.coverPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "storyCell", for: indexPath) as! StoryCell

        // MARK: - SDWebImage
        cell.storyCover.sd_setImage(with: URL(string: self.coverPhotos[indexPath.item])!)
        cell.storyTitle.text = self.coverTitles[indexPath.item]
        cell.publisherName.text = self.publisherNames[indexPath.item]
        cell.contentView.bringSubview(toFront: cell.publisherName)
        cell.contentView.bringSubview(toFront: cell.storyTitle)
        
        // MARK: - RPHelpers
        cell.storyCover.roundAllCorners(sender: cell.storyCover)
        cell.storyTitle.layer.applyShadow(layer: cell.storyTitle.layer)
        cell.publisherName.layer.applyShadow(layer: cell.publisherName.layer)
        
        return cell
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 125, height: 175)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        self.collectionView!.collectionViewLayout = layout
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
