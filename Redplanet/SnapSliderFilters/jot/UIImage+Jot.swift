//  Converted with Swiftify v1.0.6221 - https://objectivec2swift.com/
//
//  UIImage+Jot.h
//  Jot
//
//  Created by Laura Skelton on 4/30/15.
//
//
import UIKit
import Foundation
/**
 *  Private category to create single-color background images for
 *  rendering jot's drawing and text sketchpad or whiteboard-style
 *  instead of image annotation-style.
 */
extension UIImage {
    /**
     *  Creates a single-color image with the given color and size.
     *
     *  @param color The color for the image
     *  @param size  The size the image should be
     *
     *  @return An image of the given color and size
     */
    class func jotImage(with color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale())
        color.setFill()
        UIGraphicsGetCurrentContext().fill(CGRect(x: CGFloat(0.0), y: CGFloat(0.0), width: CGFloat(size.width), height: CGFloat(size.height)))
        var colorImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return colorImage!
    }
}
//
//  UIImage+Jot.m
//  Jot
//
//  Created by Laura Skelton on 4/30/15.
//
//