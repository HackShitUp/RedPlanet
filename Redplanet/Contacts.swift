//
//  Contacts.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/10/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import Contacts
import ContactsUI

import Parse
import ParseUI
import Bolts



import SVProgressHUD
import DZNEmptyDataSet
import OneSignal



// Global boolean to check whether user has entered his or her number
var numberExists = false

// Define Notification
let contactsNotification = Notification.Name("contacts")

// Set for iOS 9 +
@available(iOS 9, *)
class Contacts: UITableViewController, UINavigationControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    
    
    // Initialize CNContactStore
    let store = CNContactStore()
    
    // Global variable to hold contacts
    var contactNames = [String]()
    var contactNumbers = [String]()
    
    var contactList: [CNContact]!

    
    // Variable to hold friend objects
    var friends = [PFObject]()
    
    // Users who are not yet friends
    var notFriends = [PFObject]()
    
    
    // Initiaize AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // Function to fetch user's contacts
    func getPhoneContacts() {
        // Fetch contacts
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: { (success, error) in
            if success {
                let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor])
                do {
                    self.contactList = []
                    try store.enumerateContacts(with: request, usingBlock: { (contact, status) in
                        self.contactList.append(contact)
                    })
                } catch {
                    print("Error")
                }
                OperationQueue.main.addOperation({
                    self.tableView.reloadData()
                })
            }
        })
    }
    
    
    // Function to fetch Redplanetters
    func fetchRedplanetters() {
        // Query Relationships
        appDelegate.queryRelationships()
        
        // Find users
        let user = PFUser.query()!
        user.whereKey("phoneNumber", containedIn: contactNumbers)
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                self.notFriends.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if myFriends.contains(object) {
                        self.friends.append(object)
                    } else {
                        self.notFriends.append(object)
                    }
                }
                
                
                
                
                // Load alert if no friends were found
                if self.notFriends.count == 0 {
                    // Show Alert
                    let alert = UIAlertController(title: "No Friends on Redplanet",
                                                  message: "Your Friends Aren't on Redplanet 😕",
                                                  preferredStyle: .alert)
                    
                    let inviteFriends = UIAlertAction(title: "Invite Friends",
                                                      style: .default,
                                                      handler: {(alertAction: UIAlertAction!) in
                                                        
                                                        let textToShare = "🦄 Let's be friends on Redplanet! It's a new app that curates your newsfeeds in a fun way."
                                                        if let myWebsite = NSURL(string: "https://itunes.apple.com/us/app/redplanet/id1120915322?ls=1&mt=8") {
                                                            let objectsToShare = [textToShare, myWebsite] as [Any]
                                                            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                                                            self.present(activityVC, animated: true, completion: nil)
                                                        }
                    })
                    
                    let ok = UIAlertAction(title: "ok",
                                           style: .default,
                                           handler: nil)
                    
                    alert.addAction(inviteFriends)
                    alert.addAction(ok)
                    alert.view.tintColor = UIColor.black
                    self.present(alert, animated: true, completion: nil)
                }
                
                
                
                // Reload data
                self.tableView!.reloadData()
                
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
    }
    
    
    
    // Reload data
    func refresh() {
        
        // Reload relationships
        appDelegate.queryRelationships()
        
        // Get contacts from device
        getPhoneContacts()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Function to check whether user has number
    func checkNumber() -> Bool {
        let number = PFUser.query()!
        number.whereKey("username", equalTo: PFUser.current()!.username!)
        number.findObjectsInBackground(block:  {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Dismiss Progress
                SVProgressHUD.dismiss()
                
                for object in objects! {
                    if object["phoneNumber"] != nil {
                        
                        // Get user's contacts in phone
                        self.getPhoneContacts()
                        
                        // Set boolean that number does not exist
                        numberExists = true
                        
                        // DZNEmptyDataSet
                        self.tableView!.tableFooterView = UIView()
                        
                    } else {
                        
                        // Set boolean that number exists
                        numberExists = false
                        
                        // Dismiss Progress
                        SVProgressHUD.dismiss()
                        
                        // DZNEmptyDataset
                        self.tableView!.emptyDataSetSource = self
                        self.tableView!.emptyDataSetDelegate = self
                        self.tableView!.tableFooterView = UIView()
                    }
                    
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        })
        
        
        print("NUMBEREXISTS: \(numberExists)")
        return numberExists
    }
    
    
    
    
    // MARK: - DZNEmptyDataSet
    // Display Data set
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        
        if numberExists == false {
            return true
        } else {
            return false
        }
        
    }
    
    // Title for EmptyDataSet
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Contacts"
        let font = UIFont(name: "AvenirNext-Medium", size: 21.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        
        
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let str = "No New Friends.\nRedplanet is more fun with your friends! Find friends in your contacts, by tapping the 📞 button at the top right to get started."
        let font = UIFont(name: "AvenirNext-Medium", size: 15.0)
        let attributeDictionary: [String: AnyObject]? = [
            NSForegroundColorAttributeName: UIColor.gray,
            NSFontAttributeName: font!
        ]
        return NSAttributedString(string: str, attributes: attributeDictionary)
    }
    
    
    
    // Change the font and size of nav bar text
    func configureView() {
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [ NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: navBarFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        
        // Check whether current user has entered his/her number
        checkNumber()
        
        // Set blank tablView
        self.tableView!.emptyDataSetDelegate = self
        self.tableView!.emptyDataSetSource = self
        self.tableView!.tableFooterView = UIView()
        
        
        // Add to NSNotificationCenter reload method
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: contactsNotification, object: nil)
        
        // Style navigation bar's title
        configureView()
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
        return notFriends.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell

        // Query relationships
        appDelegate.queryRelationships()
        
        // Instantiate parent class
        cell.delegate = self
        
        // Set user's object contained in UITableViewCell
        cell.friend = notFriends[indexPath.row]
        
        // Check whether user has a full name
        cell.rpUsername.text! = notFriends[indexPath.row].value(forKey: "realNameOfUser") as! String

        // Set button
        if myRequestedFriends.contains(notFriends[indexPath.row]) || requestedToFriendMe.contains(notFriends[indexPath.row]) {
            
            cell.friendButton.setTitle("Friend Requested", for: .normal)
            
            // Set title color
            cell.friendButton.setTitleColor(UIColor.white, for: .normal)
            // Set background color
            cell.friendButton.backgroundColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0)
            // Set borderWidth
            cell.friendButton.layer.borderWidth = 1.50
            // Set border radius
            cell.friendButton.layer.cornerRadius = 22.00
            // Clip
            cell.friendButton.clipsToBounds = true
            
        } else {
            
            cell.friendButton.setTitle("Friend", for: .normal)
            
            // Set titleColor
            cell.friendButton.setTitleColor( UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0), for: .normal)
            // Set background color
            cell.friendButton.backgroundColor = UIColor.white
            // Set borderColor
            cell.friendButton.layer.borderColor = UIColor(red: 1, green: 0, blue: 0.2627, alpha: 1.0).cgColor
            // Set borderWidth
            cell.friendButton.layer.borderWidth = 1.50
            // Clip
            cell.friendButton.clipsToBounds = true
        }

        return cell
    }


}
