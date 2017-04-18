//
//  RPTextView.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/17/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Foundation

class RPTextView: UITextView {
    
    private let frameRatio: CGFloat = UIScreen.main.bounds.width/375
    
    // Make text always aligns in vertical
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
    
    func configurate() {
        // Add Shadow
        self.layer.applyShadow(layer: self.layer)
        // Configure
        text = ""
        font = UIFont(name: "AvenirNext-Bold", size: 60)
        textAlignment = .center
        spellCheckingType = .no
        tintColor = UIColor(red:1.00, green:0.00, blue:0.31, alpha:1.0)
        backgroundColor = UIColor.clear
        textColor = UIColor.white
        
        // Add padding
        let padding = 3.0 * frameRatio
        textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layoutManager.allowsNonContiguousLayout = false
    }
}
