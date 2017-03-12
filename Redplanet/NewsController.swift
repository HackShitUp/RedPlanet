//
//  NewsController.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import SDWebImage

import Parse
import ParseUI
import Bolts

import SVProgressHUD

// Array to hold news URL
var storyURL = [String]()

class NewsController: UITableViewController, UINavigationControllerDelegate {

    // Arrays to hold data
    var titles = [String]()
    var webURLS = [String]()
    var mediaURLS = [String]()

    @IBAction func back(_ sender: Any) {
        storyURL.removeAll(keepingCapacity: false)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        if storyURL.last! == "http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/1.json?api-key=9510e9823f194040b75af0012d79277c" {
            // NYTIMES
            fetchNYTimes()
            configureView(navTitle: "The New York Times", navColor: UIColor.black)
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=the-wall-street-journal&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
            // WSJ
            fetchWSJ()
            configureView(navTitle: "Wall Street Journal", navColor: UIColor.black)
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=buzzfeed&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
            // BUZZFEED
            fetchBuzzfeed()
            configureView(navTitle: "BuzzFeed", navColor: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=mtv-news&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
            // MTV
            fetchMTV()
            configureView(navTitle: "MTV", navColor: UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0))
        }
    }
    
    // NYTIMES
    func fetchNYTimes() {
        let url = URL(string: "http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/1.json?api-key=9510e9823f194040b75af0012d79277c")
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
                if let webContent = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        // Optional Chaining: JSON Data
                        if let items = json.value(forKey: "results") as? Array<Any> {
                            for item in items {
                                // GET TITLE
                                let title = (item as AnyObject).value(forKey: "title") as! String
                                self.titles.append(title)
                                // GET STORY URL
                                let url = (item as AnyObject).value(forKey: "url") as! String
                                self.webURLS.append(url)
                                // GET MEDIA
                                if let assets = (item as AnyObject).value(forKey: "media") as? NSArray {
                                    let assetList = (assets[0] as AnyObject).value(forKey: "media-metadata") as? NSArray
                                    for asset in assetList! {
                                        if (asset as AnyObject).value(forKey: "format") != nil && (asset as AnyObject).value(forKey: "format") as! String == "Jumbo" {
                                            let assetURL = (asset as AnyObject).value(forKey: "url") as! String
                                            self.mediaURLS.append(assetURL)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Reload data
                        self.tableView?.reloadData()
                        
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
                // Reload data
                self.tableView?.reloadData()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
            }
            // Reload data
            self.tableView!.reloadData()
        }
        task.resume()
    }
    
    
    // WSJ
    func fetchWSJ() {
        let url = URL(string: "https://newsapi.org/v1/articles?source=the-wall-street-journal&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
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
                            }
                        }
                        
                        // Reload data
                        self.tableView?.reloadData()
                        
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
                // Reload data
                self.tableView?.reloadData()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
            }
            // Reload data
            self.tableView!.reloadData()
        }
        task.resume()
    }
    
    // BUZZFEED
    func fetchBuzzfeed() {
        let url = URL(string: "https://newsapi.org/v1/articles?source=buzzfeed&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
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
                            }
                        }
                        
                        // Reload data
                        self.tableView?.reloadData()
                        
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
                // Reload data
                self.tableView?.reloadData()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
            }
            // Reload data
            self.tableView!.reloadData()
        }
        task.resume()
    }
    
    // MTV
    func fetchMTV() {
        let url = URL(string: "https://newsapi.org/v1/articles?source=mtv-news&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03")
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
                            }
                        }
                        
                        // Reload data
                        self.tableView?.reloadData()
                        
                    } catch {
                        print("ERROR: Unable to read JSON data.")
                        // MARK: - SVProgressHUD
                        SVProgressHUD.dismiss()
                    }
                }
                // Reload data
                self.tableView?.reloadData()
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
            }
            // Reload data
            self.tableView!.reloadData()
        }
        task.resume()
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView(navTitle: String?, navColor: UIColor?) {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: navColor!,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "\(navTitle!)"
        }
        
        // Enable UIBarButtonItems, configure navigation bar, && show tabBar (last line)
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.tintColor = navColor!
        self.navigationController?.navigationBar.topItem?.rightBarButtonItem?.tintColor = navColor!
        self.navigationController?.navigationBar.tintColor = navColor!
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if storyURL.last! == "http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/1.json?api-key=9510e9823f194040b75af0012d79277c" {
        // NYTIMES
            fetchNYTimes()
            configureView(navTitle: "The New York Times", navColor: UIColor.black)
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=the-wall-street-journal&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
        // WSJ
            fetchWSJ()
            configureView(navTitle: "Wall Street Journal", navColor: UIColor.black)
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=buzzfeed&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
        // BUZZFEED
            fetchBuzzfeed()
            configureView(navTitle: "BuzzFeed", navColor: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
        } else if storyURL.last! == "https://newsapi.org/v1/articles?source=mtv-news&sortBy=top&apiKey=eb568b2491d1431194e224121f7c4f03" {
        // MTV
            fetchMTV()
            configureView(navTitle: "MTV", navColor: UIColor(red:1.00, green:0.86, blue:0.00, alpha:1.0))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        
        // Configure table view
        self.tableView!.estimatedRowHeight = 215.00
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.separatorColor = UIColor.white
        self.tableView!.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        PFQuery.clearAllCachedResults()
        PFFile.clearAllCachedDataInBackground()
        URLCache.shared.removeAllCachedResponses()
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 215
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        // Set title
        cell.title.text! = self.titles[indexPath.row]
        cell.title.layer.shadowColor = UIColor.black.cgColor
        cell.title.layer.shadowOffset = CGSize(width: 3, height: 3)
        cell.title.layer.shadowRadius = 5.0
        cell.title.layer.shadowOpacity = 1.0
        cell.title.sizeToFit()
        cell.title.numberOfLines = 0
        // Set Asset Preview
        // MARK: - SDWebImage
        cell.asset.sd_setImage(with: URL(string: mediaURLS[indexPath.row]), placeholderImage: UIImage())
        cell.asset.layer.cornerRadius = 6.00
        cell.asset.layer.borderColor = UIColor.white.cgColor
        cell.asset.layer.borderWidth = 0.1
        cell.asset.clipsToBounds = true

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: self.webURLS[indexPath.row])
        self.present(webVC, animated: true, completion: nil)
    }
}
