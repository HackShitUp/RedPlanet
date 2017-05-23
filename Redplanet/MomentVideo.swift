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
import VIMVideoPlayer

class MomentVideo: UICollectionViewCell {
    
    // Initialize PFObject
    var postObject: PFObject?
    // Initialize parent UIViewController
    var delegate: UIViewController?
    
    // MARK: - VIMVideoPlayerView
    open var vimVideoPlayerView: VIMVideoPlayerView!

    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject?) {
        // (1) Get and set user's object
        if let user = withObject!.value(forKey: "byUser") as? PFUser {
            // Set username
            self.rpUsername.setTitle("\(user.value(forKey: "username") as! String)", for: .normal)
        }
        
        // (2) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (3) Add video
        if let video = withObject!.value(forKey: "videoAsset") as? PFFile {
            // MARK: - VIMVideoPlayer
            vimVideoPlayerView = VIMVideoPlayerView(frame: self.contentView.bounds)
            vimVideoPlayerView.player.isLooping = true
            vimVideoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
            vimVideoPlayerView.player.setURL(URL(string: video.url!)!)
            self.contentView.addSubview(vimVideoPlayerView)
            self.contentView.bringSubview(toFront: vimVideoPlayerView)
            vimVideoPlayerView.player.isMuted = false
            // Play video in parent UIViewController
        }
        
        // (4) Configure UI
        self.contentView.bringSubview(toFront: rpUsername)
        self.contentView.bringSubview(toFront: time)
        // MARK: - RPExtensions
        rpUsername.layer.applyShadow(layer: rpUsername.layer)
        time.layer.applyShadow(layer: time.layer)
        
        // (5) Add VolumeTap
        let volumeTap = UITapGestureRecognizer(target: self, action: #selector(toggleVolume))
        volumeTap.numberOfTapsRequired = 1
        self.vimVideoPlayerView.isUserInteractionEnabled = true
        self.vimVideoPlayerView.addGestureRecognizer(volumeTap)
    }
    
    // FUNCTION - Tap to unmute
    func toggleVolume(sender: AnyObject) {
        if self.vimVideoPlayerView.player.isMuted {
            self.vimVideoPlayerView.player.fadeInVolume()
            self.vimVideoPlayerView.player.isMuted = false
        } else {
            self.vimVideoPlayerView.player.fadeOutVolume()
            self.vimVideoPlayerView.player.isMuted = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
