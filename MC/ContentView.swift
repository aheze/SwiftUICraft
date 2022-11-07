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
    var coordinateToItem = [Coordinate: Item]()
    
    struct Coordinate: Hashable {
        var row: Int
        var column: Int
        var levitation: Int
    }
    
    static let defaultWorld: Self = {
        let width = 15
        let height = 6
        var coordinateToItem = [Coordinate: Item]()
        
        for row in 0..<height {
            for column in 0..<width {
                let coordinate = Coordinate(row: row, column: column, levitation: 0)
                coordinateToItem[coordinate] = Item.dirt
            }
        }
        
        let world = World(coordinateToItem: coordinateToItem)
        
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
    
    var block: Block? {
        switch self {
        case .dirt, .grass, .log, .stone, .leaf:
            return Block(tilt: 1, length: 20, item: self)
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
//                        .scaleEffect(0.8)
                }
        }
    }
    
    var game: some View {
        PrismCanvas(tilt: tilt) {
            Color.black.opacity(0.5)
                .frame(
                    width: CGFloat(world.width) * blockLength,
                    height: CGFloat(world.height) * blockLength
                )
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
                        .buttonStyle(.minecraft)
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
            Image("button")
                .interpolation(.none)
                .resizable()
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(direction.rotation))
        }
        .buttonStyle(.minecraft)
    }
}

struct ItemView: View {
    var item: Item
    
    var body: some View {
        Color.black.opacity(0.1)
            .overlay {
                if let itemPreview = item.texture.itemPreview {
                    Image(itemPreview)
                        .interpolation(.none)
                        .resizable()
                        .padding(7)
                } else if let block = item.block {
                    PrismCanvas(tilt: 1) {
                        block
                    }
                    .scaleEffect(y: 0.69)
                    .offset(y: 10)
                }
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Color.black, lineWidth: 6)
                    .opacity(0.1)
            }
            .overlay {
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .opacity(0.3)
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
    var item: Item
    
    var body: some View {
        PrismView(tilt: tilt, size: .init(width: length, height: length), extrusion: length) {
            if let top = item.texture.blockTop ?? item.texture.blockSide {
                Image(top)
                    .interpolation(.none)
                    .resizable()
            } else {
                Color.clear
            }
        } left: {
            if let side = item.texture.blockSide {
                Image(side)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.1)
            } else {
                Color.clear
            }
        } right: {
            if let side = item.texture.blockSide {
                Image(side)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.2)
            } else {
                Color.clear
            }
        }
    }
}

struct MinecraftButtonStyle: ButtonStyle {
    var scale = CGFloat(0.95)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.5 : 0)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == MinecraftButtonStyle {
    static var minecraft: MinecraftButtonStyle {
        MinecraftButtonStyle()
    }
}
