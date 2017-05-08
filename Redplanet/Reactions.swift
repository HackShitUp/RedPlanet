//
//  Reactions.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts


var reactionObject = [PFObject]()

class Reactions: UIViewController {
    
    // MARK: - TwicketSegmentedControl
    let segmentedControl = TwicketSegmentedControl()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    
    
    func fetchLikes() {
        let likes = PFQuery(className: "Likes")
        likes.whereKey("forObjectId", equalTo: reactionObject.last!.objectId!)
        
    }
    
    func fetchComments() {
        
    }
    
    func fetchShares() {
        
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - TwicketSegmentedControl
        let frame = CGRect(x: 5, y: view.frame.height / 2 - 20, width: view.frame.width - 10, height: 40)
        segmentedControl = TwicketSegmentedControl(frame: frame)
        segmentedControl.delegate = self
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.setSegmentItems(["Likes", "Comments", "Shares"])
        segmentedControl.defaultTextColor = UIColor.black
        segmentedControl.highlightTextColor = UIColor.white
        segmentedControl.segmentsBackgroundColor = UIColor.white
        segmentedControl.sliderBackgroundColor = UIColor(red: 1, green: 0.00, blue: 0.31, alpha: 1)
        segmentedControl.font = UIFont(name: "AvenirNext-Medium", size: 12)!
        self.navigationController?.navigationBar.topItem?.titleView = segmentedControl
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
