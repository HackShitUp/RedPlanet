//
//  RPChatObject.swift
//  Redplanet
//
//  Created by Joshua Choi on 3/9/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import Foundation
import Parse
import ParseUI
import Bolts

var creationExists: Bool = false

class RPChatObject: PFObject {
    var sender: PFUser?
    var senderUsername: String?
    var receiver: PFUser?
    var receiverUsername: String?
    var read: Bool?
    var Message: String?
    var photoAsset: PFFile?
    var videoAsset: PFFile?
}
