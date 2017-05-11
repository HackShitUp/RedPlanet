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
    @IBOutlet weak var moreButton: UIButton!
    
    func addVideo(videoURL: URL?) {
        // MARK: - RPVideoPlayerView
        rpVideoPlayer = RPVideoPlayerView(frame: self.contentView.bounds)
        rpVideoPlayer.setupVideo(videoURL: videoURL!)
        self.contentView.addSubview(rpVideoPlayer)
        rpVideoPlayer.autoplays = false
        rpVideoPlayer.playbackLoops = false
//        rpVideoPlayer.play()
        
        // Bring buttons to front
        let buttons = [self.rpUsername, self.time, self.moreButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }
    
    func updateView() {
        // Bring buttons to front
        let buttons = [self.rpUsername, self.time, self.moreButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }


    override func prepareForReuse() {
        super.prepareForReuse()
//        rpVideoPlayer?.play()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    

}
