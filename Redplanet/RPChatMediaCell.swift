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

class RPChatMediaCell: UITableViewCell {
    
    
    // Initialize Parent View Controller
    var delegate: UIViewController?
    
    // Initialize object
    var mediaObject: PFObject?
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpMediaAsset: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!

    
    // Function to zoom
    func zoom(sender: AnyObject) {
        
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpMediaAsset.image!)
        agrume.statusBarStyle = UIStatusBarStyle.lightContent
        agrume.showFrom(self.delegate!.self)
    }
    
    
    // Function to play video
    func playVideo() {

        if let video = mediaObject!.value(forKey: "videoAsset") as? PFFile {
            // Traverse video url
            let videoUrl = NSURL(string: video.url!)
            // MARK: - Periscope Video View Controller
            let videoViewController = VideoViewController(videoURL: videoUrl as! URL)
            self.delegate?.present(videoViewController, animated: true, completion: nil)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set tap methods depending on type of media
        if self.mediaObject?.value(forKey: "photoAsset") != nil {
            print("Photo Cell")
            // PHOTO
            
            // Add tap gesture to zoom in
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.rpMediaAsset.isUserInteractionEnabled = true
            self.rpMediaAsset.addGestureRecognizer(zoomTap)
            
        } else if self.mediaObject?.value(forKey: "videoAsset") != nil {
            
            print("Video Cell")
            
            // VIDEO
            // Add tap gesture to play video
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.rpMediaAsset.isUserInteractionEnabled = true
            self.rpMediaAsset.addGestureRecognizer(playTap) 
        }
        
        
    }
    
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
