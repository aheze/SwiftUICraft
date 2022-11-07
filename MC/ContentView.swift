//
//  ContentView.swift
//  MC
//
//  Created by A. Zheng (github.com/aheze) on 11/6/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Prism
import SwiftUI

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

struct World {
    var width = 15
    var height = 6
    var slots = [Slot]()
    
    struct Coordinate: Hashable {
        var row: Int
        var column: Int
        var levitation: Int
    }
    
    struct Slot: Identifiable {
        var id: Coordinate {
            coordinate
        }

        var coordinate: Coordinate
        var item: Item
    }
    
    static let defaultWorld: Self = {
        let width = 15
        let height = 6
        var slots = [Slot]()
        
        /// base dirt layer
        for row in 0..<height {
            for column in 0..<width {
                let shouldBeDirt = (column - (height - row)) < 3
                
                let coordinate = Coordinate(row: row, column: column, levitation: 0)
                let slot = Slot(coordinate: coordinate, item: shouldBeDirt ? .dirt : .grass)
                slots.append(slot)
            }
        }
        
        /// jagged shape
        for row in 0..<height {
            for column in 0..<10 {
                let shouldAdd = (column - (height - row)) < 3
                
                if shouldAdd {
                    let coordinate = Coordinate(row: row, column: column, levitation: 1)
                    let slot = Slot(coordinate: coordinate, item: .dirt)
                    slots.append(slot)
                }
            }
        }
     
        /// jagged shape
        for row in 0..<height {
            for column in 0..<10 {
                let shouldAdd = (column - (height - row)) < 0
                
                if shouldAdd {
                    let coordinate = Coordinate(row: row, column: column, levitation: 2)
                    let slot = Slot(coordinate: coordinate, item: .grass)
                    slots.append(slot)
                }
            }
        }
        
        /// fill in some more grass blocks at the bottom
        for (x, y) in [(2, 4), (1, 5), (2, 5), (3, 5)] {
            let coordinate = Coordinate(row: y, column: x, levitation: 2)
            let slot = Slot(coordinate: coordinate, item: .grass)
            slots.append(slot)
        }
        
        /// tree
        let trunk = (11, 2)
        for levitation in 1..<8 {
            switch levitation {
            case 5:
                /// first layer leaves
                for (x, y) in [(-1, -1), (0, -1), (1, -1)] {
                    let coordinate = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let slot = Slot(coordinate: coordinate, item: .leaf)
                    slots.append(slot)
                }
                
                let coordinateLeft = Coordinate(row: trunk.1, column: trunk.0 - 1, levitation: levitation)
                let slotLeft = Slot(coordinate: coordinateLeft, item: .leaf)
                slots.append(slotLeft)
                
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let slot = Slot(coordinate: coordinate, item: .log)
                slots.append(slot)
                
                let coordinateRight = Coordinate(row: trunk.1, column: trunk.0 + 1, levitation: levitation)
                let slotRight = Slot(coordinate: coordinateRight, item: .leaf)
                slots.append(slotRight)
                
                /// bottom leaves
                for (x, y) in [(-1, 1), (0, 1), (1, 1)] {
                    let coordinate = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let slot = Slot(coordinate: coordinate, item: .leaf)
                    slots.append(slot)
                }
            case 6:
                /// second layer of leaves, in cross shape
                for (x, y) in [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)] {
                    let coordinateRight = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let slot = Slot(coordinate: coordinateRight, item: .leaf)
                    slots.append(slot)
                }
            case 7:
                /// top leaf block
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let slot = Slot(coordinate: coordinate, item: .leaf)
                slots.append(slot)
            default:
                /// just a log
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let slot = Slot(coordinate: coordinate, item: .log)
                slots.append(slot)
            }
        }
        
        let world = World(slots: slots)
        
        return world
    }()
}

enum Item: String, CaseIterable {
    case dirt
    case grass
    case log
    case stone
    case leaf
    
    case pick
    case sword
    case bucket
    case beef
    
    var texture: Texture {
        switch self {
        case .dirt:
            return .init(itemPreview: nil, blockTop: "dirt", blockSide: "dirt")
        case .grass:
            return .init(itemPreview: nil, blockTop: "grass_block_top", blockSide: "grass_block_side")
        case .log:
            return .init(itemPreview: nil, blockTop: "oak_log_top", blockSide: "oak_log")
        case .stone:
            return .init(itemPreview: nil, blockTop: "stone", blockSide: "stone")
        case .leaf:
            return .init(itemPreview: nil, blockTop: "oak_leaves", blockSide: "oak_leaves")
        case .pick:
            return .init(itemPreview: "diamond_pickaxe", blockTop: nil, blockSide: nil)
        case .sword:
            return .init(itemPreview: "diamond_sword", blockTop: nil, blockSide: nil)
        case .bucket:
            return .init(itemPreview: "water_bucket", blockTop: nil, blockSide: nil)
        case .beef:
            return .init(itemPreview: "cooked_beef", blockTop: nil, blockSide: nil)
        }
    }
    
    var previewBlock: Block? {
        switch self {
        case .dirt, .grass, .log, .stone, .leaf:
            return Block(tilt: 1, length: 20, levitation: 0, item: self)
        default:
            return nil
        }
    }
}

struct Texture {
    var itemPreview: String?
    var blockTop: String?
    var blockSide: String?
}

struct ContentView: View {
    @State var world = World.defaultWorld
    @State var selectedItem = Item.dirt
    @State var tilt = CGFloat(0.3)
    let blockLength = CGFloat(50)
    
    var body: some View {
        Color.clear.overlay {
            controls
        }
        .background {
            LinearGradient(colors: [.blue, .white, .white, .brown], startPoint: .top, endPoint: .bottom)
                .opacity(0.2)
                .background(Color.white)
                .ignoresSafeArea()
                .overlay {
                    game
                        .offset(y: 120)
                }
        }
    }
    
    func addBlock(at coordinate: World.Coordinate) {
        /// only allow blocks to be placed, not other items
        guard selectedItem.previewBlock != nil else { return }
        
        let slot = World.Slot(coordinate: coordinate, item: selectedItem)
        world.slots.append(slot)
        
        print("addin: \(slot)")
    }
    
    var game: some View {
        PrismCanvas(tilt: tilt) {
            let size = CGSize(
                width: CGFloat(world.width) * blockLength,
                height: CGFloat(world.height) * blockLength
            )
            
            PrismColorView(tilt: tilt, size: size, extrusion: 20, levitation: -20, color: Color.blue.opacity(0.5))
                .overlay {
                    ZStack(alignment: .topLeading) {
                        ForEach(world.slots) { slot in
                            Block(
                                tilt: tilt,
                                length: blockLength,
                                levitation: CGFloat(slot.coordinate.levitation) * blockLength,
                                item: slot.item
                            ) /** topPressed */ {
                                let coordinate = World.Coordinate(
                                    row: slot.coordinate.row,
                                    column: slot.coordinate.column,
                                    levitation: slot.coordinate.levitation + 1
                                )
                                addBlock(at: coordinate)
                            } leftPressed: {
                                let coordinate = World.Coordinate(
                                    row: slot.coordinate.row + 1,
                                    column: slot.coordinate.column,
                                    levitation: slot.coordinate.levitation
                                )
                                addBlock(at: coordinate)
                            } rightPressed: {
                                let coordinate = World.Coordinate(
                                    row: slot.coordinate.row,
                                    column: slot.coordinate.column + 1,
                                    levitation: slot.coordinate.levitation
                                )
                                addBlock(at: coordinate)
                            }
                            .offset(
                                x: CGFloat(slot.coordinate.column) * blockLength,
                                y: CGFloat(slot.coordinate.row) * blockLength
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
        }
        .scaleEffect(y: 0.69)
    }
    
    var controls: some View {
        VStack {
            Spacer()
            
            HStack {
                Grid {
                    GridRow {
                        slot
                        Switch(direction: .up)
                        slot
                    }
                    GridRow {
                        Switch(direction: .left)
                        slot
                        Switch(direction: .right)
                    }
                    GridRow {
                        slot
                        Switch(direction: .down)
                        slot
                    }
                }
                
                Spacer()
            }
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 0) {
                    ForEach(Item.allCases, id: \.rawValue) { item in
                        let selected = selectedItem == item
                        
                        Button {
                            selectedItem = item
                        } label: {
                            ItemView(item: item)
                        }
                        .overlay {
                            if selected {
                                Image("selected")
                                    .interpolation(.none)
                                    .resizable()
                                    .padding(-4)
                            }
                        }
                        .zIndex(selected ? 1 : 0)
                    }
                }
                .overlay {
                    Rectangle()
                        .strokeBorder(Color.black, lineWidth: 3)
                        .padding(-3)
                        .opacity(0.5)
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 20)
    }

    var slot: some View {
        Color.clear.gridCellUnsizedAxes([.vertical, .horizontal])
    }
}

struct Switch: View {
    var direction: Direction
    
    var body: some View {
        Button {} label: {
            Image("button_background")
                .interpolation(.none)
                .resizable()
                .frame(width: 70, height: 70)
                .overlay {
                    Image("button_arrow")
                        .interpolation(.none)
                        .resizable()
                        .rotationEffect(.degrees(direction.rotation))
                }
        }
    }
}

struct ItemView: View {
    var item: Item
    
    var body: some View {
        Color.black.opacity(0.4)
            .overlay {
                if let itemPreview = item.texture.itemPreview {
                    Image(itemPreview)
                        .interpolation(.none)
                        .resizable()
                        .padding(7)
                } else if let block = item.previewBlock {
                    PrismCanvas(tilt: 1) {
                        block
                    }
                    .scaleEffect(y: 0.69)
                    .offset(y: 10)
                }
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 6)
                    .opacity(0.1)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .opacity(0.5)
                    .padding(2)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Color.black, lineWidth: 0.5)
                    .opacity(0.5)
            }
            .frame(width: 65, height: 65)
    }
}

struct Block: View {
    var tilt: CGFloat
    var length: CGFloat
    var levitation: CGFloat
    var item: Item
    
    var topPressed: (() -> Void)?
    var leftPressed: (() -> Void)?
    var rightPressed: (() -> Void)?
    
    var body: some View {
        PrismView(
            tilt: tilt,
            size: .init(width: length, height: length),
            extrusion: length,
            levitation: levitation,
            shadowOpacity: 0
        ) {
            if let top = item.texture.blockTop ?? item.texture.blockSide {
                Button {} label: {
                    Image(top)
                        .interpolation(.none)
                        .resizable()
                }
            } else {
                Color.clear
            }
        } left: {
            if let side = item.texture.blockSide {
                Button {} label: {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.1)
                }
            } else {
                Color.clear
            }
        } right: {
            if let side = item.texture.blockSide {
                Button {} label: {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.2)
                }
            } else {
                Color.clear
            }
        }
    }
}
