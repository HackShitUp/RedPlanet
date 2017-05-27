//
//  StoryCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/20/17.
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

class StoryCell: UITableViewCell {
    
    // Parent VC
    var delegate: UIViewController?
    // PFObject
    var postObject: PFObject?

    @IBOutlet weak var textPreview: KILabel!
    @IBOutlet weak var mediaPreview: PFImageView!
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    
    // FUNCTION - Show Stories
    func showStories() {
        // Show Stories
        storyObjects.append(self.postObject!)
        let storiesVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storiesVC") as! Stories
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storiesVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true)
    }
    
    // FUNCTION - Add showStories tap
    func addStoriesTap() {
        // Add tap method to viewStory
        let storyTap = UITapGestureRecognizer(target: self, action: #selector(showStories))
        storyTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(storyTap)
    }

    // FUNCTION - Show Story
    func showStory() {
        // Show StoryVC
        let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
        storyVC.storyObject = self.postObject!
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
        self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true)
    }
    
    // FUNCTION - Add story tap
    func addStoryTap() {
        // Add tap method to viewStory
        let storyTap = UITapGestureRecognizer(target: self, action: #selector(showStory))
        storyTap.numberOfTapsRequired = 1
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(storyTap)
    }
    
    // FUNCTION - Update UI
    func updateView(withObject: PFObject) {
        // (1) Get User's Object
        if let user = withObject.value(forKey: "byUser") as? PFUser {
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - RPHelpers extension
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: CGFloat(0.5), borderColor: UIColor.lightGray)
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!), placeholderImage: UIImage(named: "GenderNeutralUser"))
            }
            // (2) Set rpUsername
            if let fullName = user.value(forKey: "realNameOfUser") as? String{
                self.rpUsername.text = fullName
            }
        }
        
        // (3) Set time
        let from = withObject.createdAt!
        let now = Date()
        let components : NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        // MARK: - RPExtensions
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set mediaPreview or textPreview
        self.textPreview.isHidden = true
        self.mediaPreview.isHidden = true
        
        if withObject.value(forKey: "contentType") as! String == "tp" {
            self.textPreview.text = "\(withObject.value(forKey: "textPost") as! String)"
            self.textPreview.isHidden = false
        } else if withObject.value(forKey: "contentType") as! String == "sp" {
            self.mediaPreview.image = UIImage(named: "CSpacePost")
            self.mediaPreview.isHidden = false
        } else {
            if let photo = withObject.value(forKey: "photoAsset") as? PFFile {
                // MARK: - SDWebImage
                self.mediaPreview.sd_setImage(with: URL(string: photo.url!)!)
            } else if let video = withObject.value(forKey: "videoAsset") as? PFFile {
                // MARK: - AVPlayer
                let player = AVPlayer(url: URL(string: video.url!)!)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.mediaPreview.bounds
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.mediaPreview.contentMode = .scaleAspectFit
                self.mediaPreview.layer.addSublayer(playerLayer)
                player.isMuted = true
                player.play()
            }
            self.mediaPreview.isHidden = false
        }
        // MARK: - RPHelpers
        self.textPreview.roundAllCorners(sender: self.textPreview)
        self.mediaPreview.roundAllCorners(sender: self.mediaPreview)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected == true {
            self.contentView.backgroundColor = UIColor.groupTableViewBackground
        } else {
            self.contentView.backgroundColor = UIColor.white
        }
    }
    
}
