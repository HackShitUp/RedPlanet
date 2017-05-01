//
//  EHeaderCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts

class EHeaderCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var delegate: UIViewController?

    // Arrays to hold publisherNames and Objects for Stories
    var sourceObjects = [PFObject]() // used for Selected Stories
    var publisherNames = [String]()
    var articles = [AnyObject]()
    
    @IBOutlet weak var collectionView: UICollectionView!

    func fetchStories() {
        let ads = PFQuery(className: "Ads")
        ads.order(byAscending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                // Clear arrays
                self.sourceObjects.removeAll(keepingCapacity: false)
                self.publisherNames.removeAll(keepingCapacity: false)
                self.articles.removeAll(keepingCapacity: false)
                for object in objects! {
                    // (1) Append Source URLS
                    self.sourceObjects.append(object)
                }
                
                // Fetch Articles with Completion Handler to return data when called asyncrhonously...
                self.fetchArticles(forObjects: self.sourceObjects, completion: { (articleObjects, publisherNames) in
//                    print("Publisher Names: \(publisherNames)")
//                    print("ARTICLE OBJECTS: \(articleObjects)")
                    self.collectionView.reloadData()
                })
                
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    func fetchArticles(forObjects: [PFObject], completion: @escaping([AnyObject], [String]) -> Void) {
        
        for object in forObjects {
            // (2) Append publisherNames, and articles
            URLSession.shared.dataTask(with: URL(string: object.value(forKey: "URL") as! String)!,
                                       completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                                        if error != nil {
                                            print(error?.localizedDescription as Any)
                                            return
                                        }
                                        
                                        do  {
                                            
                                            // Traverse JSON data to "Mutable Containers"
                                            let json = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                                            
                                            // (1) Get Source (publisherNames) --> remove "-" and capitalize first word
                                            let source = ((json as AnyObject).value(forKey: "source") as! String).replacingOccurrences(of: "-", with: " ")
                                            self.publisherNames.append(source.localizedCapitalized)
                                            
                                            print("PublisherName: \(source.localizedCapitalized)\n")
                                            
                                            // (2) Get First Article for each source
                                            let items = (json as AnyObject).value(forKey: "articles") as? Array<Any>
                                            let firstSource = items![0]
                                            self.articles.append(firstSource as AnyObject)
                                            
                                            
                                            completion(self.articles, self.publisherNames)
                                            
                                        } catch let error {
                                            print(error.localizedDescription as Any)
                                        }
            }) .resume()
        }
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "featuredCell", for: indexPath) as! FeaturedCell

        // (1) Set publisher's name
        cell.publisherName.text = self.publisherNames[indexPath.item]
        
        // (2) Set cover photo
        if let urlToImage = self.articles[indexPath.item].value(forKey: "urlToImage") as? String {
            // MARK: - SDWebImage
            cell.storyCover.sd_setImage(with: URL(string: urlToImage)!)
        }
        
        // (3) Set title
        if let title = self.articles[indexPath.item].value(forKey: "title") as? String {
            cell.storyTitle.text = title
        }
        
        // MARK: - RPHelpers
        cell.storyCover.roundAllCorners(sender: cell.storyCover)
        cell.storyTitle.layer.applyShadow(layer: cell.storyTitle.layer)
        cell.publisherName.layer.applyShadow(layer: cell.publisherName.layer)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Track Who Tapped a story
        Heap.track("TappedSelectedStories", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])

        let selectedStoriesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "selectedStoriesVC") as! SelectedStories
        // Pass data...
        // (1) Publisher Name
        selectedStoriesVC.publisherName = self.publisherNames[indexPath.item]
        // (2) Publisher Logo URL
        if let publisherLogo = self.sourceObjects[indexPath.item].value(forKey: "photo") as? PFFile {
            selectedStoriesVC.logoURL = publisherLogo.url!
        }
        // (3) NewsApi.org source URL
        selectedStoriesVC.sourceURL = (self.sourceObjects[indexPath.item].value(forKey: "URL") as! String)

        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: selectedStoriesVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
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
        
        // Set UICollectionView DataSource and Delegates
        self.collectionView!.dataSource = self
        self.collectionView!.delegate = self
    }
    
}
