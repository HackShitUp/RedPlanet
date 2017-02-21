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

class NewsController: UITableViewController, UINavigationControllerDelegate {

    var stories = [String]()
    var storyURLS = [String]()
    var mediaURLS = [String]()

    @IBAction func back(_ sender: Any) {
        self.stories.removeAll(keepingCapacity: false)
        self.storyURLS.removeAll(keepingCapacity: false)
        self.mediaURLS.removeAll(keepingCapacity: false)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func refresh(_ sender: Any) {
        // Reload data
        downloadArticles()
    }
    
    func downloadArticles() {
        
        // MARK: - SVProgressHUD
        SVProgressHUD.show()
        
        let url = URL(string: "http://api.nytimes.com/svc/mostpopular/v2/mostviewed/all-sections/1.json?api-key=9510e9823f194040b75af0012d79277c")
        let session = URLSession.shared
        let task = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                // MARK: - SVProgressHUD
                SVProgressHUD.dismiss()
                
                // Clear arrays
                self.stories.removeAll(keepingCapacity: false)
                self.storyURLS.removeAll(keepingCapacity: false)
                self.mediaURLS.removeAll(keepingCapacity: false)
                if let webContent = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        // Optional Chaining: JSON Data
                        if let items = json.value(forKey: "results") as? Array<Any> {
                            for item in items {
                                // GET TITLE
                                let title = (item as AnyObject).value(forKey: "title") as! String
                                self.stories.append(title)
                                // GET STORY URL
                                let url = (item as AnyObject).value(forKey: "url") as! String
                                self.storyURLS.append(url)
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
            
            // Reload data
            self.tableView?.reloadData()
        }
        task.resume()
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
            self.title = "NYTimes API"
        }
        
        // Enable UIBarButtonItems, configure navigation bar, && show tabBar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize title
        configureView()
        
        // Fetch articles
        downloadArticles()
        
        // Configure table view
        self.tableView!.estimatedRowHeight = 215.00
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 215
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell

        // Set title
        cell.title.text! = self.stories[indexPath.row]
        cell.title.layer.shadowColor = UIColor.black.cgColor
        cell.title.layer.shadowOffset = CGSize(width: 1, height: 1)
        cell.title.layer.shadowRadius = 3
        cell.title.layer.shadowOpacity = 0.5
        // Set Asset Preview
        // MARK: - SDWebImage
        cell.asset.sd_setImage(with: URL(string: mediaURLS[indexPath.row]), placeholderImage: UIImage())
        cell.asset.layer.cornerRadius = 12.00
        cell.asset.layer.borderColor = UIColor.black.cgColor
        cell.asset.layer.borderWidth = 0.25
        cell.asset.clipsToBounds = true

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: - SwiftWebVC
        let webVC = SwiftModalWebVC(urlString: self.storyURLS[indexPath.row])
        self.present(webVC, animated: true, completion: nil)
    }
}
