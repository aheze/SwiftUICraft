//
//  Control.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Foundation

/// Represents possible buttons in the D-Pad.
enum Control {
    case direction(Direction)
    case center
    case pause
    case zoomIn
    case zoomOut
    case reset

    enum Direction {
        case up
        case right
        case down
        case left

        var rotation: CGFloat {
            switch self {
            case .up:
                return 0
            case .right:
                return 90
            case .down:
                return 180
            case .left:
                return 270
            }
        }
    }

    var image: String {
        switch self {
        case .direction:
            return "button_arrow"
        case .center:
            return "button_center"
        case .pause:
            return "button_pause"
        case .zoomIn:
            return "button_in"
        case .zoomOut:
            return "button_out"
        case .reset:
            return "button_reset"
        }
    }
}
