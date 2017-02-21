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
    var rowTitles = ["Welcome to Redplanet", "Copyright Policy\nEffective: November 16th, 2016", "DMCA Notice of Alleged Infringement (Notice)"]
    
    var rowText = [
        // (1)
        "Redplanet is a media company.\n\nWe believe that people should be able to explicitly control the type of information they view. And for those reasons, we believe that we are the best platform for people to consume news, not only about their friends, but also about the world.\n\nUnlike other social media platforms, we have 2 different news feeds. While the left-side is for mutual relationships, the right-side is not. You should follow people back to view them in the left-side, and follow others of your interests only to view them on the right.\n\nWe’ve thought quite a while to figure out exactly what Redplanet might be for our community, and we’ve come to our initial intentions of what we wanted Redplanet to be in the first place. So, let’s talk about them:\n\n• What is Redplanet as a product or service?\n\nHave you ever scrolled through your newsfeed and wished you could curate it?\n\nWe realized that social media is no longer a place for friends to communicate and share content because there’s essentially TWO groups that co-exist in a social-media ecosystem:\n(1) Our friends and families.\n(2) Content creators such as brands, aspiring artists, organizations, publishers, celebrities, etc.\nYet, current social media platforms offer no way to distinguish the former from the latter. As a result, our newsfeed is cluttered with all types of content, from different people. But what might frustrate us the most about this is that it intervenes with our streamlined experience. It’s not that we don’t want to see “irrelevant content” it’s that we’d rather see them in a different space, outside of our friends'.\n\nFor more information about the value we deliver, check out our story on Medium: https://medium.com/@redplanetapp/saluton-mondo-be1f2c1ddbc7#.y1m6qz97r\n\n• Why does Redplanet exist, and what does it stand for?\n\nWe didn’t want Redplanet to exist merely as a social media app. We also wanted some meaning as to why we exist. Our business philosophy, or our values, are quite simple:\nWe believe that we should always imagine “what if,” and challenge the status quo. For more information on our values, check out our story on Medium: https://medium.com/@redplanetapp/what-is-value-205d621b240#.z6dcshs4t\n\n\n*** All icons used in this app is credited to icons8. Check out their website for great icons all for free: https://icons8.com/register/?key=jHV6 ***\n\n\n",
        
              // (2)
                   "Redplanet respects the intellectual property rights of others and expects its users to do the same.\n\n In accordance with the Digital Millennium Copyright Act of 1998 (DMCA), the text of which may be found on the U.S. Copyright Office website at http://www.copyright.gov/legislation/pl105-304.pdf, and other applicable laws, Redplanet has adopted a policy of terminating, in appropriate circumstances and at our sole discretion, the accounts of users who are deemed to be repeat infringers. Redplanet may also, at its sole discretion, limit access to Redplanet's website and services (collectively, 'Service') and/or terminate the accounts of any users who infringe any intellectual property rights of others, whether or not there is any repeat infringement. Redplanet will respond to claims of copyright infringement committed on the Redplanet website that are reported to Redplanet's Designated Copyright Agent, identified in the sample notice below.\n\n    If you knowingly misrepresent in your notification that the material or activity is infringing, you will be liable for any damages, including costs and attorneys' fees, incurred by us or the alleged infringer as the result of our relying upon such misrepresentation in removing or disabling access to the material or activity claimed to be infringing.\n\n If you are a copyright owner, or are authorized to act on behalf of one, or authorized to act under any exclusive right under copyright, please report alleged copyright infringements taking place on or through the Services by completing the following DMCA Notice of Alleged Infringement and delivering it to Redplanet's Designated Copyright Agent. Upon receipt of the Notice as described below, Redplanet will take whatever action, in its sole discretion, it deems appropriate, including removal of the challenged material from the Services.",
                   
                   // (3)
                   "Identify the copyrighted work that you claim has been infringed, or if multiple copyrighted works are covered by this Notice you may provide a representative list of the copyrighted works that you claim have been infringed.\n\n Identify the material that you claim is infringing (or to be the subject of infringing activity) and that is to be removed or access to which is to be disabled, and information reasonably sufficient to permit us to locate the material, including at a minimum, if applicable, the URL of the link shown on the Services where such material may be found.\n\n  Provide your mailing address, telephone number, and, if available, email address.\n\n   Include both of the following statements in the body of the Notice: (i) 'I hereby state that I have a good faith belief that the disputed use of the copyrighted material is not authorized by the copyright owner, its agent, or the law (e.g., as a fair use)'; and (ii) 'I hereby state that the information in this Notice is accurate and, under penalty of perjury, that I am the owner, or authorized to act on behalf of the owner, of the copyright or of an exclusive right under the copyright that is allegedly infringed.'\n\n Provide your full legal name and your electronic or physical signature.\n\n Deliver this Notice, with all items completed, to Redplanet's Designated Copyright Agent:\n\n• Address 1: 557 East Fordham Road, 2nd Floor, Bronx, NY 10458\n• Address 2: 1350 15th Street, Apt. No. 3O\n•Phone Number: (201) -281-3502\n•Email: redplanethub@gmail.com\n\nThank you for being part of our community and using our service!\nJoshua 1:9"
    ]
    
    
    
    @IBAction func backButton(_ sender: AnyObject) {
        // Pop vc
        _ = _ = self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
