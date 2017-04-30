//
//  Explore.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/30/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class Explore: UITableViewController {
    
    
    var coverPhotos = [String]()
    var coverTitles = [String]()
    
    
    func fetchStories() {
        let ads = PFQuery(className: "Ads")
        ads.order(byDescending: "createdAt")
        ads.findObjectsInBackground {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                self.coverPhotos.removeAll(keepingCapacity: false)
                self.coverTitles.removeAll(keepingCapacity: false)
                for object in objects! {
                    self.fetchStory(mediaSource: object.value(forKey: "URL") as! String)
                }
                
                print("TITLES:\(self.coverTitles)\n")
                
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    
    
    // NYTIMES, WSJ, BUZZFEED, MTV, MASHABLE
    func fetchStory(mediaSource: String?) {
        let url = URL(string: mediaSource!)
        let session = URLSession.shared
        let task = session.dataTask(with: url!) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {

                if let webContent = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: webContent, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        // Optional Chaining: JSON Data
                        if let items = json.value(forKey: "articles") as? Array<Any> {
                            if let first = items[0] as? AnyObject {
                                if let imageURL = first.value(forKey: "urlToImage") as? String {
                                    self.coverPhotos.append(imageURL)
                                }
                                let title = first.value(forKey: "title") as! String
                                self.coverTitles.append(title)
                            }
                            print("titles: \(self.coverTitles)\n")
                        }
                        
                        // Reload data in the main thread
                        DispatchQueue.main.async {
                            self.tableView!.reloadData()
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

    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchStories()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
