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

    // Array to hold following objects
    var following = [PFObject]()
    // Array to hold NOT following objects
    var notFollowing = [PFObject]()
    
    // App Delegate
    let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
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
                self.following.removeAll(keepingCapacity: false)
                self.notFollowing.removeAll(keepingCapacity: false)
                
                for object in objects! {
                    if myFollowing.contains(where: {$0.objectId! == object.objectId!}) {
                        self.following.append(object)
                    } else {
                        self.notFollowing.append(object)
                    }
                }
                
                
                
                
                // Load alert if no friends (following) were found
                if self.notFollowing.count == 0 {
                    // Show Alert
                    let alert = UIAlertController(title: "No Friends on Redplanet",
                                                  message: "😕\nYour friends aren't on Redplanet!",
                                                  preferredStyle: .alert)
                    
                    let inviteFriends = UIAlertAction(title: "Invite Friends",
                                                      style: .default,
                                                      handler: {(alertAction: UIAlertAction!) in
                                                        
                                                        let textToShare = "🦄 Let's be friends on Redplanet! It's a new app that curates your newsfeeds in a fun way."
                                                        if let myWebsite = NSURL(string: "https://redplanetapp.com/download/") {
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
        
        // Configure nav bar && hide tab bar (last line)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Style bar
        configureView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Track when on ContactsVC
        Heap.track("ViewingContacts", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        
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
            return notFollowing.count
        } else {
            return following.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "AvenirNext-Demibold", size: 12.00)
        label.textColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        
        if section == 0 {
            label.text = "   REDPLANETERS IN CONTACTS"
            return label
        } else {
            label.text = "   FOLLOWING"
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
        return 65
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
        
        // Instantiate parent class
        cell.delegate = self
        
        if indexPath.section == 0 {
            
            // Sort notFollowing in ABC order
            let notABCFollowing = notFollowing.sorted { ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String) }
            
            // Set user's object contained in UITableViewCell
            cell.userObject = notABCFollowing[indexPath.row]
            
            // Check whether user has a full name
            cell.rpUsername.text! = notABCFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            
            // Configure buttons
            if myRequestedFollowing.contains(where: {$0.objectId! == notABCFollowing[indexPath.row].objectId!}) || myRequestedFollowers.contains(where: {$0.objectId! == notABCFollowing[indexPath.row].objectId!}) {
            // REQUESTED: Follower OR Following
                // Change button's title and design
                cell.followButton.setTitle("Requested", for: .normal)
                cell.followButton.setTitleColor(UIColor.white, for: .normal)
                cell.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                cell.followButton.layer.cornerRadius = 22.00
                cell.followButton.clipsToBounds = true
            } else if myFollowers.contains(where: {$0.objectId! == notABCFollowing[indexPath.row].objectId!}) && !myFollowing.contains(where: {$0.objectId! == notABCFollowing[indexPath.row].objectId!}) {
            // FOLLOWER
                // Change button's title and design
                cell.followButton.setTitle("Follower", for: .normal)
                cell.followButton.setTitleColor(UIColor.white, for: .normal)
                cell.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
                cell.followButton.layer.cornerRadius = 22.00
                cell.followButton.clipsToBounds = true
            } else {
            // NONE
                // Set user's follow button
                cell.followButton.setTitle("Follow", for: .normal)
                cell.followButton.setTitleColor( UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0), for: .normal)
                cell.followButton.backgroundColor = UIColor.white
                cell.followButton.layer.cornerRadius = 22.00
                cell.followButton.layer.borderColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0).cgColor
                cell.followButton.layer.borderWidth = 2.00
                cell.followButton.clipsToBounds = true
            }
            
        } else {
        // FOLLOWING
            
            // Sort Following in ABC order
            let abcFollowing = following.sorted { ($0.value(forKey: "realNameOfUser") as! String) < ($1.value(forKey: "realNameOfUser") as! String) }
            
            // Set user's object contained in UITableViewCell
            cell.userObject = abcFollowing[indexPath.row]
            
            // Check whether user has a full name
            cell.rpUsername.text! = abcFollowing[indexPath.row].value(forKey: "realNameOfUser") as! String
            
            // Change button's title and design
            cell.followButton.setTitle("Following", for: .normal)
            cell.followButton.setTitleColor(UIColor.white, for: .normal)
            cell.followButton.backgroundColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
            cell.followButton.layer.cornerRadius = 22.00
            cell.followButton.clipsToBounds = true
        }

        return cell
    } // end cellForRowAt


}
