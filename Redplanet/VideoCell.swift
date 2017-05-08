//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import KILabel
import SDWebImage

class VideoCell: UITableViewCell {
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var videoPreview: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    
    func addVideo(videoURL: URL?) {
        // MARK: - RPVideoPlayerView
        rpVideoPlayer = RPVideoPlayerView(frame: self.videoPreview.bounds)
        rpVideoPlayer.setupVideo(videoURL: videoURL!)
        self.videoPreview.addSubview(rpVideoPlayer)
        rpVideoPlayer.autoplays = false
        rpVideoPlayer.playbackLoops = false
        //        rpVideoPlayer.play()
        
        self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
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
