//
//  RPExtensions.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/2/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

import NotificationBannerSwift
import OneSignal
import Parse
import ParseUI
import Bolts


/*
 MARK: - Used to add UIButton to bottom center of UIView
 Hide rpButton in viewWillAppear and
 show rpButton in viewWillDisappear
 */
let rpButton = UIButton(frame: CGRect(x: 0, y: 0, width: 75, height: 75))

/*
 MARK: - UIView: Extensions
 */
extension UIView {
    
    // Function to add rpButton
    func setButton(container: UIView?) {
        // Add button to bottom/center of UITabBar
        var buttonFrame = rpButton.frame
        buttonFrame.origin.y = container!.bounds.height - buttonFrame.height
        buttonFrame.origin.x = container!.bounds.width/2 - buttonFrame.size.width/2
        rpButton.frame = buttonFrame
        rpButton.setImage(UIImage(named: "Cam"), for: .normal)
        rpButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        //        rpButton.layer.applyShadow(layer: rpButton.layer)
        container!.addSubview(rpButton)
    }
    
    // Function to round ALL corners of UIView
    func roundAllCorners(sender: UIView?) {
        sender!.layer.cornerRadius = 8.00
        sender!.clipsToBounds = true
    }
    
    // Function to round TOP corners of UIView
    func roundTopCorners(sender: UIView?) {
        let shape = CAShapeLayer()
        shape.bounds = sender!.frame
        shape.position = sender!.center
        shape.path = UIBezierPath(roundedRect: sender!.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8)).cgPath
        sender!.layer.mask = shape
        sender!.clipsToBounds = true
    }
    
    // Function to make the view circular
    func makeCircular(forView: UIView?, borderWidth: CGFloat?, borderColor: UIColor?) {
        forView!.layoutIfNeeded()
        forView!.layoutSubviews()
        forView!.setNeedsLayout()
        forView!.layer.cornerRadius = forView!.frame.size.width/2
        forView!.layer.borderColor = borderColor!.cgColor
        forView!.layer.borderWidth = borderWidth!
        forView!.clipsToBounds = true
    }
}

// MARK: - UINavigationBar design configuration
/*
 'Whitens-out' the UINavigationbar and removes the lower grey line border
 • Shows the UINavigationBar; Set UIImage() instance as background
 • Apply UIImage to UINavigationBar; Makes it NOT translucent
 */
extension UINavigationBar {
    func whitenBar(navigator: UINavigationController?) {
        navigator?.setNavigationBarHidden(false, animated: false)
        navigator?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigator?.navigationBar.shadowImage = UIImage()
        navigator?.navigationBar.isTranslucent = false
    }
}

/*
 MARK: - CALayer; Extension used to apply generic shadow to Interface Objects
 */
extension CALayer {
    func applyShadow(layer: CALayer?) {
        layer!.shadowColor = UIColor.black.cgColor
        layer!.shadowOffset = CGSize(width: 1, height: 1)
        layer!.shadowRadius = 3
        layer!.shadowOpacity = 0.5
    }
}

/*
 MARK: - Function to generate random colors
 */
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1)
    }
}

/*
 MARK: - Extensions add a shuffle() method to any mutable collection and a shuffled() method to any sequence
 */
extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of given collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}
extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

/*
 MARK: - DateComponents Time Display
 • getFullTime() = calculate time with full text
 • getShortTime() = calculate time with shortened text
 */
extension DateComponents {
    
    // Get Full Time
    func getFullTime(difference: DateComponents?, date: Date?) -> String {
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference!.second! <= 0 {
            return "now"
        } else if difference!.second! > 0 && difference!.minute! == 0 {
            if difference!.second! == 1 {
                return "1 second ago"
            }
            return "\(difference!.second!) seconds ago"
            
        } else if difference!.minute! > 0 && difference!.hour! == 0 {
            if difference!.minute! == 1 {
                return "1 minute ago"
            }
            return "\(difference!.minute!) minutes ago"
            
        } else if difference!.hour! > 0 && difference!.day! == 0 {
            if difference!.hour! == 1 {
                return "1 hour ago"
            }
            return "\(difference!.hour!) hours ago"
        } else if difference!.day! > 0 && difference!.weekOfMonth! == 0 {
            if difference!.day! == 1 {
                return "1 day ago"
            }
            
            return "\(difference!.day!) days ago"
        }
        
        let createdDate = DateFormatter()
        createdDate.dateFormat = "MMM dd"
        return createdDate.string(from: date!)
    }
    
    // Get Time w/Shortened Text
    func getShortTime(difference: DateComponents?, date: Date?) -> String {
        // logic what to show : Seconds, minutes, hours, days, or weeks
        if difference!.second! <= 0 {
            return "now"
        } else if difference!.second! > 0 && difference!.minute! == 0 {
            return "\(difference!.second!)s"
        } else if difference!.minute! > 0 && difference!.hour! == 0 {
            return "\(difference!.minute!)m"
        } else if difference!.hour! > 0 && difference!.day! == 0 {
            return "\(difference!.hour!)h"
        } else if difference!.day! > 0 && difference!.weekOfMonth! == 0 {
            return "\(difference!.day!)d"
        }
        
        let createdDate = DateFormatter()
        createdDate.dateFormat = "MMM dd"
        return createdDate.string(from: date!)
    }
}


class RPExtensions: NSObject {

}
