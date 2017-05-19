//
//  PhotoCell.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/16/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Bolts
import KILabel
import SDWebImage

class PhotoCell: UITableViewCell {
    
    // PFObject; used to determine post type
    var postObject: PFObject?
    // Parent UIViewController
    var superDelegate: UIViewController?
    
    @IBOutlet weak var rpUserProPic: PFImageView!
    @IBOutlet weak var rpUsername: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var resizingView: UIView!
    @IBOutlet weak var photo: PFImageView!
    @IBOutlet weak var textPost: KILabel!
    
    // Function to bind data
    func updateView(postObject: PFObject?) {
        // (1) Get user's object
        if let user = postObject!.value(forKey: "byUser") as? PFUser {
            // Get realNameOfUser
            self.rpUsername.text = (user.value(forKey: "realNameOfUser") as! String)
            // Set profile photo
            if let proPic = user.value(forKey: "userProfilePicture") as? PFFile {
                // MARK: - SDWebImage
                self.rpUserProPic.sd_setImage(with: URL(string: proPic.url!)!, placeholderImage: UIImage(named: "GenderNeutralUser"))
                // MARK: - RPExtensions
                self.rpUserProPic.makeCircular(forView: self.rpUserProPic, borderWidth: 0.5, borderColor: UIColor.lightGray)
            }
        }
        
        // (2) Set text post
        if let text = postObject!.value(forKey: "textPost") as? String {
            self.textPost.text = text
        }
        
        // (3) Set time
        let from = postObject!.createdAt!
        let now = Date()
        let components: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfMonth]
        let difference = (Calendar.current as NSCalendar).components(components, from: from, to: now, options: [])
        self.time.text = difference.getFullTime(difference: difference, date: from)
        
        // (4) Set photo
        if let image = postObject!.value(forKey: "photoAsset") as? PFFile {
            self.photo.translatesAutoresizingMaskIntoConstraints = true
            self.photo.autoresizingMask = .flexibleBottomMargin
            self.photo.autoresizingMask = .flexibleHeight
            self.photo.autoresizingMask = .flexibleRightMargin
            self.photo.autoresizingMask = .flexibleLeftMargin
            self.photo.autoresizingMask = .flexibleTopMargin
            self.photo.autoresizingMask = .flexibleWidth
            self.photo.contentMode = .scaleAspectFit
            /*
             float scaleFactor = MAX(image.size.width/imageView.bounds.size.width, image.size.height/imageView.bounds.size.height);
             Then do
             
             CGRect ivFrame = imageView.frame;
             ivframe.size.height = image.size.height/scalefactor;
             ivFrame.size.width = image.size.width/scalefactor;
             imageView.frame = ivFrame;
 */
            // MARK: - SDWebImage
            self.photo.sd_setIndicatorStyle(.gray)
            self.photo.sd_showActivityIndicatorView()
            self.photo.sd_setImage(with: URL(string: image.url!)!)
        }
        
    }

    
    func imageWithImage (sourceImage: UIImage, scaledToWidth: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = scaledToWidth / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
