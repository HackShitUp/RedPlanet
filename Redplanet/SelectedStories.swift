//
//  SelectedStories.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//


import UIKit
import CoreData
import SafariServices

import Parse
import ParseUI
import Bolts

import AnimatedCollectionViewLayout
import SDWebImage
import SVProgressHUD
import SwipeNavigationController


class SelectedStories: UIViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Class Variables
    var publisherName = String()
    var logoURL = String()
    var sourceURL = String()
    
    // Array to hold articles
    var articleObjects = [AnyObject]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func exit(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
    func fetchStories(mediaSource: String?) {
        // Clear arrays
        self.articleObjects.removeAll(keepingCapacity: false)
        // Fetch request to url...
        URLSession.shared.dataTask(with: URL(string: mediaSource!)!,
                                   completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                                    if error != nil {
                                        print(error?.localizedDescription as Any)
                                        return
                                    }
                                    do  {
                                        // Traverse JSON data to "Mutable Containers"
                                        let json = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))

                                        // Get First Article for each source
                                        let items = (json as AnyObject).value(forKey: "articles") as? Array<Any>
                                        for item in items! {
                                            self.articleObjects.append(item as AnyObject)
                                        }
                                        
                                        // Update UICollectionView in Main Thread
                                        DispatchQueue.main.async {
                                            self.collectionView.reloadData()
                                        }
                                        
                                    } catch let error {
                                        print(error.localizedDescription as Any)
                                    }
        }) .resume()
    }

    // Function to show API
    func showAPIUsage() {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: "https://newsapi.org/")!, entersReaderIfAvailable: true)
        // MARK: - RPHelpers
        webVC.view.roundAllCorners(sender: webVC.view)
        self.present(webVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - MainTabUI
        // Show button
        rpButton.isHidden = false
        
        // Fetch Stories
        self.fetchStories(mediaSource: self.sourceURL)
        
        // Hide UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = CubeAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = self.view.bounds.size
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.frame = self.view.bounds
        self.collectionView!.backgroundColor = UIColor.white
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.articleObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ssCell", for: indexPath) as! SelectedStoriesCell
        
        // CONFIGURE PUBLISHER PROPERTIES
        // Set publisher name
        cell.publisherName.text = self.publisherName
        // MARK: - SDWebImage
        cell.publisherLogo.sd_setImage(with: URL(string: self.logoURL)!)
        cell.publisherLogo.image?.getColors { colors in
            cell.publisherName.textColor = colors.primaryColor
        }
        // MARK: - RPHelpers
        cell.publisherLogo.roundAllCorners(sender: cell.publisherLogo)

        // CONFIGURE STORY
        // (1) Set title
        cell.title.text = "\(self.articleObjects[indexPath.item].value(forKey: "title") as! String)"
        // (2) Set cover photo
        // MARK: - SDWebImage
        if let urlToImage = self.articleObjects[indexPath.item].value(forKey: "urlToImage") as? String {
            cell.coverPhoto.sd_setImage(with: URL(string: urlToImage)!)
        }
        // (3) Set author
        if let author = self.articleObjects[indexPath.item].value(forKey: "author") as? String {
            cell.author.text = "By \(author)"
        }
        // (4) Set Description
        if let description = self.articleObjects[indexPath.item].value(forKey: "description") as? String {
            cell.storyDescription.text = "\(description)"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: self.articleObjects[indexPath.row].value(forKey: "url") as! String)!, entersReaderIfAvailable: false)
        // MARK: - RPHelpers
        webVC.view.roundAllCorners(sender: webVC.view)
        self.present(webVC, animated: true, completion: nil)
    }
}
