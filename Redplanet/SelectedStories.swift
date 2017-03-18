//
//  SelectedStories.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//


import UIKit
import AnimatedCollectionViewLayout

import Parse
import ParseUI
import Bolts

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
    
    @IBOutlet weak var selectedStoriesTitle: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var publisherLogo: PFImageView!
    @IBOutlet weak var publisherName: UILabel!
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
                        // Reload data
                        self.collectionView!.reloadData()
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
                // Reload data
                self.collectionView?.reloadData()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
            }
            // Reload data
            self.collectionView!.reloadData()
        }
    
        task.resume()
    }
    
    
    // Function to show API
    func showAPIUsage() {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: "https://newsapi.org")
        self.present(webVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        // Stylize view
//        self.navigationController?.tabBarController?.tabBar.isHidden = false
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Configure data
        self.fetchStories(mediaSource: storyURL.last!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - AnimatedCollectionViewLayout
        let layout = AnimatedCollectionViewLayout()
        layout.scrollDirection = .horizontal
        layout.animator = LinearCardAttributesAnimator()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.isPagingEnabled = true
        
        // Underline SS
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "\(self.selectedStoriesTitle.text!)", attributes: underlineAttribute)
        self.selectedStoriesTitle.attributedText = underlineAttributedString
        
        // Apply shadow
        self.exitButton.layer.shadowColor = UIColor.black.cgColor
        self.exitButton.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.exitButton.layer.shadowRadius = 4
        self.exitButton.layer.shadowOpacity = 0.5
        
        // Add Tap Method
        let apiTap = UITapGestureRecognizer(target: self, action: #selector(showAPIUsage))
        apiTap.numberOfTapsRequired = 1
        self.selectedStoriesTitle.isUserInteractionEnabled = true
        self.selectedStoriesTitle.addGestureRecognizer(apiTap)
        
        // PUBLISHER
        // Fetch media's logo
        let ads = PFQuery(className: "Ads")
        ads.whereKey("adName", equalTo: mediaName.last!)
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    if let file = object.value(forKey: "photo") as? PFFile {
                        // Configure UIImageView
                        self.publisherLogo.layer.cornerRadius = 6.00
                        self.publisherLogo.clipsToBounds = true
                        // MARK: - SDWebImage
                        self.publisherLogo.sd_setImage(with: URL(string: file.url!), placeholderImage: UIImage())
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        // Set publisher's name
        self.publisherName.text! = mediaName.last!
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
        print("Titles: \(titles.count)")
        return self.titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ssCell", for: indexPath) as! SelectedStoriesCell
        // (1) Set title
        cell.title.text! = self.titles[indexPath.row]
        cell.title.sizeToFit()
        cell.title.numberOfLines = 0
        // (2) Set Asset Preview
        // MARK: - SDWebImage
        cell.coverPhoto.sd_setImage(with: URL(string: mediaURLS[indexPath.row]), placeholderImage: UIImage())
        cell.coverPhoto.layer.cornerRadius = 4.00
        cell.coverPhoto.layer.borderColor = UIColor.lightGray.cgColor
        cell.coverPhoto.layer.borderWidth = 0.50
        cell.coverPhoto.clipsToBounds = true
        // (3) Set author
        if self.authors[indexPath.row] != " " {
            cell.author.text! = "By \(self.authors[indexPath.row])"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: self.webURLS[indexPath.row])
        self.present(webVC, animated: true, completion: nil)
    }

}
