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

    
    // Array to hold contacts
    var contactNumbers = [String]()

    // Storing Contact Objects
    var results = [CNContact]()

    
    // Variable to hold friend objects
    var friends = [PFObject]()
    
    // Users who are not yet friends
    var notFriends = [PFObject]()
    
    
    // Initiaize AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    @IBAction func backButton(_ sender: Any) {
        // Quyery relationships
        appDelegate.queryRelationships()
        
        // POP VC
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func phoneNumber(_ sender: Any) {
        // Change phone number
        configureNumber(sender: self)
    }
    
    
    // Function to save or edit phone number
    func configureNumber(sender: Any) {
        // Present PhoneNumber
        let numberVC = self.storyboard?.instantiateViewController(withIdentifier: "currentUserNumberVC") as! CurrentUserNumber
        self.navigationController?.pushViewController(numberVC, animated: false)
    }
    
    // Function to fetch user's contacts
    func getPhoneContacts() {
        // Clear arrays
        contactNumbers.removeAll(keepingCapacity: false)
        results.removeAll(keepingCapacity: false)

        // Initialize CNContactStore object
        let contactStore = CNContactStore()
        
        // Set predicates for Contacts' values and traverse to any object
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
        ] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                // Appenc to CNContacts
                results.append(contentsOf: containerResults)
                
                // Fetch phone number and traverse it as String value
                for contact: CNContact in results {
                    if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
                        for phoneNumber: CNLabeledValue in contact.phoneNumbers {
                            var number = phoneNumber.value.stringValue
                            number = number.replacingOccurrences(of: ")", with: "") // (
                            number = number.replacingOccurrences(of: "(", with: "") // )
                            number = number.replacingOccurrences(of: " ", with: "") // SPACE
                            number = number.replacingOccurrences(of: "+1 ", with: "") // +1
                            number = number.replacingOccurrences(of: "1 ", with: "") // 1SPACE
                            number = number.replacingOccurrences(of: "-", with: "") // -
                            number = number.replacingOccurrences(of: "1 ", with: "")
                            
                            // Append clean number
                            self.contactNumbers.append(number)
                        }
                    }
                }
                
                
                // Fetch users
                fetchRedplanetters()

                
            } catch {
                print("Error fetching results for container")
            }
        }
        
    }
    
    
    // Function to fetch Redplanetters
    func fetchRedplanetters() {
        // Query Relationships
        appDelegate.queryRelationships()
        
        // Find users
        let user = PFUser.query()!
        user.whereKey("phoneNumber", containedIn: self.contactNumbers)
        user.findObjectsInBackground(block: {
            (objects: [PFObject]?, error: Error?) in
            if error == nil {
                
                // Clear array
                self.friends.removeAll(keepingCapacity: false)
                self.notFriends.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if myFriends.contains(where: {$0.objectId! == object.objectId!}) {
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
        
        // Get contacts from device
        getPhoneContacts()
        
        // Reload data
        self.tableView!.reloadData()
    }
    
    
    // Function to check whether user has number
    func checkNumber() {
        if PFUser.current()!["phoneNumber"] != nil {
            
            // Dismiss Progress
            SVProgressHUD.dismiss()
            
            // Set boolean that number DOES EXIST
            numberExists = true
            
            // Get user's contacts in phone
            self.getPhoneContacts()
            
            // DZNEmptyDataSet
            self.tableView!.tableFooterView = UIView()
            
        } else {
            
            // Dismiss Progress
            SVProgressHUD.dismiss()
            
            // Set boolean that number DOES NOT EXIST
            numberExists = false
            
            // Show alert
            configureNumber(sender: self)
            
            // DZNEmptyDataset
            self.tableView!.emptyDataSetSource = self
            self.tableView!.emptyDataSetDelegate = self
            self.tableView!.tableFooterView = UIView()
        }
        
        print("NUMBEREXISTS: \(numberExists)")
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
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [ NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: navBarFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Contacts"
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress
        SVProgressHUD.show()
        SVProgressHUD.setBackgroundColor(UIColor.white)
        
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return notFriends.count
        } else {
            return myFriends.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        label.font = UIFont(name: "AvenirNext-Medium", size: 19.00)
        
        if section == 0 {
            
            label.text = " • Redplaneters in Contacts"
            return label
            
        } else {
            
            label.text = " • Friends"
            return label
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 44
        } else {
            return 44
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
        
        // Instantiate parent class
        cell.delegate = self
        
        if indexPath.section == 0 {
            // Set user's object contained in UITableViewCell
            cell.friend = notFriends[indexPath.row]
            
            // Check whether user has a full name
            cell.rpUsername.text! = notFriends[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // Set button
            if myRequestedFriends.contains(where: {$0.objectId! == notFriends[indexPath.row].objectId!}) || requestedToFriendMe.contains(where: {$0.objectId! == notFriends[indexPath.row].objectId!}) {
                
                // Change button's title and design
                cell.friendButton.setTitle("Friend Requested", for: .normal)
                cell.friendButton.setTitleColor(UIColor.white, for: .normal)
                cell.friendButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                cell.friendButton.layer.cornerRadius = 22.00
                cell.friendButton.clipsToBounds = true
                
            } else {
                
                // Set user's friends button
                cell.friendButton.setTitle("Friend", for: .normal)
                cell.friendButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                cell.friendButton.backgroundColor = UIColor.white
                cell.friendButton.layer.cornerRadius = 22.00
                cell.friendButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                cell.friendButton.layer.borderWidth = 2.00
                cell.friendButton.clipsToBounds = true
                
            }
        } else {
            // Set user's object contained in UITableViewCell
            cell.friend = myFriends[indexPath.row]
            
            // Check whether user has a full name
            cell.rpUsername.text! = myFriends[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // Change button's title and design
            cell.friendButton.setTitle("Friends", for: .normal)
            cell.friendButton.setTitleColor(UIColor.white, for: .normal)
            cell.friendButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            cell.friendButton.layer.cornerRadius = 22.00
            cell.friendButton.clipsToBounds = true
        }

        return cell
    } // end cellForRowAt


}
