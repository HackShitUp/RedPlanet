//
//  VideoMoment.swift
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

class VideoMoment: UICollectionViewCell {

    @IBOutlet weak var rpUsername: UIButton!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var numberOfLikes: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var numberOfComments: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var numberOfShares: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    func addVideo(videoURL: URL?) {
        // MARK: - RPVideoPlayer
        let rpVideoPlayer = RPVideoPlayer(frame: self.contentView.bounds)
        rpVideoPlayer.setupInitialView(videoURL: videoURL!)
        self.contentView.addSubview(rpVideoPlayer)

        // Bring buttons to front
        let buttons = [self.rpUsername, self.time, self.moreButton,
                       self.numberOfLikes, self.likeButton,
                       self.numberOfComments, self.commentButton,
                       self.numberOfShares, self.shareButton] as [Any]
        for b in buttons {
            (b as AnyObject).layer.applyShadow(layer: (b as AnyObject).layer!)
            self.contentView.bringSubview(toFront: (b as AnyObject) as! UIView)
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

}
