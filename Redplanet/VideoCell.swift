//
//  VideoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/23/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts
import KILabel
import SafariServices
import SDWebImage
import VIMVideoPlayer

class VideoCell: UICollectionViewCell, VIMVideoPlayerViewDelegate {
    
    // Initialize PFObject
    var postObject: PFObject?
    // Initialize parent UIViewController
    var delegate: UIViewController?
    
    // MARK: - VIMVideoPlayerView
    var vimVideoPlayerView: VIMVideoPlayerView!
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var videoView: VIMVideoPlayerView!
    @IBOutlet weak var textPost: KILabel!
    
    @IBOutlet weak var videoLength: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBAction func playAction(_ sender: Any) {
        if self.vimVideoPlayerView.player.isPlaying {
            self.vimVideoPlayerView.player.fadeOutVolume()
            self.vimVideoPlayerView.player.pause()
            self.playButton.setImage(UIImage(named: "Pause"), for: .normal)
        } else {
            self.vimVideoPlayerView.player.fadeInVolume()
            self.vimVideoPlayerView.player.play()
            self.playButton.setImage(UIImage(named: "Play"), for: .normal)
        }
    }
    
    @IBOutlet weak var volumeButton: UIButton!
    @IBAction func volumeAction(_ sender: Any) {
        if self.vimVideoPlayerView.player.isMuted {
            self.vimVideoPlayerView.player.fadeInVolume()
            self.vimVideoPlayerView.player.isMuted = false
            self.volumeButton.setImage(UIImage(named: "VolumeOn"), for: .normal)
        } else {
            self.vimVideoPlayerView.player.fadeOutVolume()
            self.vimVideoPlayerView.player.isMuted = true
            self.volumeButton.setImage(UIImage(named: "VolumeOff"), for: .normal)
        }
    }
    
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
            self.rpUsername.text = (user.value(forKey: "username") as! String)
            // Get and set user's profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser")!)
                // MARK: - RPExtensions
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.groupTableViewBackground)
            }
        }
        
        // (2) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        self.time.text = "uploaded \(difference.getFullTime(difference: difference, date: from))"
        
        // (3) Add video
        if let video = withObject!.value(forKey: "videoAsset") as? PFFile {
            // Pass <delegate>'s VIMVideoPlayerView object to self
            self.vimVideoPlayerView = videoPlayer!
            
            // MARK: - VIMVideoPlayer
            videoPlayer!.player.isLooping = false
            videoPlayer!.player.setURL(URL(string: video.url!)!)
            videoPlayer!.player.isMuted = false
            videoPlayer!.delegate = self
            videoPlayer!.frame = self.bounds
            videoPlayer!.layoutIfNeeded()
            videoPlayer!.setVideoFillMode(AVLayerVideoGravityResizeAspect)
            self.videoView.backgroundColor = UIColor.black
            self.videoView.addSubview(videoPlayer!)
            self.videoView.bringSubview(toFront: videoPlayer!)
        }
        
        // (4) Configure UI
        let objects = [self.rpUserProPic,
                       self.rpUsername,
                       self.time,
                       self.videoLength,
                       self.playButton,
                       self.volumeButton] as [Any]
        for button in objects {
            self.videoView.bringSubview(toFront: button as! UIView)
            self.videoView.layer.applyShadow(layer: (button as! UIView).layer)
        }
        
        
        // (5) Set text post
        if let text = withObject!.value(forKey: "textPost") as? String {
            if withObject!.value(forKey: "textPost") as! String != "" {
                self.textPost.text = text
            } else {
                self.textPost.isHidden = true
            }
        }
    }
    
    // FUNCTION - Show caption
    func showCaption(sender: AnyObject) {
        // Hide || Show textPost
        self.textPost.isHidden = !self.textPost.isHidden
        
        // Play || Pause depending on textPost
        if self.textPost.isHidden == false {
            self.textPost.layer.applyShadow(layer: self.textPost.layer)
            self.videoView.bringSubview(toFront: self.textPost)
            self.vimVideoPlayerView?.player.pause()
        } else {
            self.vimVideoPlayerView?.player.play()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Hide text post
        self.textPost.isHidden = true
        
        // Add Profile Tap
        let proPicTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        proPicTap.numberOfTapsRequired = 1
        self.rpUserProPic.isUserInteractionEnabled = true
        self.rpUserProPic.addGestureRecognizer(proPicTap)
        
        // Add Username Tap
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(visitProfile))
        nameTap.numberOfTapsRequired = 1
        self.rpUsername.isUserInteractionEnabled = true
        self.rpUsername.addGestureRecognizer(nameTap)
        
        // Add Video Tap
        let videoCaptionTap = UITapGestureRecognizer(target: self, action: #selector(showCaption))
        videoCaptionTap.numberOfTapsRequired = 1
        self.videoView.isUserInteractionEnabled = true
        self.videoView.addGestureRecognizer(videoCaptionTap)
        
        // Add Caption Tap
        let textPostTap = UITapGestureRecognizer(target: self, action: #selector(showCaption))
        textPostTap.numberOfTapsRequired = 1
        self.textPost.isUserInteractionEnabled = true
        self.textPost.addGestureRecognizer(textPostTap)

        // MARK: - SDWebImage
        self.videoView.sd_addActivityIndicator()
        self.videoView.sd_setIndicatorStyle(.white)

        // MARK: - KILabel; @, #, and https://
        // @@@
        self.textPost.userHandleLinkTapHandler = { label, handle, range in
            // Query data
            let user = PFUser.query()!
            user.whereKey("username", equalTo: String(handle.characters.dropFirst()).lowercased())
            user.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                if error == nil {
                    for object in objects! {
                        // Append data
                        otherName.append(String(handle.characters.dropFirst()).lowercased())
                        otherObject.append(object)
                        // Push VC
                        let otherUser = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.delegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        self.textPost.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.delegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
        // https://
        self.textPost.urlLinkTapHandler = { label, handle, range in
            // MARK: - SafariServices
            let webVC = SFSafariViewController(url: URL(string: handle)!, entersReaderIfAvailable: false)
            self.delegate?.navigationController?.present(webVC, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - VIMVideoPlayerView Delegate Methods
    func videoPlayerView(_ videoPlayerView: VIMVideoPlayerView!, timeDidChange cmTime: CMTime) {
        // Create Date()
        let date = Date(timeIntervalSince1970: CMTimeGetSeconds(cmTime))
        // Specify DateFormatter output
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "m:ss"
        // Change text
        self.videoLength.text = "\(dateFormatter.string(from: date))s"
    }
}
