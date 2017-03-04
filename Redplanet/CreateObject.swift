//
//  CreateObject.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/4/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import Parse
import ParseUI
import Bolts

class CreateObject {
    var byUser: PFUser?
    var username: String?
    var saved: Bool?
    var contentType: String?
    var textPost: String?
    var photoAsset: PFFile?
    var videoAsset: PFFile?
}
