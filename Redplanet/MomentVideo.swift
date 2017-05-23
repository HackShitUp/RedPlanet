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
    var vimPlayerView: VIMVideoPlayerView!

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
//        if let video = withObject!.value(forKey: "videoAsset") as? PFFile {
            // MARK: - VIMVideoPlayer
//            vimPlayerView = VIMVideoPlayerView(frame: self.contentView.bounds)
//            vimPlayerView.player.isLooping = true
//            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
//            vimPlayerView.player.setURL(URL(string: video.url!)!)
//            self.contentView.addSubview(vimPlayerView)
//            self.contentView.bringSubview(toFront: vimPlayerView)
//            vimPlayerView.player.isMuted = true
//            vimPlayerView.player.play()
//        }
        
        // (4) Configure UI
        self.contentView.bringSubview(toFront: rpUsername)
        self.contentView.bringSubview(toFront: time)
        // MARK: - RPExtensions
        rpUsername.layer.applyShadow(layer: rpUsername.layer)
        time.layer.applyShadow(layer: time.layer)
        
//        // (5) Add VolumeTap
//        let volumeTap = UITapGestureRecognizer(target: self, action: #selector(toggleVolume))
//        volumeTap.numberOfTapsRequired = 1
//        self.vimPlayerView.isUserInteractionEnabled = true
//        self.vimPlayerView.addGestureRecognizer(volumeTap)
    }
    
    // FUNCTION - Tap to unmute
    func toggleVolume(sender: AnyObject) {
        if self.vimPlayerView.player.isMuted {
            print("IS MUTED?: \(self.vimPlayerView.player.isMuted)\n")
            self.vimPlayerView.player.fadeInVolume()
            self.vimPlayerView.player.isMuted = false
        } else {
            print("IS___MUTED?: \(self.vimPlayerView.player.isMuted)\n")
            self.vimPlayerView.player.fadeOutVolume()
            self.vimPlayerView.player.isMuted = true
        }
    }
    
    func addVideo(withObject: PFObject?) {
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
