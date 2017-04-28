//
//  RPVideoPlayerView.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/27/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

open class RPVideoPlayerView: UIView {

    // MARK: - Variables
    fileprivate var videoURL: URL!
    fileprivate var asset: AVURLAsset!
    fileprivate var playerItem: AVPlayerItem!
    fileprivate var player: AVPlayer!
    fileprivate var playerLayer: AVPlayerLayer!
    fileprivate var assetGenerator: AVAssetImageGenerator!
    
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer!
    fileprivate var previousLocationX: CGFloat = 0.0
    fileprivate let rewindDimView = UIVisualEffectView()
    fileprivate let rewindContentView = UIView()
    open let rewindTimelineView = TimelineView()
    fileprivate let rewindPreviewShadowLayer = CALayer()
    fileprivate let rewindPreviewImageView = UIImageView()
    fileprivate let rewindCurrentTimeLabel = UILabel()
    
    /// Indicates the maximum height of rewindPreviewImageView. Default value is 112.
    open var rewindPreviewMaxHeight: CGFloat = 112.0 {
        didSet {
            assetGenerator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: rewindPreviewMaxHeight * UIScreen.main.scale)
        }
    }
    
    /// Indicates whether player should start playing on viewDidLoad. Default is true.
    open var autoplays: Bool = true
    
    // MARK: - Constructors
    
    /**
     Returns an initialized VideoViewController object
     
     - Parameter videoURL: Local URL to the video asset
     **/
    
    // MARK: - Object Life Cycle
    // (1) Initialize RPVideoPlayerView
    override public init (frame : CGRect) {
        super.init(frame : frame)
    }
    // (2) Handle nil
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    // (3) Deinitialize/release object when no longer needed
    deinit {
        print("De-Initialized")
        player = nil
    }
    
    // Initialization function to SETUP video
    public func setupVideo(videoURL: URL) {
        // Do what you want.
        self.videoURL = videoURL
        
        asset = AVURLAsset(url: videoURL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        
        assetGenerator = AVAssetImageGenerator(asset: asset)
        assetGenerator.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: rewindPreviewMaxHeight * UIScreen.main.scale)
        
        // Awake set up and layout all views
        didMoveToSuperview()
        awakeFromNib()
        layoutSubviews()
    }
    
    // Function to loop video
    func loopVideo(_ notification: Notification) {
        self.player?.seek(to: kCMTimeZero)
        self.player?.play()
    }

    // MARK: - Methods
    // Playback automatically loops continuously when true.
    open var playbackLoops: Bool {
        get {
            return (self.player.actionAtItemEnd == .none) as Bool
        }
        set {
            if newValue == true {
                self.player.actionAtItemEnd = .none
            } else {
                self.player.actionAtItemEnd = .pause
            }
        }
    }
    
    /// Mutes audio playback when true.
    open var muted: Bool {
        get {
            return self.player.isMuted
        }
        set {
            self.player.isMuted = newValue
        }
    }
    
    // Resumes playback
    open func play() {
        player.play()
    }
    
    // Pauses playback
    open func pause() {
        player.pause()
    }
    
    // MARK: - UIGestureRecognizer
    open func longPressed(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: gesture.view!)
        rewindTimelineView.zoom = (location.y - rewindTimelineView.center.y - 10.0) / 30.0
        
        if gesture.state == .began {
            player.pause()
            rewindTimelineView.initialTime = CMTimeGetSeconds(playerItem.currentTime())
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut], animations: {
                self.rewindDimView.effect = UIBlurEffect(style: .dark)
                self.rewindContentView.alpha = 1.0
            }, completion: nil)
        } else if gesture.state == .changed {
            rewindTimelineView.rewindByDistance(previousLocationX - location.x)
        } else {
            player.play()
            
            let newTime = CMTime(seconds: rewindTimelineView.currentTime, preferredTimescale: playerItem.currentTime().timescale)
            playerItem.seek(to: newTime)
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut], animations: {
                self.rewindDimView.effect = nil
                self.rewindContentView.alpha = 0.0
            }, completion: nil)
        }
        
        if previousLocationX != location.x {
            previousLocationX = location.x
        }
    }
    
    // MARK: - UIView Lifecycle
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.backgroundColor = .black
        self.layer.addSublayer(self.playerLayer)
        
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        self.addGestureRecognizer(longPressGestureRecognizer)
        
        self.addSubview(rewindDimView)
        
        rewindContentView.alpha = 0.0
        self.addSubview(rewindContentView)
        
        rewindTimelineView.duration = CMTimeGetSeconds(asset.duration)
        rewindTimelineView.currentTimeDidChange = { [weak self] (currentTime) in
            guard let strongSelf = self, let playerItem = strongSelf.playerItem, let assetGenerator = strongSelf.assetGenerator else { return }
            
            let minutesInt = Int(currentTime / 60.0)
            let secondsInt = Int(currentTime) - minutesInt * 60
            strongSelf.rewindCurrentTimeLabel.text = (minutesInt > 9 ? "" : "0") + "\(minutesInt)" + ":" + (secondsInt > 9 ? "" : "0") + "\(secondsInt)"
            
            let requestedTime = CMTime(seconds: currentTime, preferredTimescale: playerItem.currentTime().timescale)
            
            assetGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: requestedTime)]) { [weak self] (_, CGImage, _, _, _) in
                guard let strongSelf = self, let CGImage = CGImage else { return }
                let image = UIImage(cgImage: CGImage, scale: UIScreen.main.scale, orientation: .up)
                
                DispatchQueue.main.async {
                    strongSelf.rewindPreviewImageView.image = image
                    
                    if strongSelf.rewindPreviewImageView.bounds.size != image.size {
                        strongSelf.layoutSubviews()
                    }
                }
            }
        }
        rewindContentView.addSubview(rewindTimelineView)
        
        rewindCurrentTimeLabel.text = " "
        rewindCurrentTimeLabel.font = .systemFont(ofSize: 16.0)
        rewindCurrentTimeLabel.textColor = .white
        rewindCurrentTimeLabel.textAlignment = .center
        rewindCurrentTimeLabel.sizeToFit()
        rewindContentView.addSubview(rewindCurrentTimeLabel)
        
        rewindPreviewShadowLayer.shadowOpacity = 1.0
        rewindPreviewShadowLayer.shadowColor = UIColor(white: 0.1, alpha: 1.0).cgColor
        rewindPreviewShadowLayer.shadowRadius = 15.0
        rewindPreviewShadowLayer.shadowOffset = .zero
        rewindPreviewShadowLayer.masksToBounds = false
        rewindPreviewShadowLayer.actions = ["position": NSNull(), "bounds": NSNull(), "shadowPath": NSNull()]
        rewindContentView.layer.addSublayer(rewindPreviewShadowLayer)
        
        rewindPreviewImageView.contentMode = .scaleAspectFit
        rewindPreviewImageView.layer.mask = CAShapeLayer()
        rewindContentView.addSubview(rewindPreviewImageView)
        
        
        // update new playerItem settings
        if playbackLoops == true {
            self.player.actionAtItemEnd = .none
        } else {
            self.player.actionAtItemEnd = .pause
        }

    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure looping for AVPlayer
        self.player.actionAtItemEnd = .none
        
        // Add observer to handle looping of video
        NotificationCenter.default.addObserver(self, selector: #selector(loopVideo),
                                               name: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)
        
        // Play video if autoplays
        if autoplays {
            play()
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        playerLayer.frame = self.bounds
        rewindDimView.frame = self.bounds

        rewindContentView.frame = self.bounds
        
        let timelineHeight: CGFloat = 10.0
        let verticalSpacing: CGFloat = 25.0
        
        let rewindPreviewImageViewWidth = rewindPreviewImageView.image?.size.width ?? 0.0
        rewindPreviewImageView.frame = CGRect(x: (rewindContentView.bounds.width - rewindPreviewImageViewWidth) / 2.0, y: (rewindContentView.bounds.height - rewindPreviewMaxHeight - verticalSpacing - rewindCurrentTimeLabel.bounds.height - verticalSpacing - timelineHeight) / 2.0, width: rewindPreviewImageViewWidth, height: rewindPreviewMaxHeight)
        rewindCurrentTimeLabel.frame = CGRect(x: 0.0, y: rewindPreviewImageView.frame.maxY + verticalSpacing, width: rewindTimelineView.bounds.width, height: rewindCurrentTimeLabel.frame.height)
        rewindTimelineView.frame = CGRect(x: 0.0, y: rewindCurrentTimeLabel.frame.maxY + verticalSpacing, width: rewindContentView.bounds.width, height: timelineHeight)
        rewindPreviewShadowLayer.frame = rewindPreviewImageView.frame
        
        let path = UIBezierPath(roundedRect: rewindPreviewImageView.bounds, cornerRadius: 5.0).cgPath
        rewindPreviewShadowLayer.shadowPath = path
        (rewindPreviewImageView.layer.mask as! CAShapeLayer).path = path
    }
    
    
    
}