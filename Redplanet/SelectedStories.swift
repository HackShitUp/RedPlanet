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
import SwipeNavigationController


/*
 UIViewController class that reinforces UICollectionViewDataSource and UICollectionViewDelegate methods.
 This UIViewController appears when a user taps on a news preview in the "Explore" tab of the main interface.
 
 • Uses NewsApi.org
 
 The data for the presentation of each news story, is binded in this class.
 */

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
        let webVC = SFSafariViewController(url: URL(string: "https://newsapi.org/")!, entersReaderIfAvailable: false)
        // MARK: - RPHelpers
        webVC.view.roundTopCorners(sender: webVC.view)
        self.present(webVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ssCell", for: indexPath) as! SelectedStoriesCell

        // CONFIGURE STORY
        // (1) Set cover photo
        if let urlToImage = self.articleObjects[indexPath.item].value(forKey: "urlToImage") as? String {
            // MARK: - SDWebImage
            cell.coverPhoto.sd_addActivityIndicator()
            cell.coverPhoto.sd_setIndicatorStyle(.gray)
            cell.coverPhoto.sd_setImage(with: URL(string: urlToImage))
            cell.storyStatus.text = "Tap anywhere to read the full story..."
        } else {
            // MARK: - SDWebImage
            cell.coverPhoto.sd_addActivityIndicator()
            cell.coverPhoto.sd_setIndicatorStyle(.gray)
            cell.coverPhoto.sd_setImage(with: URL(string: self.logoURL))
            cell.storyStatus.text = "💩 There's no cover photo for this story..."
        }
        // MARK: - RPExtensions
        cell.storyStatus.layer.applyShadow(layer: cell.storyStatus.layer)
        let formattedString = NSMutableAttributedString()
        _ = formattedString.normal("\(self.publisherName.uppercased())\n", withFont: UIFont(name: "AvenirNext-Demibold", size: 17))
        
        // (2) SET UP STORY
        // Set Title
        if let title = self.articleObjects[indexPath.item].value(forKey: "title") as? String {
            _ = formattedString.bold("\n\(title)\n", withFont: UIFont(name: "AvenirNext-Bold", size: 21))
        }
        // Set author
        if let author = self.articleObjects[indexPath.item].value(forKey: "author") as? String {
            _ = formattedString.bold("\nBy \(author)", withFont: UIFont(name: "AvenirNext-Demibold", size: 15))
        }
        // Set Description
        if let description = self.articleObjects[indexPath.item].value(forKey: "description") as? String {
            _ = formattedString.bold("\n\(description)", withFont: UIFont(name: "AvenirNext-Medium", size: 17))
        }
        cell.title.attributedText = formattedString
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: self.articleObjects[indexPath.row].value(forKey: "url") as! String)!, entersReaderIfAvailable: false)
        self.present(webVC, animated: true, completion: nil)
    }
    
    
}
