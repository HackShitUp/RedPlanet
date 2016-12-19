//
//  TermsOfService.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/11/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

class TermsOfService: UITableViewController, UINavigationControllerDelegate {
    
    
    @IBAction func backButton(_ sender: Any) {
        // Pop VC
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    // Set TOS
    var tosTitles = ["Terms Effective June 16th 2016",
                     "Accepting These Terms",
                     "Changes to These Terms",
                     "I. Privacy Policy",
                     "II. Third-Party Services",
                     "III. Creating Accounts",
                     "IV. Your Content & Conduct",
                     "V. Hyperlinks & Third Party Content",
                     "VI. Unavoidable Legalities",
                     "VII. Copyright Complaints",
                     "VIII. Governing Law",
                     "VIIII. Jurisdiction",
                     "X. Termination",
                     "XI. Entire Agreement",
                     "Feedback",
                     "Questions & Contact Information"
    ]
    
    
    
    var tosTexts = ["These terms of service ('Terms') apply to your access and use of Redplanet (the 'Service'). Please read them carefully.",
        "If you access or use the Service, it means you agree to be bound by all of the terms below. So, before you use the Service, please read all of the terms. If you don't agree to all of the terms below, please do not use the Service. Also, if a term does not make sense to you, please let us know by e-mailing redplanethub@gmail.com.",
                    "We reserve the right to modify these Terms at any time. For instance, we may need to change these Terms if we come out with a new feature or for some other reason.\nWhenever we make changes to these Terms, the changes are effective 24 hours after we post such revised Terms (indicated by revising the date at the top of these Terms) or upon your acceptance if we provide a mechanism for your immediate acceptance of the revised Terms (such as a click-through confirmation or acceptance button). It is your responsibility to check Redplanet for changes to these Terms.\nIf you continue to use the Service after the revised Terms go into effect, then you have accepted the changes to these Terms.",
                    "For information about how we collect and use information about users of the Service, please check out the row titled “Terms & Conditions” in your settings.",
        "From time to time, we may provide you with links to third party websites or services that we do not own or control. Your use of the Service may also include the use of applications that are developed or owned by a third party. Your use of such third party applications, websites, and services is governed by that party's own terms of service or privacy policies. We encourage you to read the terms and conditions and privacy policy of any third party application, website or service that you visit or use.",
        "When you create an account or use another service to log in to the Service, you agree to maintain the security of your password and accept all risks of unauthorized access to any data or other information you provide to the Service.\nIf you discover or suspect any Service security breaches, please let us know as soon as possible.",
        "Our Service allows you and other users to post, link and otherwise make available content. You are responsible for the content that you make available to the Service, including its legality, reliability, and appropriateness.\n\nWhen you post, link or otherwise make available content to the Service, you grant us the right and license to use, reproduce, modify, publicly perform, publicly display and distribute your content on or through the Service. We may format your content for display throughout the Service, but we will not edit or revise the substance of your content itself.\n\nAside from our limited right to your content, you retain all of your rights to the content you post, link and otherwise make available on or through the Service.\n\nYou can remove the content that you posted by deleting it. Once you delete your content, it will not appear on the Service, but copies of your deleted content may remain in our system or backups for some period of time. We will retain web server access logs for a maximum of [168 hours] and then delete them.\n\nYou may not post, link and otherwise make available on or through the Service any of the following:\n\n• Content that is libelous, defamatory, bigoted, fraudulent or deceptive.\n• Content that is illegal or unlawful, that would otherwise create liability.\n• Content that may infringe or violate any patent, trademark, trade secret, copyright, right of privacy, right of publicity or other intellectual or other right of any party.\n• Mass or repeated promotions, political campaigning or commercial messages directed at users who do not follow you (SPAM).\n• Private information of any third party (e.g., addresses, phone numbers, email addresses, Social Security numbers and credit card numbers).\n• Viruses, corrupted data or other harmful, disruptive or destructive files or code.\nAlso, you agree that you will not do any of the following in connection with the Service or other users:\n\n• Use the Service in any manner that could interfere with, disrupt, negatively affect or inhibit other users from fully enjoying the Service or that could damage, disable, overburden or impair the functioning of the Service.\n• Impersonate or post on behalf of any person or entity or otherwise misrepresent your affiliation with a person or entity.\n• Collect any personal information about other users, or intimidate, threaten, stalk or otherwise harass other users of the Service.\n• Create an account or post any content if you are not over 13 years of age years of age.\n• Circumvent or attempt to circumvent any filtering, security measures, rate limits or other features designed to protect the Service, users of the Service, or third parties.\n\nRedplanet Materials\n\nWe put a lot of effort into creating the Service including, the logo and all designs, text, graphics, pictures, information and other content (excluding your content). This property is owned by us or our licensors and it is protected by U.S. and international copyright laws. We grant you the right to use it.\n\nHowever, unless we expressly state otherwise, your rights do not include: (i) publicly performing or publicly displaying the Service; (ii) modifying or otherwise making any derivative uses of the Service or any portion thereof; (iii) using any data mining, robots or similar data gathering or extraction methods; (iv) downloading (other than page caching) of any portion of the Service or any information contained therein; (v) reverse engineering or accessing the Service in order to build a competitive product or service; or (vi) using the Service other than for its intended purposes. If you do any of this stuff, we may terminate your use of the Service.",
        "You may create a hyperlink to the Service. But, you may not use, frame or utilize framing techniques to enclose any of our trademarks, logos or other proprietary information without our express written consent.\n\nRedplanet makes no claim or representation regarding, and accepts no responsibility for third party websites accessible by hyperlink from the Service or websites linking to the Service. When you leave the Service, you should be aware that these Terms and our policies no longer govern.\n\nIf there is any content on the Service from you and others, we don't review, verify or authenticate it, and it may include inaccuracies or false information. We make no representations, warranties, or guarantees relating to the quality, suitability, truth, accuracy or completeness of any content contained in the Service. You acknowledge sole responsibility for and assume all risk arising from your use of or reliance on any content.",
        "THE SERVICE AND ANY OTHER SERVICE AND CONTENT INCLUDED ON OR OTHERWISE MADE AVAILABLE TO YOU THROUGH THE SERVICE ARE PROVIDED TO YOU ON AN AS IS OR AS AVAILABLE BASIS WITHOUT ANY REPRESENTATIONS OR WARRANTIES OF ANY KIND. WE DISCLAIM ANY AND ALL WARRANTIES AND REPRESENTATIONS (EXPRESS OR IMPLIED, ORAL OR WRITTEN) WITH RESPECT TO THE SERVICE AND CONTENT INCLUDED ON OR OTHERWISE MADE AVAILABLE TO YOU THROUGH THE SERVICE WHETHER ALLEGED TO ARISE BY OPERATION OF LAW, BY REASON OF CUSTOM OR USAGE IN THE TRADE, BY COURSE OF DEALING OR OTHERWISE.\n\nIN NO EVENT WILL REDPLANET BE LIABLE TO YOU OR ANY THIRD PARTY FOR ANY SPECIAL, INDIRECT, INCIDENTAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES OF ANY KIND ARISING OUT OF OR IN CONNECTION WITH THE SERVICE OR ANY OTHER SERVICE AND/OR CONTENT INCLUDED ON OR OTHERWISE MADE AVAILABLE TO YOU THROUGH THE SERVICE, REGARDLESS OF THE FORM OF ACTION, WHETHER IN CONTRACT, TORT, STRICT LIABILITY OR OTHERWISE, EVEN IF WE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES OR ARE AWARE OF THE POSSIBILITY OF SUCH DAMAGES. OUR TOTAL LIABILITY FOR ALL CAUSES OF ACTION AND UNDER ALL THEORIES OF LIABILITY WILL BE LIMITED TO THE AMOUNT YOU PAID TO REDPLANET. THIS SECTION WILL BE GIVEN FULL EFFECT EVEN IF ANY REMEDY SPECIFIED IN THIS AGREEMENT IS DEEMED TO HAVE FAILED OF ITS ESSENTIAL PURPOSE.\n\nYou agree to defend, indemnify and hold us harmless from and against any and all costs, damages, liabilities, and expenses (including attorneys' fees, costs, penalties, interest and disbursements) we incur in relation to, arising from, or for the purpose of avoiding, any claim or demand from a third party relating to your use of the Service or the use of the Service by any person using your account, including any claim that your use of the Service violates any applicable law or regulation, or the rights of any third party, and/or your violation of these Terms.",
        "We take intellectual property rights seriously. In accordance with the Digital Millennium Copyright Act ('DMCA') and other applicable law, we have adopted a policy of terminating, in appropriate circumstances and, at our sole discretion, access to the service for users who are deemed to be repeat infringers. Please refer to the row titled “Redplanet”, for more information about issues regarding Copyrights.",
        "The validity of these Terms and the rights, obligations, and relations of the parties under these Terms will be construed and determined under and in accordance with the laws of New Jersey, without regard to conflicts of law principles.",
        "You expressly agree that exclusive jurisdiction for any dispute with the Service or relating to your use of it, resides in the courts of New Jersey and you further agree and expressly consent to the exercise of personal jurisdiction in the courts of New Jersey in connection with any such dispute including any claim involving Service. You further agree that you and Service will not commence against the other a class action, class arbitration or other representative action or proceeding.",
        "If you breach any of these Terms, we have the right to suspend or disable your access to or use of the Service.",
        "These Terms constitute the entire agreement between you and Redplanet regarding the use of the Service, superseding any prior agreements between you and Redplanet relating to your use of the Service.",
        "Please let us know what you think of the Service, these Terms and, in general, Redplanet. When you provide us with any feedback, comments or suggestions about the Service, these Terms and, in general, Redplanet, you irrevocably assign to us all of your right, title and interest in and to your feedback, comments and suggestions.",
                     "Questions or comments about the Service may be directed to us at the email address redplanethub@gmail.com.",
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "tosCell", for: indexPath) as! TOSCell
        

        if indexPath.row == 0 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 1 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 2 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 3 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 4 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 5 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 6 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 7 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 8 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 9 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 10 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 11 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 12 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 13 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 14 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 15 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 16 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        
        if indexPath.row == 17 {
            cell.tosTitle.text! = tosTitles[indexPath.row]
            cell.tosText.text! = tosTexts[indexPath.row]
        }
        

        return cell
    }
    

}
