//
//  SNFilter.swift
//  Pods
//
//  Created by Paul Jeannot on 04/05/2016.
//
//

import UIKit
import CoreImage

open class SNFilter: UIImageView {
    
    /*
     Array to hold CoreImageFilters --> This public variable is accessible in 
     CapturedStill.swift and is append-able.
     */
    open static var filterIdentities = ["CINoiseReduction",
                                        "CIPhotoEffectChrome",
                                        "CIPhotoEffectNoir",
                                        "CICMYKHalftone",
                                        "CICrystallize",
                                        "CIGloom",
                                        "CIEdgeWork",
                                        "CIPhotoEffectFade",
                                        "nil",
                                        "nil"]
    
    open var name:String?
    var stickers = [SNSticker]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(frame: CGRect, withImage image:UIImage, withContentMode mode:UIViewContentMode = .scaleToFill) {
        super.init(frame: frame)
        self.contentMode = mode
        self.clipsToBounds = true
        self.image = image
        let maskLayer = CAShapeLayer()
        self.layer.mask = maskLayer
        maskLayer.frame = CGRect(origin: CGPoint.zero, size: self.image!.size)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func mask(_ maskRect: CGRect) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        path.addRect(maskRect)
        maskLayer.path = path
        self.layer.mask = maskLayer;
    }
    
    func updateMask(_ maskRect: CGRect, newXPosition: CGFloat) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        var rect = maskRect
        rect.origin.x = newXPosition
        path.addRect(rect)
        maskLayer.path = path
        self.layer.mask = maskLayer;
    }
    
    func applyFilter(filterNamed name:String) -> SNFilter {
        
        let filter: SNFilter = self.copy() as! SNFilter
        filter.name = name
        
        if (SNFilter.filterIdentities.contains(name) == false) {
            print("Filter not existing")
            return filter
        } else if name == "nil" {
            // Figure out how to replicate the code 
            // in the next statement
            return filter
        } else {
            // Create and apply filter
            // (1) Create Source Image
            let sourceImage = CIImage(image: filter.image!)
            // (2) Create Filter Image
            let rpFilter = CIFilter(name: name)
            rpFilter?.setDefaults()
            // (3) Set Source Image
            rpFilter?.setValue(sourceImage, forKey: kCIInputImageKey)
            // (4) Create Core Image Context
            let context = CIContext(options: nil)
            // (5) Output filtered image as cgImage with dimension
            let outputCGImage = context.createCGImage(rpFilter!.outputImage!, from: rpFilter!.outputImage!.extent)
            // (6) Convert filtered cgImage to UIImage and set orientation
            var filteredImage: UIImage?
            if isRearCam! == true {
                filteredImage = UIImage(cgImage: outputCGImage!, scale: 0.5, orientation: .right)
            } else if isRearCam! == false {
                filteredImage = UIImage(cgImage: outputCGImage!, scale: 0.5, orientation: .leftMirrored)
            }
            // (7) Add filtered image to array
            filter.image = filteredImage
            return filter
        }
    }
    
    open func addSticker(_ sticker: SNSticker) {
        self.stickers.append(sticker)
    }
    
    open static func generateFilters(_ originalImage: SNFilter, filters:[String]) -> [SNFilter] {
        
        var finalFilters = [SNFilter]()
        let syncQueue = DispatchQueue(label: "com.redplanetapp.redplanet", attributes: .concurrent)
        
        // Each filter can be generated on a different thread
        DispatchQueue.concurrentPerform(iterations: filters.count) { iteration in
            let filterComputed = originalImage.applyFilter(filterNamed: filters[iteration])
            syncQueue.sync {
                finalFilters.append(filterComputed)
                return
            }
        }
        
        return finalFilters
    }
}

// MARK: - NSCopying protocol

extension SNFilter: NSCopying {
    public func copy(with zone: NSZone?) -> Any {
        let copy = SNFilter(frame: self.frame)
        copy.backgroundColor = self.backgroundColor
        copy.image = self.image
        copy.name = name
        copy.contentMode = self.contentMode
        
        for s in stickers {
            copy.stickers.append(s.copy() as! SNSticker)
        }
        return copy
    }
}
