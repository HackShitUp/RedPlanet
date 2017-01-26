//
//  Controlla.swift
//  Redplanet
//
//  Created by Joshua Choi on 1/26/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import SwipeNavigationController

class Controlla: UIViewController {
    
    var swipeNavigationController: SwipeNavigationController?

    override func viewDidLoad() {
        super.viewDidLoad()

        swipeNavigationController = SwipeNavigationController(centerViewController: RPCamera())
        swipeNavigationController?.topViewController = nil
        swipeNavigationController?.bottomViewController = MasterTab()
        swipeNavigationController?.leftViewController = Library()
        swipeNavigationController?.rightViewController = NewTextPost()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
