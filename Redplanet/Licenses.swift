//
//  Licenses.swift
//  Redplanet
//
//  Created by Joshua Choi on 2/20/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class Licenses: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBAction func back(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.isSelectable = false
    }

}
