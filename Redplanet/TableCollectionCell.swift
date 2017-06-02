//
//  TableCollectionCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/16/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

/*
 UITableViewCell class for "Explore.swift" The protocol in this class, setCollectionViewDataSourceDelegate(_ ) is configured in 
 "Explore.swift"
 */

class TableCollectionCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    func setCollectionViewDataSourceDelegate
        <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (dataSourceDelegate: D, forRow row: Int) {
        // Configure Flow layout...
        if row == 0 || row == 1 {
            let layout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.itemSize = CGSize(width: 125, height: 175)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            layout.scrollDirection = .horizontal
            collectionView.collectionViewLayout = layout
        } else {
            let layout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.itemSize = CGSize(width: 215, height: 125)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            layout.scrollDirection = .horizontal
            collectionView.collectionViewLayout = layout
        }
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
