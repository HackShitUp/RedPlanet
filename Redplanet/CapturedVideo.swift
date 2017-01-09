//
//  CapturedVideo.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

// Video URL
var capturedURL = [URL]()

class CapturedVideo: UIViewController, PlayerDelegate {
    
    // Initializae Player
    var player: Player!
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.player = Player()
        self.player.delegate = self
        self.player.view.frame = self.view.bounds
        
        self.addChildViewController(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParentViewController: self)
        
        self.player.setUrl(capturedURL.last!)
        self.player.playFromBeginning()
        self.player.fillMode = "AVLayerVideoGravityResizeAspect"
        
        // Add tap method to pause and play again
        let pauseTap = UITapGestureRecognizer(target: self, action: #selector(self.player.playFromBeginning))
        pauseTap.numberOfTapsRequired = 1
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(pauseTap)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
