//
//  Licenses.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class Licenses: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Track when user views license
        Heap.track("ViewedLicense", withProperties:
            ["byUserId": "\(PFUser.current()!.objectId!)",
                "Name": "\(PFUser.current()!.value(forKey: "realNameOfUser") as! String)"
            ])
        self.textView.isSelectable = false
    }

}
