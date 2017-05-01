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

    // Variables to hold data
    var publisherName = String()
    var logoURL = String()
    var sourceURL = String()
    
    // Array to hold articles
    var articleObjects = [AnyObject]()
    
    var titles = [String]()
    var coverURLS = [String]()
    var authors = [String]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func exit(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
    func fetchStories(mediaSource: String?) {
        // Clear arrays
        self.titles.removeAll(keepingCapacity: false)
        self.coverURLS.removeAll(keepingCapacity: false)
        self.authors.removeAll(keepingCapacity: false)
        
        // (2) Append publisherNames, and articles
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
                                            self.titles.append((item as AnyObject).value(forKey: "title") as! String)
                                            self.coverURLS.append((item as AnyObject).value(forKey: "urlToImage") as! String)
//                                            self.authors.append((item as AnyObject).value(forKey: "author") as! String)
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
        
        // MARK: - SVProgressHUD
//        SVProgressHUD.show()
        
/*
        MARK: - AnimatedCollectionViewLayout
        ZoomInOutAttributesAnimator()
        RotateInOutAttributesAnimator()
        LinearCardAttributesAnimator()
        CubeAttributesAnimator()
        CrossFadeAttributesAnimator()
        PageAttributesAnimator()
        SnapInAttributesAnimator()
*/
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = ZoomInOutAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.bounds.size.width, height: 603)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        self.collectionView!.frame = self.view.bounds
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
        return self.titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ssCell", for: indexPath) as! SelectedStoriesCell
        
        
        cell.publisherName.text = self.publisherName
        
        // MARK: - SDWebImage
        cell.publisherLogo.sd_setImage(with: URL(string: self.logoURL)!)
        // MARK: - RPHelpers
        cell.publisherLogo.roundAllCorners(sender: cell.publisherLogo)

        // (1) Set title
        cell.title.text = self.titles[indexPath.item]
        
        // (2) Set cover photo
        // MARK: - SDWebImage
        cell.coverPhoto.sd_setImage(with: URL(string: self.coverURLS[indexPath.item])!)
        
        // (3) Set author
//        cell.author.text = self.authors[indexPath.item]
        
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
