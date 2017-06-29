//
//  Stickers.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/19/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import OneSignal

/*
 UICollectionViewController class that shows the sticker-assets to send in a chat room.
 The UICollectionViewController is used with RPPopUpVC to present this class. The data binded to show the sticker image assets is
 executed in this class. 
 
 Works with "CollectionCell.swift" and "CollectionCell.xib"
 */

class Stickers: UICollectionViewController, UINavigationControllerDelegate {
    // Declare Stickers
    let stickers = ["bruh",
                    "crying",
                    "cute",
                    "dance",
                    "duh",
                    "electrified",
                    "embarrassed",
                    "ew",
                    "faded",
                    "goodbye",
                    "happybirthday",
                    "hello",
                    "icanteven",
                    "ily",
                    "lit",
                    "loveit",
                    "makeout",
                    "nah",
                    "ok",
                    "omg",
                    "question",
                    "sorry",
                    "Sun",
                    "thankyou",
                    "wannachill",
                    "word",
                    "wow",
                    "wtf",
                    "yay",
                    "yougotit",
                    "yourealright"]
    
    
    // MARK: - UIView Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: UIScreen.main.bounds.size.width/4, height: UIScreen.main.bounds.size.width/4)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        
        collectionView!.collectionViewLayout = layout
        collectionView!.reloadData()
        
        // Register NIB
        collectionView!.register(UINib(nibName: "CollectionCell", bundle: nil), forCellWithReuseIdentifier: "CollectionCell")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Configure UIStatusBar
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = .default
        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return stickers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! CollectionCell
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        // Set image
        cell.assetPreview.image = UIImage(named: self.stickers[indexPath.row])
        cell.assetPreview.contentMode = .scaleAspectFit
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Send to Chats
        let chats = PFObject(className: "Chats")
        chats["sender"] = PFUser.current()!
        chats["senderUsername"] = PFUser.current()!.username!
        chats["receiver"] = chatUserObject.last!
        chats["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chats["photoAsset"] = PFFile(data: UIImagePNGRepresentation(UIImage(named: self.stickers[indexPath.row])!)!)
        chats["contentType"] = "sti"
        chats["read"] = false
        chats["saved"] = false
        chats.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                
                // MARK: - RPHelpers; update ChatsQueue, send push notification
                let rpHelpers = RPHelpers()
                rpHelpers.updateQueue(chatQueue: chats, userObject: chatUserObject.last!)
                rpHelpers.pushNotification(toUser: chatUserObject.last!, activityType: "from")
                
                // Reload data for Chats
                NotificationCenter.default.post(name: rpChat, object: nil)
                
                // Dismiss VC
                self.dismiss(animated: true, completion: nil)
                
            } else {
                print(error?.localizedDescription as Any)
                // MARK: - RPHelpers
                let rpHelpers = RPHelpers()
                rpHelpers.showError(withTitle: "Network Error")
            }
        }
    }
    
    
}
