//
//  LaunchUI.swift
//  Redplanet
//
//  Created by Joshua Choi on 4/1/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

class LaunchUI: UIViewController, UITabBarControllerDelegate {


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.navigationController?.tabBarController?.delegate = self
//        self.tabBarController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.tabBarController?.delegate = self
//        self.navigationController?.tabBarController?.delegate = self
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
