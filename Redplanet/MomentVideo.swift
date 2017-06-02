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

import SDWebImage
import VIMVideoPlayer


/*
 MARK: - THIS CLASS RELATES TO POSTS SHARED ON REDPLANET
 UICollectionViewCell class that shows the user's video-moment they recorded on Redplanet sharing it
 
 • Referenced as "itm" in database class titled "Posts" under the column, <contentType>, with a definite value in <videoAsset>
 
 The data is binded here when its parent class class the executable functions to do so.
 Works with "Stories.swift", "ChatStory.swift" and "Hashtags.swift"
 */

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
        if let user = self.postObject!.object(forKey: "byUser") as? PFUser {
            otherObject.append(user)
            otherName.append(user.value(forKey: "username") as! String)
        }
        let otherUserVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.delegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject?, videoPlayer: VIMVideoPlayerView?) {
        // (1) Get and set user's object
        if let user = withObject!.object(forKey: "byUser") as? PFUser {
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
            videoPlayer!.player.isLooping = false
            videoPlayer!.player.setURL(URL(string: video.url!)!)
            videoPlayer!.player.isMuted = false
            videoPlayer!.frame = self.bounds
            videoPlayer!.layoutIfNeeded()
            videoPlayer!.setVideoFillMode(AVLayerVideoGravityResizeAspect)
            self.contentView.backgroundColor = UIColor.black
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
        // Set backgroundColor
        self.contentView.backgroundColor = UIColor.black
        
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        
        // MARK: - SDWebImage
        self.contentView.sd_addActivityIndicator()
        self.contentView.sd_setIndicatorStyle(.white)
    }
    
}
