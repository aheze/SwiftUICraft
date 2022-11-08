//
//  Models.swift
//  MC
//
//  Created by A. Zheng (github.com/aheze) on 11/7/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

enum Item: String, CaseIterable {
    case dirt
    case grass
    case log
    case stone
    case leaf
    
    case ice
    case concrete
    case blackstone
    case clay
    case sand
    case acaciaLog
    case acaciaPlanks
    case amethyst
    
    case pick
    case sword
    case bucket
    case beef
    
    enum Preview {
        case image(String)
        case blockView(BlockView)
    }
    
    var preview: Preview {
        switch self {
        case .pick:
            return .image("diamond_pickaxe")
        case .sword:
            return .image("diamond_sword")
        case .bucket:
            return .image("water_bucket")
        case .beef:
            return .image("cooked_beef")
        default:
            if let associatedBlockKind {
                return .blockView(
                    BlockView(
                        tilt: 1,
                        length: 20,
                        levitation: 0,
                        block: Block(
                            coordinate: .init( /// coordinate is ignored
                                row: 0,
                                column: 0,
                                levitation: 0
                            ),
                            blockKind: associatedBlockKind
                        )
                    )
                )
            }
        }
        
        fatalError("No preview for \(self).")
    }
    
    var associatedBlockKind: BlockKind? {
        switch self {
        case .dirt:
            return .dirt
        case .grass:
            return .grass
        case .log:
            return .log
        case .stone:
            return .stone
        case .leaf:
            return .leaf
        case .ice:
            return .ice
        case .concrete:
            return .concrete
        case .blackstone:
            return .blackstone
        case .clay:
            return .clay
        case .sand:
            return .sand
        case .acaciaLog:
            return .acaciaLog
        case .acaciaPlanks:
            return .acaciaPlanks
        case .amethyst:
            return .amethyst
        case .pick:
            return nil
        case .sword:
            return nil
        case .bucket:
            return .waterSource
        case .beef:
            return nil
        }
    }
}

/// represents a chunk in the world
/// use `Hashable` for preventing duplicate coordinates
struct Block: Identifiable, Hashable {
    var id: Coordinate {
        coordinate
    }

    var coordinate: Coordinate
    var blockKind: BlockKind
    var extrusionPercentage = CGFloat(1)
    var active = true
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate)
    }
}

enum BlockKind: String, CaseIterable {
    case dirt
    case grass
    case log
    case stone
    case leaf
    
    case ice
    case concrete
    case blackstone
    case clay
    case sand
    case acaciaLog
    case acaciaPlanks
    case amethyst
    
    case water
    case waterSource
    
    var texture: Texture {
        switch self {
        case .dirt:
            return .image("dirt")
        case .grass:
            return .differentSides(top: "grass_block_top", sides: "grass_block_side")
        case .log:
            return .differentSides(top: "oak_log_top", sides: "oak_log")
        case .stone:
            return .image("stone")
        case .leaf:
            return .image("oak_leaves")
        case .ice:
            return .image("blue_ice")
        case .concrete:
            return .image("cyan_concrete_powder")
        case .blackstone:
            return .differentSides(top: "blackstone_top", sides: "blackstone")
        case .clay:
            return .image("clay")
        case .sand:
            return .image("sand")
        case .acaciaLog:
            return .differentSides(top: "acacia_log_top", sides: "acacia_log")
        case .acaciaPlanks:
            return .image("acacia_planks")
        case .amethyst:
            return .image("amethyst_block")
        case .water:
            return .water
        case .waterSource:
            return .waterSource
        }
    }
    
    var isWater: Bool {
        self == .water || self == .waterSource
    }
}

enum Texture {
    case differentSides(top: String, sides: String)
    case image(String)
    case water
    case waterSource
}

struct World {
    var width: Int
    var height: Int
    var blocks: [Block]
}

struct Coordinate: Hashable, Comparable {
    var row: Int
    var column: Int
    var levitation: Int
    
    static func < (lhs: Coordinate, rhs: Coordinate) -> Bool {
        /// from https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
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

enum KeyboardKey {
    case direction(Direction)
    case center
    case reset
    case zoomIn
    case zoomOut
    
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
        case .reset:
            return "button_reset"
        case .zoomIn:
            return "button_in"
        case .zoomOut:
            return "button_out"
        }
    }
}
