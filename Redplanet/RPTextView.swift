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

    func configurate() {
        // Those properties need to set after attributedText
        text = ""
        font = UIFont(name: "AvenirNext-Bold", size: 70)
        textAlignment = .center
        spellCheckingType = .no
        backgroundColor = UIColor.clear
        textColor = UIColor.white
        
        // Set tint color
        self.tintColor = UIColor.groupTableViewBackground
        
        // Set UIEdgeInsets
        self.contentInset = UIEdgeInsets(top: 88, left: 16, bottom: 0, right: 16)
        
        // MARK: - RPExtensions
        self.layer.applyShadow(layer: self.layer)
        
        // Hide scrolls
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = true
    }
}
