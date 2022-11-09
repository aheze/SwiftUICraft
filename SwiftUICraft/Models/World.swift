//
//  World.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/// Each world has a set size and stores which blocks are placed.
struct World {
    var width: Int
    var height: Int
    var blocks: [Block]
}
