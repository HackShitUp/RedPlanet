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

class Stickers: UICollectionViewController, UINavigationControllerDelegate {
    
    @IBAction func dismiss(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: false)
    }

    let stickers = ["Sun.png",
                    "Pineapple.png",
                        "9.png",
                        "10.png",
                        "11.png",
                        "12.png",
                        "13.png",
                        "14.png",
                        "15.png",
                        "16.png",
                        "17.png",
                        "18.png",
                        "19.png",
                        "20.png",
                        "30.png",
                        "31.png",
                        "32.png",
                        "691505.png",
                        "691504.png",
                        "691502.png",
                        "691501.png",
                        "691499.png",
                        "691498.png",
                        "691497.png",
                        "691496.png",
                        "691495.png",
                        "691494.png",
                        "691493.png",
                        "691491.png",
                        "691490.png",
                        "3018651.png",
                        "3018646.png",
                        "3018638.png",
                        "3018637.png",
                        ]
    
    
    // Function to stylize and set title of navigation bar
    func configureView() {
        // Change the font and size of nav bar text
        if let navBarFont = UIFont(name: "AvenirNext-Medium", size: 21.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navBarFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
            self.title = "Stickers"
        }
        
        // Show tab bar and navigation bar and configure nav bar
        self.navigationController?.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view?.backgroundColor = UIColor.white
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.view.layer.cornerRadius = 12.00
        self.navigationController?.view.clipsToBounds = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()

        self.view.backgroundColor = UIColor.blue
        // Do any additional setup after loading the view, typically from a nib.
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 93.00, height: 93.00)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
        self.collectionView!.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.view.layer.cornerRadius = 00.00
        self.navigationController?.view.clipsToBounds = true
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "stickersCell", for: indexPath) as! StickersCell
        //set contentView frame and autoresizingMask
        cell.contentView.frame = cell.bounds
        
        // LayoutViews
        cell.stickerImage.layoutIfNeeded()
        cell.stickerImage.layoutSubviews()
        cell.stickerImage.setNeedsLayout()
        cell.stickerImage.image = UIImage(named: self.stickers[indexPath.row])
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Send to Chats
        let chat = PFObject(className: "Chats")
        chat["sender"] = PFUser.current()!
        chat["senderUsername"] = PFUser.current()!.username!
        chat["receiver"] = chatUserObject.last!
        chat["receiverUsername"] = chatUserObject.last!.value(forKey: "username") as! String
        chat["photoAsset"] = PFFile(data: UIImagePNGRepresentation(UIImage(named: self.stickers[indexPath.row])!)!)
        chat["read"] = false
        chat.saveInBackground {
            (success: Bool, error: Error?) in
            if error == nil {
                
                // Handle optional chaining
                if chatUserObject.last!.value(forKey: "apnsId") != nil {
                    // MARK: - OneSignal
                    // Send Push Notification to user
                    OneSignal.postNotification(
                        ["contents":
                            ["en": "from \(PFUser.current()!.username!.uppercased())"],
                         "include_player_ids": ["\(chatUserObject.last!.value(forKey: "apnsId") as! String)"],
                         "ios_badgeType": "Increase",
                         "ios_badgeCount": 1
                        ]
                    )
                }
                
                // Reload data for Chats
                NotificationCenter.default.post(name: rpChat, object: nil)
                
                _ = self.navigationController?.popViewController(animated: false)
                
            } else {
                print(error?.localizedDescription as Any)
                
                // Reload data for Chats
                NotificationCenter.default.post(name: rpChat, object: nil)
                
                _ = self.navigationController?.popViewController(animated: false)
            }
        }
    }

    
    // ScrollView -- Pull To Pop
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.collectionView!.contentOffset.y < -80 {
            // Pop view controller
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
    
    

}
