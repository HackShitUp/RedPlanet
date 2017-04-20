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

// Array to hold news URL
var storyURL = [String]()
var mediaName = [String]()

class SelectedStories: UIViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // Arrays to hold data
    var titles = [String]()
    var webURLS = [String]()
    var mediaURLS = [String]()
    var authors = [String]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func exit(_ sender: Any) {
        storyURL.removeAll(keepingCapacity: false)
        mediaName.removeAll(keepingCapacity: false)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
    func fetchStories(mediaSource: String?) {
        let url = URL(string: mediaSource!)
        let session = URLSession.shared
        let task = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.titles.removeAll(keepingCapacity: false)
                self.webURLS.removeAll(keepingCapacity: false)
                self.mediaURLS.removeAll(keepingCapacity: false)
                self.authors.removeAll(keepingCapacity: false)
                
                
                if let webContent = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        // Optional Chaining: JSON Data
                        if let items = json.value(forKey: "articles") as? Array<Any> {
                            for item in items {
                                // GET TITLE
                                let title = (item as AnyObject).value(forKey: "title") as! String
                                self.titles.append(title)
                                // GET STORY URL
                                let url = (item as AnyObject).value(forKey: "url") as! String
                                self.webURLS.append(url)
                                // GET MEDIA
                                if let imageURL = (item as AnyObject).value(forKey: "urlToImage") as? String {
                                    self.mediaURLS.append(imageURL)
                                }
                                // GET AUTHOR
                                if let writer = (item as AnyObject).value(forKey: "author") as? String {
                                    self.authors.append(writer)
                                } else {
                                    self.authors.append(" ")
                                }
                            }
                        }
                        // Reload data in the main thread
                        DispatchQueue.main.async {
                            self.collectionView!.reloadData()
                        }
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
            }
        }
        // Resume query if ended
        task.resume()
    }
    
    
    // Function to show API
    func showAPIUsage() {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: "https://newsapi.org/")!, entersReaderIfAvailable: true)
        webVC.view.layer.cornerRadius = 8.00
        webVC.view.clipsToBounds = true
        self.present(webVC, animated: true, completion: nil)
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "Avenir-Heavy", size: 21) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(mediaName.last!)"
        }
        // MARK: - RPHelpers
        self.navigationController?.navigationBar.whitenBar(navigator: self.navigationController)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        // Show UIstatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set view
        configureView()
        // Configure data
        self.fetchStories(mediaSource: storyURL.last!)
        
        // MARK: - MainTabUI
        // Show button
        rpButton.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        
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
        layout.animator = LinearCardAttributesAnimator()
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
        // (1) Set title
        cell.title.text! = "\(self.titles[indexPath.row])\n\nBy \(self.authors[indexPath.row])"
        cell.title.numberOfLines = 4
        // (2) Set Asset Preview
        // MARK: - SDWebImage
        cell.coverPhoto.sd_setShowActivityIndicatorView(true)
        cell.coverPhoto.sd_setIndicatorStyle(.gray)
        cell.coverPhoto.sd_setImage(with: URL(string: mediaURLS[indexPath.row]), placeholderImage: UIImage())
        // Set corner radius
        cell.coverPhoto.layer.cornerRadius = 2.00
        cell.coverPhoto.layer.borderColor = UIColor.lightGray.cgColor
        cell.coverPhoto.layer.borderWidth = 0.50
        cell.coverPhoto.clipsToBounds = true
        
        // Set corner radius for view
        cell.contentView.layer.cornerRadius = 8.00
        cell.contentView.clipsToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // MARK: - SafariServices
        let webVC = SFSafariViewController(url: URL(string: self.webURLS[indexPath.row])!, entersReaderIfAvailable: true)
        webVC.view.layer.cornerRadius = 8.00
        webVC.view.clipsToBounds = true
        self.present(webVC, animated: true, completion: nil)
    }
    
    
    
}
