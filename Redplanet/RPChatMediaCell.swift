//
//  RPChatMediaCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/17/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

//import Agrume



class RPChatMediaCell: UITableViewCell {
    
    
    // Initialize Parent View Controller
    var delegate: UIViewController?
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpMediaAsset: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!

    
    // Function to zoom/
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpMediaAsset.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    
    // Save
    func savePhoto(sender: UILongPressGestureRecognizer) {
        
        let options = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)
        
        let save = UIAlertAction(title: "Save",
                                 style: .default,
                                 handler: {(alertAction: UIAlertAction!) in
                                    
                                    UIImageWriteToSavedPhotosAlbum(self.rpMediaAsset.image!, nil, nil, nil)
                                    
        })
        
        let cancel = UIAlertAction(title: "Cancel",
                                   style: .cancel,
                                   handler: nil)
        options.addAction(save)
        options.addAction(cancel)
        self.delegate?.present(options, animated: true, completion: nil)
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        
        // Add tap gesture to zoom in
        let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
        zoomTap.numberOfTapsRequired = 1
        self.rpMediaAsset.isUserInteractionEnabled = true
        self.rpMediaAsset.addGestureRecognizer(zoomTap)
        
        
        // Hold to save
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(savePhoto))
        hold.minimumPressDuration = 0.50
        self.rpMediaAsset.isUserInteractionEnabled = true
        self.rpMediaAsset.addGestureRecognizer(hold)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
