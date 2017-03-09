//
//  RPObject.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/9/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import Foundation

import Parse
import ParseUI
import Bolts

class RPObject: PFObject {
    
    // Initialize object?
    // Use the below object to share posts????
//    var postObject: PFObject?
    
    var byUser: PFUser?
    var username: String?
    var toUser: PFUser?
    var toUsername: String?
    var contentType: String?
    var textPost: String?
    var photo: PFFile?
    var video: PFFile?
    var pointObject: PFObject?
}
