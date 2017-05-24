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
    var vimVideoPlayerView: VIMVideoPlayerView?

    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    
    // FUNCTION - Navigates to user's profile
    func visitProfile(sender: AnyObject) {
        otherObject.append(self.postObject?.value(forKey: "byUser") as! PFUser)
        otherName.append(self.postObject?.value(forKey: "username") as! String)
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject?, videoPlayer: VIMVideoPlayerView?) {
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
            // Pass <delegate>'s VIMVideoPlayerView object to self
            self.vimVideoPlayerView = videoPlayer!
            
            // MARK: - VIMVideoPlayer
            videoPlayer!.frame = self.contentView.bounds
            videoPlayer!.player.isLooping = true
            videoPlayer!.setVideoFillMode(AVLayerVideoGravityResizeAspect)
            videoPlayer!.player.setURL(URL(string: video.url!)!)
            videoPlayer!.player.isMuted = false
            self.contentView.addSubview(videoPlayer!)
            self.contentView.bringSubview(toFront: videoPlayer!)
            
            // Add VolumeTap
            let volumeTap = UITapGestureRecognizer(target: self, action: #selector(toggleVolume))
            volumeTap.numberOfTapsRequired = 1
            videoPlayer!.isUserInteractionEnabled = true
            videoPlayer!.addGestureRecognizer(volumeTap)
            /* Play video in parent UIViewController */
        }
        
        // (4) Configure UI
        self.contentView.bringSubview(toFront: rpUsername)
        self.contentView.bringSubview(toFront: time)
        // MARK: - RPExtensions
        rpUsername.layer.applyShadow(layer: rpUsername.layer)
        time.layer.applyShadow(layer: time.layer)
    }
    
    // FUNCTION - Tap to unmute
    func toggleVolume(sender: AnyObject) {
        if self.vimVideoPlayerView!.player.isMuted {
            self.vimVideoPlayerView!.player.fadeInVolume()
            self.vimVideoPlayerView!.player.isMuted = false
        } else {
            self.vimVideoPlayerView!.player.fadeOutVolume()
            self.vimVideoPlayerView!.player.isMuted = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
    }
    
}
