//
//  Texture.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/// An texture for drawing different `Block`s.
enum Texture {
    case differentSides(top: String, sides: String)
    case image(String)
    case water
    case waterSource
    case laser
    case lava
    case lavaSource
}
