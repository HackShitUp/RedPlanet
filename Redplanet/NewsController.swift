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
var mediaName = [String]()

class NewsController: UITableViewController, UINavigationControllerDelegate {

    // Arrays to hold data
    var titles = [String]()
    var webURLS = [String]()
    var mediaURLS = [String]()
    var authors = [String]()

    @IBAction func back(_ sender: Any) {
        storyURL.removeAll(keepingCapacity: false)
        mediaName.removeAll(keepingCapacity: false)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.setData()
    }
    
    
    // Function to set data
    func setData() {
        // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
        fetchAnyNews(mediaSource: storyURL.last!)
    }
    
    // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
    func fetchAnyNews(mediaSource: String?) {
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
    
    
    // Function to show API
    func showAPIUsage() {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: "https://newsapi.org")
        self.present(webVC, animated: true, completion: nil)
    }
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.00) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Selected Stories"
        }
        
        // Enable UIBarButtonItems, configure navigation bar, && show tabBar (last line)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Stylize title
        configureView()
        // Configure data
        self.setData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        
        // Register NIB
        let nib = UINib(nibName: "NewsHeader", bundle: nil)
        tableView?.register(nib, forHeaderFooterViewReuseIdentifier: "NewsHeader")
        
        // Configure table view
        self.tableView!.estimatedRowHeight = 275
        self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.separatorColor = UIColor(red:0.96, green:0.95, blue:0.95, alpha:1.0)
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
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "NewsHeader") as! NewsHeader
        // (1) Add Tap Method
        let apiTap = UITapGestureRecognizer(target: self, action: #selector(showAPIUsage))
        apiTap.numberOfTapsRequired = 1
        header.isUserInteractionEnabled = true
        header.addGestureRecognizer(apiTap)
        
        // (2) Fetch media's logo
        let ads = PFQuery(className: "Ads")
        ads.whereKey("adName", equalTo: mediaName.last!)
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                for object in objects! {
                    if let file = object.value(forKey: "photo") as? PFFile {
                        // Configure UIImageView
                        header.mediaLogo.layer.cornerRadius = 6.00
                        header.mediaLogo.clipsToBounds = true
                        // MARK: - SDWebImage
                        header.mediaLogo.sd_setImage(with: URL(string: file.url!), placeholderImage: UIImage())
                    }
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
        // (3) Set Media's Name
        header.mediaName.text! = mediaName.last!
        return header
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 275
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        // (1) Set title
        cell.title.text! = self.titles[indexPath.row]
        cell.title.sizeToFit()
        cell.title.numberOfLines = 0
        // (2) Set Asset Preview
        // MARK: - SDWebImage
        cell.asset.sd_setImage(with: URL(string: mediaURLS[indexPath.row]), placeholderImage: UIImage())
        cell.asset.layer.cornerRadius = 4.00
        cell.asset.layer.borderColor = UIColor.lightGray.cgColor
        cell.asset.layer.borderWidth = 0.50
        cell.asset.clipsToBounds = true
        // (3) Set author
        cell.author.text! = "By \(self.authors[indexPath.row])"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: self.webURLS[indexPath.row])
        self.present(webVC, animated: true, completion: nil)
    }
}
