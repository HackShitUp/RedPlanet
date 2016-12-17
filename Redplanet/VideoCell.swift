//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 11/6/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import KILabel
import OneSignal

class VideoCell: UITableViewCell {
    
    // Initialize parent vc
    var delegate: UIViewController?
    
    // Initialize user's object
    var userObject: PFObject?
    
    // Initialize content object
    var contentObject: PFObject?
    
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var videoPreview: PFImageView!
    @IBOutlet weak var caption: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    
    @IBAction func showLikes(_ sender: Any) {
    }
    
    @IBOutlet weak var numberOfComments: UIButton!
    @IBAction func showComments(_ sender: Any) {
    }
    
    @IBOutlet weak var numberOfShares: UIButton!
    @IBAction func showShares(_ sender: Any) {
    }
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBAction func like(_ sender: Any) {
    }
    
    @IBAction func comment(_ sender: Any) {
    }

    @IBAction func share(_ sender: Any) {
    }
    
    // Function to present video
    func playVideo() {

        // Fetch video data
        if let video = self.contentObject!.value(forKey: "videoAsset") as? PFFile {
            // Traverse video url
            let videoUrl = NSURL(string: video.url!)
            // MARK: - Periscope Video View Controller
            let videoViewController = VideoViewController(videoURL: videoUrl as! URL)
            self.delegate?.present(videoViewController, animated: true, completion: nil)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add tap for playing video
        let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
        playTap.numberOfTapsRequired = 1
        self.videoPreview.isUserInteractionEnabled = true
        self.videoPreview.addGestureRecognizer(playTap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
