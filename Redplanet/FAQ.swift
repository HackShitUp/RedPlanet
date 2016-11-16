//
//  FAQ.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/15/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

/*
 Dear TV, desensitize me
 Give me more genocide please
 The world is your Aphrodisiac so you stay turned on
 Every minute, every second I breathe
 You weaponize greed, kill me with incessant I needs
 Got me checkin' out those and checkin' out these
 Mainstream me, disinfecting my breed
 I'm looking for nirvana but you Geffenize me
 Point me to the skies till heaven's eye bleeds
 Anoint me with your lies then divinize me
 If heaven is a show, well, televise me
 But I won't lie my way in, no fakin' IDs
 I'll die standing. Try breaking my knees
 I'll do a handstand till I'm breakin'
 Now freeze.
 Don't act like you know me cause you recognize me
 You sell my record not me
 */

class FAQ: UITableViewController {
    
    var questions = ["1. Why does Redplanet exist?",
                    "2. If you're friends with someone, are you also following that person?",
                     "3. So what's the difference between friends and following?"]
    
    var answers = ["We believe that Redplanet is the best platform for people to consume news not only about their friends, but also about the world. Redplanet exists because we beleive that your news feed should be delivered and curated the way you want it to, not algorithmically. Redplanet is the only platform where you go to the stories, not vice-versa.",
                   
        "NO. Unlike other social media platforms, Redplanet is built in such a way that these two models of connections are entirely separate from each other.",
        
                   "Because friends and following are two completely differnt relationships, let's go over the few but impactful features that amplify friend-relationships:\n• Only friends can like, comment, or share each other's Profile Photos.\n• Only friends can write in each other's Space. The Space is what we call someone's personal 'territory' on Redplanet.\n•You can only see profile photo updates, space posts, and re-shares in your friends newsfeeds.",
                   "You can only see"]

    
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
        return 3
    }

    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "faqCell", for: indexPath) as! FAQCell

        if indexPath.row == 0 {
            cell.question.text! = questions[indexPath.row]
            cell.answer.text! = answers[indexPath.row]
        }
        
        if indexPath.row == 1 {
            cell.question.text! = questions[indexPath.row]
            cell.answer.text! = answers[indexPath.row]
        }
        
        if indexPath.row == 2 {
            cell.question.text! = questions[indexPath.row]
            cell.answer.text! = answers[indexPath.row]
        }

        return cell
    }


}
