//
//  ContentView.swift
//  MC
//
//  Created by A. Zheng (github.com/aheze) on 11/6/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Prism
import SwiftUI

enum KeyboardKey {
    case direction(Direction)
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
        case .reset:
            return "button_reset"
        case .zoomIn:
            return "button_in"
        case .zoomOut:
            return "button_out"
        }
    }
}

struct World {
    var width = 15
    var height = 6
    var blocks = [Block]()
    
    struct Coordinate: Hashable, Comparable {
        var row: Int
        var column: Int
        var levitation: Int
        
        static func < (lhs: World.Coordinate, rhs: World.Coordinate) -> Bool {
            /// from https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
            let predicates: [(World.Coordinate, World.Coordinate) -> Bool] = [ // <2>
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
    
    /// represents a chunk in the world
    struct Block: Identifiable {
        var id: Coordinate {
            coordinate
        }

        var coordinate: Coordinate
        var item: Item
        var extrusionPercentage = CGFloat(1)
    }
    
    static let defaultWorld: Self = {
        let width = 15
        let height = 6
        var blocks = [Block]()
        
        /// base dirt layer
        for row in 0..<height {
            for column in 0..<width {
                let shouldBeDirt = (column - (height - row)) < 3
                
                let coordinate = Coordinate(row: row, column: column, levitation: 0)
                let block = Block(coordinate: coordinate, item: shouldBeDirt ? .dirt : .grass)
                blocks.append(block)
            }
        }
        
        /// jagged shape
        for row in 0..<height {
            for column in 0..<10 {
                let shouldAdd = (column - (height - row)) < 3
                
                if shouldAdd {
                    let coordinate = Coordinate(row: row, column: column, levitation: 1)
                    let block = Block(coordinate: coordinate, item: .dirt)
                    blocks.append(block)
                }
            }
        }
     
        /// jagged shape
        for row in 0..<height {
            for column in 0..<10 {
                let shouldAdd = (column - (height - row)) < 0
                
                if shouldAdd {
                    let coordinate = Coordinate(row: row, column: column, levitation: 2)
                    let block = Block(coordinate: coordinate, item: .grass)
                    blocks.append(block)
                }
            }
        }
        
        /// fill in some more grass blocks at the bottom
        for (x, y) in [(2, 4), (1, 5), (2, 5), (3, 5)] {
            let coordinate = Coordinate(row: y, column: x, levitation: 2)
            let block = Block(coordinate: coordinate, item: .grass)
            blocks.append(block)
        }
        
        /// tree
        let trunk = (11, 2)
        for levitation in 1..<8 {
            switch levitation {
            case 5:
                /// first layer leaves
                for (x, y) in [(-1, -1), (0, -1), (1, -1)] {
                    let coordinate = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let block = Block(coordinate: coordinate, item: .leaf)
                    blocks.append(block)
                }
                
                let coordinateLeft = Coordinate(row: trunk.1, column: trunk.0 - 1, levitation: levitation)
                let blockLeft = Block(coordinate: coordinateLeft, item: .leaf)
                blocks.append(blockLeft)
                
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, item: .log)
                blocks.append(block)
                
                let coordinateRight = Coordinate(row: trunk.1, column: trunk.0 + 1, levitation: levitation)
                let blockRight = Block(coordinate: coordinateRight, item: .leaf)
                blocks.append(blockRight)
                
                /// bottom leaves
                for (x, y) in [(-1, 1), (0, 1), (1, 1)] {
                    let coordinate = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let block = Block(coordinate: coordinate, item: .leaf)
                    blocks.append(block)
                }
            case 6:
                /// second layer of leaves, in cross shape
                for (x, y) in [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)] {
                    let coordinateRight = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let block = Block(coordinate: coordinateRight, item: .leaf)
                    blocks.append(block)
                }
            case 7:
                /// top leaf block
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, item: .leaf)
                blocks.append(block)
            default:
                /// just a log
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, item: .log)
                blocks.append(block)
            }
        }
        
        blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
        let world = World(blocks: blocks)
        
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
    
    var previewBlockView: BlockView? {
        switch self {
        case .dirt, .grass, .log, .stone, .leaf:
            return BlockView(tilt: 1, length: 20, levitation: 0, item: self)
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
    @State var offset = CGSize.zero
    
    @State var scale = CGFloat(1)
    @State var savedTranslation = CGFloat(0)
    @State var additionalTranslation = CGFloat(0)
    var tilt: CGFloat {
        let translation = savedTranslation + additionalTranslation
        let tilt = 0.3 - (translation / 100)
        return tilt
    }
    
    let blockLength = CGFloat(50)
    
    var body: some View {
        Color.clear.overlay {
            controls
        }
        .background {
            Color.clear
                .overlay {
                    game
                        .scaleEffect(scale)
                        .offset(y: 120)
                }
                .offset(offset)
                .drawingGroup()
                .background {
                    LinearGradient(colors: [.blue, .white, .white, .brown], startPoint: .top, endPoint: .bottom)
                        .opacity(0.2)
                        .background(Color.white)
                }
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            additionalTranslation = value.translation.width
                        }
                        .onEnded { value in
                            savedTranslation += additionalTranslation
                            additionalTranslation = 0
                        }
                )
        }
    }
    
    func addBlock(at coordinate: World.Coordinate) {
        if selectedItem == .bucket {
            print("Water!")
            var blocks = world.blocks
            DispatchQueue.global().async {
                let block = World.Block(coordinate: coordinate, item: selectedItem)
                blocks.append(block)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                
                DispatchQueue.main.async {
                    world.blocks = blocks
                }
            }
            
        } else {
            /// only allow blocks (items that have a block preview) to be placed, not other items
            guard selectedItem.previewBlockView != nil else { return }
            
            var blocks = world.blocks
            DispatchQueue.global().async {
                let block = World.Block(coordinate: coordinate, item: selectedItem)
                blocks.append(block)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                
                DispatchQueue.main.async {
                    world.blocks = blocks
                }
            }
        }
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
                        ForEach(world.blocks) { block in
                            BlockView(
                                tilt: tilt,
                                length: blockLength,
                                levitation: CGFloat(block.coordinate.levitation) * blockLength,
                                item: block.item
                            ) /** topPressed */ {
                                let coordinate = World.Coordinate(
                                    row: block.coordinate.row,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation + 1
                                )
                                addBlock(at: coordinate)
                            } leftPressed: {
                                let coordinate = World.Coordinate(
                                    row: block.coordinate.row + 1,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation
                                )
                                addBlock(at: coordinate)
                            } rightPressed: {
                                let coordinate = World.Coordinate(
                                    row: block.coordinate.row,
                                    column: block.coordinate.column + 1,
                                    levitation: block.coordinate.levitation
                                )
                                addBlock(at: coordinate)
                            }
                            .offset(
                                x: CGFloat(block.coordinate.column) * blockLength,
                                y: CGFloat(block.coordinate.row) * blockLength
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
                        KeyboardButton(key: .zoomOut) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                scale -= 0.1
                            }
                        }
                        KeyboardButton(key: .zoomIn) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                scale += 0.1
                            }
                        }
                        block
                    }
                    
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                        .frame(height: 4)
                    
                    GridRow {
                        block
                        KeyboardButton(key: .direction(.up)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                offset.height += 100
                            }
                        }
                        block
                    }
                    GridRow {
                        KeyboardButton(key: .direction(.left)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                offset.width += 100
                            }
                        }
                        KeyboardButton(key: .reset) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                offset = .zero
                            }
                        }
                        KeyboardButton(key: .direction(.right)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                offset.width -= 100
                            }
                        }
                    }
                    GridRow {
                        block
                        KeyboardButton(key: .direction(.down)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                offset.height -= 100
                            }
                        }
                        block
                    }
                }
                Spacer()
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 2) {
                Text("SWIFTUICRAFT")
                    .font(.system(size: 40, weight: .heavy, design: .serif))
                
                Text("@aheze0")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .opacity(0.25)
            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 5)
        .padding(.vertical, 20)
    }

    var block: some View {
        Color.clear.gridCellUnsizedAxes([.vertical, .horizontal])
    }
}

struct KeyboardButton: View {
    var key: KeyboardKey
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("button_background")
                .interpolation(.none)
                .resizable()
                .frame(width: 70, height: 70)
                .overlay {
                    if case let .direction(direction) = key {
                        Image(key.image)
                            .interpolation(.none)
                            .resizable()
                            .rotationEffect(.degrees(direction.rotation))
                    } else {
                        Image(key.image)
                            .interpolation(.none)
                            .resizable()
                    }
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
                } else if let previewBlockView = item.previewBlockView {
                    PrismCanvas(tilt: 1) {
                        previewBlockView
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

struct BlockView: View {
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
            shadowOpacity: 0.25
        ) {
            if let top = item.texture.blockTop ?? item.texture.blockSide {
                if let topPressed {
                    Image(top)
                        .interpolation(.none)
                        .resizable()
                        .onTapGesture {
                            topPressed()
                        }
                } else {
                    Image(top)
                        .interpolation(.none)
                        .resizable()
                }
                        
            } else if item == .bucket {
                Color.blue.opacity(0.75)
            }
        } left: {
            if let side = item.texture.blockSide {
                if let leftPressed {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.1)
                        .onTapGesture {
                            leftPressed()
                        }
                } else {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.1)
                }
            } else if item == .bucket {
                Color.blue.opacity(0.5)
            }
        } right: {
            if let side = item.texture.blockSide {
                if let rightPressed {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.2)
                        .onTapGesture {
                            rightPressed()
                        }
                } else {
                    Image(side)
                        .interpolation(.none)
                        .resizable()
                        .brightness(-0.2)
                }
            } else if item == .bucket {
                Color.blue.opacity(0.3)
            }
        }
    }
}
