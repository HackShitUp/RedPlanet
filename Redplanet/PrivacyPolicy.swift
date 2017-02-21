//
//  PrivacyPolicy.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/14/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class PrivacyPolicy: UITableViewController, UINavigationControllerDelegate {
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        self.navigationController!.popViewController(animated: true)
    }
    
    // Set TOS
    var ppTitles = ["Last Revised on June 16th, 2016",
                    "Collection of Information",
                    "I. Information You Provide to Us",
                    "II. Information We Collect Automatically When You Use Our Services",
                    "III. Information We Collect From Other Sources",
                    "Use Of Information",
                    "I. We Use Information About You For Various Purposes, Including To:",
                    "Sharing of Information",
                    "I. We May Share Personal Information About You As Follows:",
                    "Third Party Analytics",
                    "Security",
                    "I. Your Information Choices",
                    "II. Location Information",
                    "III. Cookies",
                    "IV. Promotional Communications",
                    "Contact Us"
    ]
    
    
    
    var ppTexts = ["Our privacy policy applies to information we collect when you use or access our website, application, or just interact with us. We may change this privacy policy from time to time. Whenever we make changes to this privacy policy, the changes are effective 24 hours after we post the revised privacy policy (as indicated by revising the date at the top of our privacy policy). We encourage you to review our privacy policy whenever you access our services to stay informed about our information practices and the ways you can help protect your privacy.",
                   
                   "We collect information you provide directly to us. For example, we collect information when you participate in any interactive features of our services, fill out a form, request customer support, provide any contact or identifying information or otherwise communicate with us. The types of information we may collect include your name, email address, postal address, credit card information, your content, and other contact or identifying information you choose to provide.",
                   
                   "",
                   
                   "When you access or use our services, we automatically collect information about you, including:\n\n• Log Information: We log information about your use of our services, including the type of browser you use, access times, pages viewed, your IP address and the page you visited before navigating to our services.\n• Device Information: We collect information about the computer you use to access our services, including the hardware model, and operating system and version.\n• Location Information: We may collect information about the location of your device each time you access or use one of our mobile applications or otherwise consent to the collection of this information.\n• Information Collected by Cookies and Other Tracking Technologies: We use various technologies to collect information, and this may include sending cookies to your computer. Cookies are small data files stored on your hard drive or in your device memory that helps us to improve our services and your experience, see which areas and features of our services are popular and count visits. We may also collect information using web beacons (also known as 'tracking pixels'). Web beacons are electronic images that may be used in our services or emails and to track count visits or understand usage and campaign effectiveness.\n\nFor more details about how we collect information, including details about cookies and how to disable them, please see 'Your Information Choices' below.",
        
        "In order to provide you with access to the Service, or to provide you with better service in general, we may combine information obtained from other sources (for example, a third-party service whose application you have authorized or used to sign in) and combine that with information we collect through our services.",
        "",
        "• Provide, maintain and improve our services.\n• Provide services you request, process transactions and to send you related information.\n• Send you technical notices, updates, security alerts and support and administrative messages.\n• Respond to your comments, questions and requests and provide customer service.\n• Communicate with you about news and information related to our service.\n• Monitor and analyze trends, usage and activities in connection with our services.\n• Personalize and improve our services.\n• By accessing and using our services, you consent to the processing and transfer of your information in and to the United States and other countries.",
        "",
        "• If we believe disclosure is reasonably necessary to comply with any applicable law, regulation, legal process or governmental request.\n• To enforce applicable user agreements or policies, including our Terms of Service (please refer to the row titled “Terms of Service” in settings); and to protect us, our users or the public from harm or illegal activities.\n• In connection with any merger, sale of Redplanet assets, financing or acquisition of all or a portion of our business to another company.\n• If we notify you through our services (or in our Privacy Policy) that the information you provide will be shared in a particular manner and you provide such information.\n• We may also share aggregated or anonymized information that does not directly identify you.",
        "We may allow third parties to provide analytics services. These third parties may use cookies, web beacons and other technologies to collect information about your use of the services and other websites, including your IP address, web browser, pages viewed, time spent on pages, links clicked and conversion information. This information may be used by us and third parties to, among other things, analyze and track data, determine the popularity of certain content and other websites and better understand your online activity. Our privacy policy does not apply to, and we are not responsible for, third party cookies, web beacons or other tracking technologies and we encourage you to check the privacy policies of these third parties to learn more about their privacy practices.",
        "We take reasonable measures to help protect personal information from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.",
        "When you first sign up for Redplanet, your account is automatically private. In Settings, in the row titled 'Privacy,' there should be a switch. Turn it off to make your account public so you can appear in the Explore section of the app for people to follow you.",
        "When you first launch any of our mobile applications that collect location information, you will be asked to consent to the application's collection of this information. If you initially consent to our collection of location information, you can subsequently stop the collection of this information at any time by changing the preferences on your mobile device. [If you do so, our mobile applications, or certain features thereof, will no longer function.] You may also stop our collection of location information by following the standard uninstall process to remove all of our mobile applications from your device.",
        "Most web browsers are set to accept cookies by default. If you prefer, you can usually choose to set your browser to remove or reject browser cookies. Please note that if you choose to remove or reject cookies, this could affect the availability and functionality of our services.",
        "You may opt out of receiving any promotional emails from us by following the instructions in those emails. If you opt out, we may still send you non-promotional communications, such as those about your account or our ongoing business relations.",
        "If you have any questions about this privacy policy, please contact us at:\n•Phone: (201) -281-3502\n•Email: redplanethub@gmail.com"
        ]
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set tableView Height
        self.tableView!.setNeedsLayout()
        self.tableView!.layoutSubviews()
        self.tableView!.layoutIfNeeded()
        self.tableView!.estimatedRowHeight = 125
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
        return 16
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ppCell", for: indexPath) as! PrivacyPolicyCell

        if indexPath.row == 0 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 1 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 2 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 3 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 4 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 5 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 6 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 7 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 8 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 9 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 10 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 11 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 12 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 13 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 14 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 15 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 16 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        
        if indexPath.row == 17 {
            cell.ppTitle.text! = ppTitles[indexPath.row]
            cell.ppText.text! = ppTexts[indexPath.row]
        }
        

        return cell
    }


}
