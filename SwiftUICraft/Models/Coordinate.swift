//
//  Coordinate.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/// A 3D point in space.
struct Coordinate: Hashable, Comparable {
    var row: Int
    var column: Int
    var levitation: Int

    /// Allow ordering by coordinate to maintain Prism's 3D effect.
    static func < (lhs: Coordinate, rhs: Coordinate) -> Bool {
        /// From https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
        let predicates: [(Coordinate, Coordinate) -> Bool] = [ // <2>
            { $0.row < $1.row },
            { $0.column < $1.column },
            { $0.levitation < $1.levitation }
        ]

        for predicate in predicates { // <3>
            if !predicate(lhs, rhs), !predicate(rhs, lhs) { // <4>
                continue // <5>
            }

            return predicate(lhs, rhs) // <5>
        }

        return false
    }
}
