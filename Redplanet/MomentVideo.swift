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

        // (4) Configure UI
        self.contentView.bringSubview(toFront: rpUsername)
        self.contentView.bringSubview(toFront: time)
        rpUsername.layer.applyShadow(layer: rpUsername.layer)
        time.layer.applyShadow(layer: time.layer)
    }
    
    func addVideo(withObject: PFObject?) {
        print("Fired...")
        if let video = withObject!.value(forKey: "videoAsset") as? PFFile {
            // MARK: - VIMVideoPlayer
            let vimPlayerView = VIMVideoPlayerView(frame: self.contentView.bounds)
            vimPlayerView.player.isLooping = true
            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimPlayerView.player.setURL(URL(string: video.url!)!)
            vimPlayerView.player.play()
            // Add to subview
            self.contentView.addSubview(vimPlayerView)
        }
    }
    

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
