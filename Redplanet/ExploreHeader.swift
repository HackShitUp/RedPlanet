//
//  ExploreHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/26/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class ExploreHeader: UICollectionReusableView {
    // Parent VC
    var delegate: UIViewController?

    @IBOutlet weak var adOne: PFImageView!

    // View News
    func viewNews() {
        let newsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "newsVC") as! NewsController
        self.delegate?.navigationController?.pushViewController(newsVC, animated: true)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let newsTap = UITapGestureRecognizer(target: self, action: #selector(viewNews))
        newsTap.numberOfTapsRequired = 1
        self.adOne.isUserInteractionEnabled = true
        self.adOne.addGestureRecognizer(newsTap)
    }
    

}
