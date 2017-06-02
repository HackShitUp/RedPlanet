//
//  SpacePostCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/22/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import AVKit

import Parse
import ParseUI
import Bolts

import KILabel
import SDWebImage
import VIMVideoPlayer

/*
 MARK: - THIS CLASS RELATES TO POSTS SHARED ON REDPLANET
 UITableViewCell that presents a Space Post shared between 2 users.
 
 • Refers to "sp" in the database class, "Posts", with possible values in the <photoAsset>, <videoAsset> and <textPost> columns.
 - Consistently has a definitive value in the database class, "Posts", in the column, "toUser" and "toUsername"
 
 PARENT CLASS IS ALWAYS "StoryScrollCell.swift"
 */

class SpacePostCell: UITableViewCell {
    
    // Initialized PFObject
    var postObject: PFObject?
    // Initialized parent UIViewController
    var superDelegate: UIViewController?
    
    @IBOutlet weak var byUserProPic: PFImageView!
    @IBOutlet weak var byUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var toUserProPic: PFImageView!
    @IBOutlet weak var toUsername: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var textPost: KILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    
    
    // FUNCTION - Zoom into photo
    func zoom(sender: AnyObject) {
        // MARK: - Agrume
        let agrume = Agrume(image: self.mediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.superDelegate!.self)
    }
    
    // FUNCTION - Play video
    func playVideo(sender: AnyObject) {
        if let video = self.postObject!.value(forKey: "videoAsset") as? PFFile {
            // Remove VIMVideoPlayerView's player's player's playerItem if video exists in STORIES
            if let storiesVC = self.superDelegate! as? Stories {
                storiesVC.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            }
            // Remove VIMVideoPlayerView's player's player's playerItem if video exists in STORY
            if let storyVC = self.superDelegate! as? Story {
                storyVC.vimVideoPlayerView?.player.player.replaceCurrentItem(with: nil)
            }
            
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            let viewController = UIViewController()
            // MARK: - VIMVideoPlayer
            let vimPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
            vimPlayerView.player.isLooping = true
            vimPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimPlayerView.player.setURL(URL(string: video.url!)!)
            vimPlayerView.player.play()
            viewController.view.addSubview(vimPlayerView)
            viewController.view.bringSubview(toFront: vimPlayerView)
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.superDelegate?.present(rpPopUpVC, animated: true, completion: nil)
        }
    }
    
    // FUNCTION - Navigates to sender's profile
    func visitSender(sender: AnyObject) {
        // Traverse user's object
        if let byUser = self.postObject!.object(forKey: "byUser") as? PFUser {
            otherObject.append(byUser)
            otherName.append(byUser.username!)
        }
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Navigate to receivers profile
    func visitReceiver(sender: AnyObject) {
        // Traverse user's object
        if let toUser = self.postObject!.value(forKey: "toUser") as? PFUser {
            otherObject.append(toUser)
            otherName.append(toUser.username!)
        }
        let otherUserVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
        self.superDelegate?.navigationController?.pushViewController(otherUserVC, animated: true)
    }
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject?) {
        
        // MARK: - RPExtensions
        self.byUserProPic.makeCircular(forView: self.byUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        self.toUserProPic.makeCircular(forView: self.toUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
        
        // (1) Get byUser's object
        if let byUser = withObject?.object(forKey: "byUser") as? PFUser {
            // Get and set proPic
            if let proPic = byUser.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.byUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // Set fullName
            self.byUsername.text = (byUser.value(forKey: "realNameOfUser") as! String)
        }
        
        // (2) Get toUser's object
        if let toUser = withObject?.value(forKey: "toUser") as? PFUser {
            // Get and set proPic
            if let proPic = toUser.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.toUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // Set fullName
            self.toUsername.text = (toUser.value(forKey: "realNameOfUser") as! String)
        }
        
        // (3) Set time
        let from = withObject!.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPExtensions
        self.time.text = "shared in \(self.toUsername.text!)'s Space \(difference.getFullTime(difference: difference, date: from))"
        
        // (4) Set text post
        if let text = withObject!.value(forKey: "textPost") as? String {
            // MARK: - RPExtensions
            let formattedString = NSMutableAttributedString()
            _ = formattedString.bold("\((withObject!.object(forKey: "byUser") as! PFUser).username!) ", withFont: UIFont(name: "AvenirNext-Demibold", size: 15)).normal("\(text)", withFont: UIFont(name: "AvenirNext-Medium", size: 15))
            if text != "" {
                self.textPost.attributedText = formattedString
            } else {
                self.textPost.isHidden = true
            }
        }
        
        // (5) Set photo or video
        // MARK: - SDWebImage
        self.mediaPreview.sd_setIndicatorStyle(.gray)
        self.mediaPreview.sd_showActivityIndicatorView()
        // Traverse asset to PFFile
        
        if let photo = withObject?.value(forKey: "photoAsset") as? PFFile {
            // MARK: - SDWebImage
            self.mediaPreview.sd_setImage(with: URL(string: photo.url!))
            // MARK: - RPExtensions
            self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
            
            // Add Zoom Tap
            let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
            zoomTap.numberOfTapsRequired = 1
            self.mediaPreview.isUserInteractionEnabled = true
            self.mediaPreview.addGestureRecognizer(zoomTap)
            
        } else if let video = withObject?.value(forKey: "videoAsset") as? PFFile {
            // MARK: - AVPlayer
            let player = AVPlayer(url: URL(string: video.url!)!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.mediaPreview.bounds
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.mediaPreview.contentMode = .scaleAspectFit
            self.mediaPreview.layer.addSublayer(playerLayer)
            player.isMuted = true
            player.play()
            
            // MARK: - RPExtensions
            self.mediaPreview.makeCircular(forView: self.mediaPreview, borderWidth: 0, borderColor: UIColor.clear)
            
            // Add Play Tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            self.mediaPreview.isUserInteractionEnabled = true
            self.mediaPreview.addGestureRecognizer(playTap)
        }
    }
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Set byUser's Profile Tap
        let byUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(visitSender(sender:)))
        byUserProPicTap.numberOfTapsRequired = 1
        byUserProPic.isUserInteractionEnabled = true
        byUserProPic.addGestureRecognizer(byUserProPicTap)
        let byUsernameTap = UITapGestureRecognizer(target: self, action: #selector(visitSender(sender:)))
        byUsernameTap.numberOfTapsRequired = 1
        byUsername.isUserInteractionEnabled = true
        byUsername.addGestureRecognizer(byUsernameTap)
        // Set toUser's Profile Tap
        let toUserProPicTap = UITapGestureRecognizer(target: self, action: #selector(visitReceiver(sender:)))
        toUserProPicTap.numberOfTapsRequired = 1
        toUserProPic.isUserInteractionEnabled = true
        toUserProPic.addGestureRecognizer(toUserProPicTap)
        let toUsernameTap = UITapGestureRecognizer(target: self, action: #selector(visitReceiver(sender:)))
        toUsernameTap.numberOfTapsRequired = 1
        toUsername.isUserInteractionEnabled = true
        toUsername.addGestureRecognizer(toUsernameTap)
        
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
                        let otherUser = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "otherUser") as! OtherUser
                        self.superDelegate?.navigationController?.pushViewController(otherUser, animated: true)
                    }
                } else {
                    print(error?.localizedDescription as Any)
                }
            })
        }
        // ###
        self.textPost.hashtagLinkTapHandler = { label, handle, range in
            // Show #'s
            let hashtagsVC = self.superDelegate?.storyboard?.instantiateViewController(withIdentifier: "hashtagsVC") as! Hashtags
            hashtagsVC.hashtagString = String(handle.characters.dropFirst()).lowercased()
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: hashtagsVC)
            self.superDelegate?.navigationController?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
