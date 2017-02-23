//
//  AboutUs.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/26/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class AboutUs: UITableViewController, UINavigationControllerDelegate {
    
    
    
    
    // Variables to hold text
    var rowTitles = ["Why Redplanet Exists",
                     "What is our vision as a startup?",
                     "What is Redplanet as a product or service?"]
    
    var rowText = [
        "Redplanet's mission is to provide people a comfortable way to express themselves through various forms of content.\n\nThe kernel of Redplanet, lies in the belief that sharing, interacting with, and viewing both public and private information should NOT be permanent. This is because we think that people's identities shouldn't be the accumulation of their posts.\n\nUnlike other ephemeral platforms that only focus on Photos or Videos, Redplanet allows you to share publicly-interactive Text Posts, Shared Posts, Moments, Profile Photo updates, or those extremely personal, Space Posts.\n",
        "Redplanet is a media company. We want to allow people to comfortably (and explicitly) control the type of information they share and view.\n\nFor most of us, the internet revolutionized how we live our lives for the past decade. And with the advent of free-flowing information, innovations everywhere enabled us to freely gather information about whatever we want; including whoever we want. Unfortunately, this backfires once you realize that everything you share on the internet stays there forever.\n\nFor those reasons, we believe that Redplanet is the best platform to share, interact with, or view published news, not only about our friends, but also about the world.\n\nAt the core of Redplanet, our value is to create phenomenally great products that empower people to express themselves.\n\nWhen we design such products, we first ask, “What is the human-problem we’re solving?” Then we ask, “What is the best, intuitive solution to solve this problem.” Finally, we ask, “How do we want people to feel while they use our product?” After we complete this rigorous process and get at the root of the problem, we begin developing our products...",
        "At the heart of Redplanet, lies ephemerality. Whatever you share, disappears in 24 hours. On Redplanet, there’s no such thing as permanence; you can only save them.\n\nA complementary feature with ephemeral identities is that we have two separate news feeds. On the left-side, we have a news feed of mutual followings/followers. In other words, if you’re following John, and John is following you back, you’ll see all of John’s posts on the left-side of your news feed. On the right-side, you’ll see all of the posts shared by accounts you follow, and they don’t follow you back. We think this might enhance the experience when using our product for two reasons:\n\n(1) You can finally get to see who’s not following you back (via the left-side of the news feed) when they share a post.\n(2) It’ll organize your news feed when it get’s cluttered.\n\nWe do our best to make sure our service naturally enables people to not only share photos or videos about their life, but thoughts in the form of text, perspectives with news, or even how one may currently look with a Profile Photo update. In a nutshell there are 7 different types of posts you can share on Redplanet:\n\n1) Text Posts - Posts that are only focused on text, including urls.\n2) Photos - Posts that are focused on a single photo, shared from your camera roll.\n3) Videos - Posts that are focused on a single video, shared from your camera roll.\n4) Moments - Photos or Videos captured directly with the camera.\n5) Shared Posts - Posts that you share via someone else.\n6) Space Posts - Posts that you share on someone’s Space (digital “wall”).\n7) Profile Photo Updates - Updates about your new Profile Photo.\n\nIMAGINE\n\nJoshua 1:9"
    ]
    
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop vc
        _ = _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Demibold", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0),
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "About Us"
        }
        
        // Configure nav bar, show tab bar, and set statusBar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stylize navigation bar
        configureView()

        // Set tableView Height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 90
        self.tableView!.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aboutUsCell", for: indexPath) as! AboutUsCell
        
        // Set delegate
        cell.delegate = self

        // Set indexPath
        if indexPath.row == 0 {
            cell.headerTitle.text! = rowTitles[indexPath.row]
            cell.aboutText.text! = rowText[indexPath.row]
        }
        
        if indexPath.row == 1 {
            cell.headerTitle.text! = rowTitles[indexPath.row]
            cell.aboutText.text! = rowText[indexPath.row]
        }
        
        if indexPath.row == 2 {
            cell.headerTitle.text! = rowTitles[indexPath.row]
            cell.aboutText.text! = rowText[indexPath.row]
        }

        return cell
    }
    


}
