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

class RPChatMediaCell: UITableViewCell {
    
    
    // Initialize Parent View Controller
    var delegate: UIViewController?
    
    // Initialize object
    var mediaObject: PFObject?
    
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpMediaAsset: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var container: UIView!
    
    
    // Photo or Sticker --> "ph" or "sti" --> Function to zoom into Photo/Sticker
    func zoom() {
        // Mark: - Agrume
        let agrume = Agrume(image: self.rpMediaAsset.image!, backgroundBlurStyle: .dark, backgroundColor: .black)
        agrume.showFrom(self.delegate!.self)
    }
    
    
    // Video --> "vi" --> Function to play video
    func playVideo() {
        if let video = mediaObject!.value(forKey: "videoAsset") as? PFFile {
            // Traverse video url
            let videoUrl = URL(string: video.url!)
            // MARK: - RPPopUpVC
            let rpPopUpVC = RPPopUpVC()
            let viewController = UIViewController()
            // MARK: - RPVideoPlayerView
            let rpVideoPlayer = RPVideoPlayerView(frame: viewController.view.bounds)
            rpVideoPlayer.setupVideo(videoURL: videoUrl!)
            rpVideoPlayer.playbackLoops = true
            viewController.view.addSubview(rpVideoPlayer)
            rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: viewController)
            self.delegate?.present(UINavigationController(rootViewController: rpPopUpVC), animated: true, completion: nil)
        }
    }
    
    // Moment --> "itm" --> SingleStory
    func showStory() {
        // MARK: - RPPopUpVC
        let rpPopUpVC = RPPopUpVC()
        let storyVC = self.delegate?.storyboard?.instantiateViewController(withIdentifier: "storyVC") as! Story
        storyVC.singleStory = self.mediaObject!
        storyVC.chatOrStory = "Chat"
        rpPopUpVC.setupView(vc: rpPopUpVC, popOverVC: storyVC)
        self.delegate?.present(rpPopUpVC, animated: true, completion: nil)
    }
    
    
    // Function to add tap method
    func addTapMethod() {
        
        // Configure tap method based on mediaType
        switch mediaObject?.value(forKey: "contentType") as! String {
            case "itm":
                let mediaTap = UITapGestureRecognizer(target: self, action: #selector(showStory))
                mediaTap.numberOfTapsRequired = 1
                self.rpMediaAsset.isUserInteractionEnabled = true
                self.rpMediaAsset.addGestureRecognizer(mediaTap)
            case "ph", "sti":
                // Add tap gesture to zoom in
                let zoomTap = UITapGestureRecognizer(target: self, action: #selector(zoom))
                zoomTap.numberOfTapsRequired = 1
                self.rpMediaAsset.isUserInteractionEnabled = true
                self.rpMediaAsset.addGestureRecognizer(zoomTap)
            case "vi":
                // Add tap gesture to play video
                let playTap = UITapGestureRecognizer(target: self, action: #selector(playVideo))
                playTap.numberOfTapsRequired = 1
                self.rpMediaAsset.isUserInteractionEnabled = true
                self.rpMediaAsset.addGestureRecognizer(playTap)
        default:
            break;
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
