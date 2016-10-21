//
//  MyProfile.swift
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


class MyProfile: UICollectionViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView!.backgroundColor = UIColor.white

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: UICollectionViewHeaderSection datasource
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        // ofSize should be the same size of the headerView's label size:
////        return CGSize(width: self.view.frame.size.width, height: self.view.frame.size.height)
//        return CGSize(width: self.view.frame.size.width, height: 400)
//    }
    
    // flowLayout.headerReferenceSize = CGSizeMake(self.collectionView.frame.size.width, 100.f);
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "myHeader", for: indexPath as IndexPath) as! MyHeader
        
        
        // Get Profile Photo
        if let myProfilePhoto = PFUser.current()!["userProfilePicture"] as? PFFile {
            myProfilePhoto.getDataInBackground(block: {
                (data: Data?, error: Error?) in
                if error == nil {
                    // Set profile photo
                    header.myProPic.image = UIImage(data: data!)
                    
                    print("FIRED")
                    
                } else {
                    print(error?.localizedDescription)
                    
                    print("ERROR")
                    
                    // Set default
                    header.myProPic.image = UIImage(named: "Gender Neutral User-96")
                }
            })
        }

        return header
    }


    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myContentCell", for: indexPath) as! MyContentCell
    
        // Configure the cell
    
        return cell
    }


}
