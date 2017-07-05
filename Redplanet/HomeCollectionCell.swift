//
//  HomeCollectionCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 7/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

/*
 This class shows all the "Collections" a user might be following
 */

class HomeCollectionCell:  UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Initialize UICollectionViewFlowLayout
    let layout = UICollectionViewFlowLayout()
    
    func setCollectionViewDataSourceDelegate
        <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (dataSourceDelegate: D, forRow row: Int) {
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 125, height: 175)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
