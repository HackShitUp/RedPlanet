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
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    func addVideo(videoURL: URL?) {
        // MARK: - RPVideoPlayerView
//        rpVideoPlayer = RPVideoPlayerView(frame: self.contentView.bounds)
//        rpVideoPlayer.setupVideo(videoURL: videoURL!)
//        self.contentView.addSubview(rpVideoPlayer)
//        rpVideoPlayer.autoplays = false
//        rpVideoPlayer.play()
        
        // MARK: - AVPlayer
        let player = AVPlayer(url: videoURL!)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.contentView.bounds
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.contentView.contentMode = .scaleAspectFit
        self.contentView.layer.addSublayer(playerLayer)
        player.isMuted = false
        player.play()

        
        // Bring buttons to front
        let buttons = [self.rpUsername, self.time, self.moreButton,
                       self.numberOfLikes, self.likeButton,
                       self.numberOfComments, self.commentButton,
                       self.numberOfShares, self.shareButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }
    
    func updateView() {
        // Bring buttons to front
        let buttons = [self.rpUsername, self.time, self.moreButton,
                       self.numberOfLikes, self.likeButton,
                       self.numberOfComments, self.commentButton,
                       self.numberOfShares, self.shareButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
}
