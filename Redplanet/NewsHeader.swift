//
//  NewsHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/13/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

import KILabel

class NewsHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var mediaLogo: PFImageView!
    @IBOutlet weak var mediaName: UILabel!
}
