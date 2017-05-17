//
//  MomentVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

class MomentVideo: UICollectionViewCell {
    
    // MARK: - RPVideoPlayerView
    var rpVideoPlayer: RPVideoPlayerView!

    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    
    func addVideo(videoURL: URL?) {
        // MARK: - RPVideoPlayerView
//        rpVideoPlayer = RPVideoPlayerView(frame: self.contentView.bounds)
//        rpVideoPlayer.setupVideo(videoURL: videoURL!)
//        self.contentView.addSubview(rpVideoPlayer)
//        rpVideoPlayer.autoplays = false
//        rpVideoPlayer.playbackLoops = false
//        rpVideoPlayer.play()

        self.rpUsername.layer.applyShadow(layer: self.rpUsername.layer)
        self.time.layer.applyShadow(layer: self.time.layer)
        self.contentView.bringSubview(toFront: self.rpUsername)
        self.contentView.bringSubview(toFront: self.time)
    }
    
    func updateView() {
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
