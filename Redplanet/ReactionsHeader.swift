//
//  ReactionsHeader.swift
//  Redplanet
//
//  Created by Joshua Choi on 5/8/17.
//  Copyright © 2017 Redplanet Media, LLC. All rights reserved.
//

import UIKit

/*
 UITableViewheaderFooterView class. Superclass is "Reactions.swift"
 Used to show the number of likes or comments within the parent class' UITableView.
 Used to enable users to like or unlike a post.
 */

class ReactionsHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var reactionType: UILabel!
    @IBOutlet weak var likeButton: UIButton!
}
