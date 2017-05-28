//
//  RPChatMediaCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 10/17/16.
//  Copyright © 2016 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import VIMVideoPlayer
import ReadabilityKit

class RPChatMediaCell: UITableViewCell {
    
    // Initialize Parent View Controller
    var delegate: UIViewController?
    // Initialize PFObject
    var postObject: PFObject?
    
    // MARK: - VIMVideoPLayerView
    var vimVideoPlayerView: VIMVideoPlayerView!

    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpMediaPreview: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var container: UIView!
    
    // FUNCTION - Zoom into photo; "ph" || "sti"
    func zoom() {
        // Mark: - Agrume
        let agrume = Agrume(image: rpMediaPreview.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    // FUNCTION - Play video; "vi"
    func playVideo() {
        // MARK: - SubtleVolume
        let subtleVolume = SubtleVolume(style: .dots)
        subtleVolume.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 3)
        subtleVolume.animation = .fadeIn
        subtleVolume.barTintColor = UIColor.black
        subtleVolume.barBackgroundColor = UIColor.white
        
        if let video = postObject!.value(forKey: "videoAsset") as? PFFile {
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            let viewController = UIViewController()
            // MARK: - VIMVideoPlayer
            let vimVideoPlayerView = VIMVideoPlayerView(frame: UIScreen.main.bounds)
            vimVideoPlayerView.player.isLooping = true
            vimVideoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimVideoPlayerView.player.setURL(URL(string: video.url!)!)
            vimVideoPlayerView.player.play()
            viewController.view.addSubview(vimVideoPlayerView)
            viewController.view.bringSubview(toFront: vimVideoPlayerView)
            viewController.view.addSubview(subtleVolume)
            viewController.view.bringSubview(toFront: subtleVolume)
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.delegate?.present(rpPopUpVC, animated: true, completion: nil)
        }
    }
    
    // FUNCTION - Show story; "itm"
    func showStory() {
        // ChatStoryVC
        let chatStoryVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "chatStoryVC") as! ChatStory
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: chatStoryVC)
        self.delegate?.present(rpPopUpVC, animated: true, completion: nil)
    }
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject) {

        // (1) Set usernames depending on who sent what
        if (withObject.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! {
            // Set Current user's username
            self.rpUsername.text! = PFUser.current()!.value(forKey: "realNameOfUser") as! String
        } else {
            // Set username
            self.rpUsername.text! = chatUserObject.last!.value(forKey: "realNameOfUser") as! String
        }
        
        // (2) Get and set user's profile photos
        if (withObject.object(forKey: "receiver") as! PFUser).objectId! == PFUser.current()!.objectId! && (withObject.object(forKey: "sender") as! PFUser).objectId! == chatUserObject.last!.objectId! {
        // RECEIVER == CURRENTUSER
            // Get and set profile photo
            if let proPic = chatUserObject.last!.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        } else if (withObject.object(forKey: "sender") as! PFUser).objectId! == PFUser.current()!.objectId! && (withObject.object(forKey: "receiver") as! PFUser).objectId! == chatUserObject.last!.objectId! {
        // SENDER == CURRENTUSER
            // Get and set Profile Photo
            if let proPic = PFUser.current()!.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
        }
        
        
        
        // (3) Fetch Media Asset
        if let photo = withObject.value(forKey: "photoAsset") as? PFFile {
        // PHOTO
            
            // MARK: - SDWebImage
            self.rpMediaPreview.sd_setShowActivityIndicatorView(true)
            self.rpMediaPreview.sd_setIndicatorStyle(.gray)
            self.rpMediaPreview.sd_setImage(with: URL(string: photo.url!)!, placeholderImage: self.rpMediaPreview.image)
            
            // (A) REGULAR:  PHOTO OR STICKER
            if withObject.value(forKey: "contentType") as! String == "ph" || withObject.value(forKey: "contentType") as! String == "sti" {
                // MARK: - RPExtensions
                self.rpMediaPreview.roundAllCorners(sender: rpMediaPreview)
                
                // Add Zoom Tap
                let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
                zoomTap.numberOfTapsRequired = 1
                rpMediaPreview.isUserInteractionEnabled = true
                rpMediaPreview.addGestureRecognizer(zoomTap)
                
            } else if withObject.value(forKey: "contentType") as! String == "itm" {
                // (B) MOMENT
                // MARK: - RPExtensions
                rpMediaPreview.makeCircular(forView: rpMediaPreview,
                                            borderWidth: 3,
                                            borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
                
                // Add Moment Tap
                let momentTap = UITapGestureRecognizer(target: self, action: #selector(showStory))
                momentTap.numberOfTapsRequired = 1
                rpMediaPreview.isUserInteractionEnabled = true
                rpMediaPreview.addGestureRecognizer(momentTap)
            }
        }
        
        if let videoFile = withObject.value(forKey: "videoAsset") as? PFFile {
        // VIDEO
            
            // MARK: - VIMVideoPLayerView
            vimVideoPlayerView = VIMVideoPlayerView(frame: self.rpMediaPreview.bounds)
            vimVideoPlayerView.player.isLooping = true
            vimVideoPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
            vimVideoPlayerView.player.setURL(URL(string: videoFile.url!)!)
            vimVideoPlayerView.player.isMuted = true
            vimVideoPlayerView.player.play()
            self.rpMediaPreview.addSubview(vimVideoPlayerView)
            
            
            // Add Play Tap
            let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
            playTap.numberOfTapsRequired = 1
            rpMediaPreview.isUserInteractionEnabled = true
            rpMediaPreview.addGestureRecognizer(playTap)
            
            if withObject.value(forKey: "contentType") as! String == "vi" {
                // (A) REGULAR: VIDEO; Draw Purple Border
                // MARK: - RPExtensions
                rpMediaPreview.makeCircular(forView: rpMediaPreview, borderWidth: 0, borderColor: UIColor.clear)
            } else {
                // (B) MOMENT; Make circular
                // MARK: - RPExtensions
                rpMediaPreview.makeCircular(forView: rpMediaPreview,
                                            borderWidth: 3,
                                            borderColor: UIColor(red: 1, green: 0, blue: 0.31, alpha: 1))
            }
        }

        // (5) Set time
        let from = withObject.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPHelpers
        self.time.text = "\(difference.getFullTime(difference: difference, date: from))"
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset rpMediaPreview
        self.rpMediaPreview.contentMode = .scaleAspectFill
        self.rpMediaPreview.straightenCorners(sender: self.rpMediaPreview)
        self.rpMediaPreview.layer.borderColor = UIColor.clear.cgColor
        self.rpMediaPreview.layer.borderWidth = 0
        self.rpMediaPreview.image = UIImage()
        
        // MARK: - VIMVideoPlayerView
        self.vimVideoPlayerView?.removeFromSuperview()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // MARK: - RPExtensions; Make rpUserProPic Circular
        self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
    }

}
