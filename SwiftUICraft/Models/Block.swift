//
//  Block.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

/// A block chunk in the world.
struct Block: Codable, Hashable {
    var coordinate: Coordinate
    var blockKind: BlockKind
    
    /**
     Multiply the extrusion by this.
     
     Used for extending a block's height past a cube, for liquids and lasers.
     */
    var extrusionMultiplier = CGFloat(1)
    
    /// If the block is shown. For liquids, this will initially be `false`.
    var active = true
    
    /// How long you should hold a block to break it.
    let holdDurationForRemoval = CGFloat(0.1)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate)
        hasher.combine(blockKind)
    }
}

/// Enumerates all possible block types.
enum BlockKind: String, Codable, CaseIterable {
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
    case cactus
    
    case water
    case waterSource
    
    case crimsonStem
    case warpedStem
    case nylium
    case guildedBlackstone
    case glowstone
    case netherBricks
    case netherrack
    case gold
    case lava
    case lavaSource
    case laser
    
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
        case .cactus:
            return .differentSides(top: "cactus_top", sides: "cactus_side")
        case .water:
            return .water
        case .waterSource:
            return .waterSource
        case .crimsonStem:
            return .differentSides(top: "crimson_stem_top", sides: "crimson_stem")
        case .warpedStem:
            return .differentSides(top: "warped_stem_top", sides: "warped_stem")
        case .nylium:
            return .differentSides(top: "warped_nylium", sides: "warped_nylium_side")
        case .guildedBlackstone:
            return .image("gilded_blackstone")
        case .glowstone:
            return .image("glowstone")
        case .netherBricks:
            return .image("nether_bricks")
        case .netherrack:
            return .image("netherrack")
        case .gold:
            return .image("gold_block")
        case .lava:
            return .lava
        case .lavaSource:
            return .lavaSource
        case .laser:
            return .laser
        }
    }
    
    var isLiquid: Bool {
        self == .water || self == .waterSource || self == .lava || self == .lavaSource
    }
}
