//
//  ChatsCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/16/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import SVProgressHUD
import SimpleAlert

class ChatsCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    var userObject: PFObject?
    

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var status: UIImageView!
    
    
    // Function to delete chats
    func deleteChat() {
        
        // MARK: - SimpleAlert
        // Present alert
        let alert = AlertController(title: "\(self.rpUsername.text!)\nDelete Chat Forever?",
                                    message: "Both you and \(self.rpUsername.text!) can't restore this chat once it's deleted.",
            style: .alert)
        
        // Design content view
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.backgroundColor = UIColor.white
                view.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 21)
                view.titleLabel.textColor = UIColor.black
                view.messageLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
                view.messageLabel.textColor = UIColor.black
                view.textBackgroundView.layer.cornerRadius = 3.00
                view.textBackgroundView.clipsToBounds = true
                
            }
        }
        
        // Design corner radius
        alert.configContainerCornerRadius = {
            return 14.00
        }
        
        let yes = AlertAction(title: "Yes",
                              style: .destructive,
                              handler: { (AlertAction) in
                                
                                // Show Progress
                                SVProgressHUD.show()
                                SVProgressHUD.setForegroundColor(UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0))
                                SVProgressHUD.setBackgroundColor(UIColor.white)
                                
                                // Delete chats
                                let sender = PFQuery(className: "Chats")
                                sender.whereKey("sender", equalTo: PFUser.current()!)
                                sender.whereKey("receiver", equalTo: self.userObject!)
                                
                                let receiver = PFQuery(className: "Chats")
                                receiver.whereKey("receiver", equalTo: PFUser.current()!)
                                receiver.whereKey("sender", equalTo: self.userObject!)
                                
                                let chats = PFQuery.orQuery(withSubqueries: [sender, receiver])
                                chats.findObjectsInBackground(block: {
                                    (objects: [PFObject]?, error: Error?) in
                                    if error == nil {
                                        
                                        // Dismiss progress
                                        SVProgressHUD.dismiss()
                                        
                                        // Delete all objects
                                        PFObject.deleteAll(inBackground: objects, block: {
                                            (success: Bool, error: Error?) in
                                            if success {
                                                print("Deleted all objects: \(objects)")
                                            } else {
                                                print(error?.localizedDescription as Any)
                                            }
                                        })
                                        
                                        // Reload data
                                        NotificationCenter.default.post(name: mainChat, object: nil)
                                        
                                    } else {
                                        if (error?.localizedDescription.hasSuffix("offline."))! {
                                            SVProgressHUD.dismiss()
                                        }
                                        
                                        // Reload data
                                        NotificationCenter.default.post(name: mainChat, object: nil)
                                    }
                                })
        })
        
        let no = AlertAction(title: "No",
                             style: .cancel,
                             handler: nil)
        
        
        alert.addAction(no)
        alert.addAction(yes)
        alert.view.tintColor = UIColor.black
        self.delegate?.present(alert, animated: true, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hold onto the chat to delete it
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(deleteChat))
        hold.minimumPressDuration = 0.30
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(hold)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
