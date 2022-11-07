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

struct World {
    var width = 15
    var height = 6
    var blocks = [Block]()
    
    static let defaultWorld: Self = {
        let width = 15
        let height = 6
        var blocks = [Block]()
        
        /// base dirt layer
        for row in 0..<height {
            for column in 0..<width {
                let shouldBeDirt = (column - (height - row)) < 3
                
                let coordinate = Coordinate(row: row, column: column, levitation: 0)
                let block = Block(coordinate: coordinate, blockKind: shouldBeDirt ? .dirt : .grass)
                blocks.append(block)
            }
        }
        
        /// jagged shape
        for row in 0..<height {
            for column in 0..<10 {
                let shouldAdd = (column - (height - row)) < 3
                
                if shouldAdd {
                    let coordinate = Coordinate(row: row, column: column, levitation: 1)
                    let block = Block(coordinate: coordinate, blockKind: .dirt)
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
                    let block = Block(coordinate: coordinate, blockKind: .grass)
                    blocks.append(block)
                }
            }
        }
        
        /// fill in some more grass blocks at the bottom
        for (x, y) in [(2, 4), (1, 5), (2, 5), (3, 5)] {
            let coordinate = Coordinate(row: y, column: x, levitation: 2)
            let block = Block(coordinate: coordinate, blockKind: .grass)
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
                    let block = Block(coordinate: coordinate, blockKind: .leaf)
                    blocks.append(block)
                }
                
                let coordinateLeft = Coordinate(row: trunk.1, column: trunk.0 - 1, levitation: levitation)
                let blockLeft = Block(coordinate: coordinateLeft, blockKind: .leaf)
                blocks.append(blockLeft)
                
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, blockKind: .log)
                blocks.append(block)
                
                let coordinateRight = Coordinate(row: trunk.1, column: trunk.0 + 1, levitation: levitation)
                let blockRight = Block(coordinate: coordinateRight, blockKind: .leaf)
                blocks.append(blockRight)
                
                /// bottom leaves
                for (x, y) in [(-1, 1), (0, 1), (1, 1)] {
                    let coordinate = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let block = Block(coordinate: coordinate, blockKind: .leaf)
                    blocks.append(block)
                }
            case 6:
                /// second layer of leaves, in cross shape
                for (x, y) in [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)] {
                    let coordinateRight = Coordinate(row: trunk.1 + y, column: trunk.0 + x, levitation: levitation)
                    let block = Block(coordinate: coordinateRight, blockKind: .leaf)
                    blocks.append(block)
                }
            case 7:
                /// top leaf block
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, blockKind: .leaf)
                blocks.append(block)
            default:
                /// just a log
                let coordinate = Coordinate(row: trunk.1, column: trunk.0, levitation: levitation)
                let block = Block(coordinate: coordinate, blockKind: .log)
                blocks.append(block)
            }
        }
        
        blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
        let world = World(blocks: blocks)
        
        return world
    }()
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
        case .dirt, .grass, .log, .stone, .leaf:
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

enum Texture {
    case differentSides(top: String, sides: String)
    case image(String)
    case water
    case waterSource
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
    
    func addBlock(at coordinate: Coordinate) {
        if selectedItem == .bucket {
            var blocks = world.blocks
            DispatchQueue.global().async {
                blocks = modifyWorldForWater(existingBlocks: blocks, at: coordinate, depth: 0, isInitial: true)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                blocks = blocks.uniqued()
                
//                let newlyAddedBlocks = blocks.filter { !$0.active }

                DispatchQueue.main.async {
                    world.blocks = blocks
                }

                /**
                 1. the block
                 2. the block's index in `blocks`
                 3. the block's planar distance from the source block
                 */
                let blocksWithIndicesAndDistance: [(Block, Int, Int)] = blocks.indices.compactMap { index in
                    let block = blocks[index]
                    
                    if block.blockKind.isWater {
                        return (
                            block,
                            index,
                            DistanceSquared(
                                from: (x: block.coordinate.column, y: block.coordinate.row),
                                to: (x: coordinate.column, y: coordinate.row)
                            )
                        )
                    } else {
                        return nil
                    }
                }
                
                let groupedBlocksCollection = blocksWithIndicesAndDistance
                    .sorted {
                        $0.2 < $1.2 /// sort by distance
                    }.group { $0.2 }
                
//                print("blocksWithDistance.map \(groupedBlocks)")
                
                for index in groupedBlocksCollection.indices {
                    let groupedBlocks = groupedBlocksCollection[index]
                    var blocks = world.blocks
                    for block in groupedBlocks {
                        blocks[block.1].active = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 1, blendDuration: 1)) {
                            world.blocks = blocks
                        }
                    }
                }
            }
            
        } else {
            /// only allow blocks (items that have a block preview) to be placed, not other items
            guard let associatedBlockKind = selectedItem.associatedBlockKind else { return }
            
            var blocks = world.blocks
            DispatchQueue.global().async {
                let block = Block(coordinate: coordinate, blockKind: associatedBlockKind)
                blocks.append(block)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                
                DispatchQueue.main.async {
                    world.blocks = blocks
                }
            }
        }
    }
    
    func modifyWorldForWater(existingBlocks: [Block], at coordinate: Coordinate, depth: Int, isInitial: Bool = false) -> [Block] {
        var waterSpread = 5
        var existingBlocks = existingBlocks
        
        /// add a block if there's none there currently
        if !existingBlocks.contains(where: { $0.coordinate == coordinate }) {
            /// otherwise, add water and sink it to the surface
            if let surface = existingBlocks.last(where: {
                $0.coordinate.row == coordinate.row
                    && $0.coordinate.column == coordinate.column
                    && $0.coordinate.levitation < coordinate.levitation
            }) {
                let waterHeight = CGFloat(coordinate.levitation - surface.coordinate.levitation) - (0.2 + CGFloat(depth) * 0.2) /// make the extrusion larger
                let waterAboveSurfaceCoordinate = Coordinate(row: coordinate.row, column: coordinate.column, levitation: surface.coordinate.levitation + 1)
                let waterAboveSurface = Block(coordinate: waterAboveSurfaceCoordinate, blockKind: isInitial ? .waterSource : .water, extrusionPercentage: max(0, waterHeight), active: false)
                existingBlocks.append(waterAboveSurface)
                existingBlocks = modifyWorldForWater(existingBlocks: existingBlocks, at: waterAboveSurfaceCoordinate, depth: 0)
            }
        }
        
        let coordinateUnderneath = Coordinate(row: coordinate.row, column: coordinate.column, levitation: coordinate.levitation - 1)
        
        if
            depth == 0, /// only spread if the depth is 0 and the block underneath is land
            existingBlocks.contains(where: { $0.coordinate == coordinateUnderneath && !$0.blockKind.isWater })
        {
            /// check if current block is on a surface
            if existingBlocks.contains(where: {
                $0.coordinate == coordinateUnderneath
            }) {
                let surroundingOffsets: [(x: Int, y: Int)] = [
                    (-1, -1), (0, -1), (1, -1),
                    (-1, 0), (1, 0),
                    (-1, 1), (0, 1), (1, 1),
                ]
                
                let surroundingCoordinates = surroundingOffsets.map {
                    Coordinate(row: coordinateUnderneath.row + $0.y, column: coordinateUnderneath.column + $0.x, levitation: coordinateUnderneath.levitation)
                }
                
                let surroundingSurfaces = surroundingCoordinates.filter { surroundingCoordinate in
                    existingBlocks.contains(where: { $0.coordinate == surroundingCoordinate })
                }
                
                if surroundingSurfaces.count < 5 {
                    waterSpread = 1
                }
                
                for index in 0...waterSpread {
                    /// draw a diamond-shaped ring of blocks
                    for column in -index...index {
                        let rowOffset = index - abs(column)
                        let waterCoordinate = Coordinate(row: coordinate.row + rowOffset, column: coordinate.column + column, levitation: coordinate.levitation)
                        
                        existingBlocks = modifyWorldForWater(existingBlocks: existingBlocks, at: waterCoordinate, depth: depth + index + 1)
                            
                        if column != -index {
                            let waterCoordinate = Coordinate(row: coordinate.row - rowOffset, column: coordinate.column + column, levitation: coordinate.levitation)
                            existingBlocks = modifyWorldForWater(existingBlocks: existingBlocks, at: waterCoordinate, depth: depth + index + 1)
                        }
                    }
                }
            }
        }
        
        return existingBlocks
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
                                block: block
                            ) /** topPressed */ {
                                let coordinate = Coordinate(
                                    row: block.coordinate.row,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation + 1
                                )
                                addBlock(at: coordinate)
                            } leftPressed: {
                                let coordinate = Coordinate(
                                    row: block.coordinate.row + 1,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation
                                )
                                addBlock(at: coordinate)
                            } rightPressed: {
                                let coordinate = Coordinate(
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
                        KeyboardButton(key: .reset) {
                            var blocks = world.blocks
                            DispatchQueue.global().async {
                                blocks = blocks.filter { !$0.blockKind.isWater }
                                
                                DispatchQueue.main.async {
                                    world.blocks = blocks
                                }
                            }
                        }
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
                        KeyboardButton(key: .center) {
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
                switch item.preview {
                case let .image(image):
                    Image(image)
                        .interpolation(.none)
                        .resizable()
                        .padding(7)
                case let .blockView(blockView):
                    PrismCanvas(tilt: 1) {
                        blockView
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
    var block: Block
    
    var topPressed: (() -> Void)?
    var leftPressed: (() -> Void)?
    var rightPressed: (() -> Void)?
    
    var top: some View {
        Group {
            switch block.blockKind.texture {
            case let .differentSides(top, _):
                Image(top)
                    .interpolation(.none)
                    .resizable()
            case let .image(image):
                Image(image)
                    .interpolation(.none)
                    .resizable()
            case .water:
                Color.blue.opacity(0.4)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.8)
            }
        }
    }
    
    var left: some View {
        Group {
            switch block.blockKind.texture {
            case let .differentSides(_, sides):
                Image(sides)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.1)
            case let .image(image):
                Image(image)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.1)
            case .water:
                Color.blue.opacity(0.3)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.55)
            }
        }
    }
    
    var right: some View {
        Group {
            switch block.blockKind.texture {
            case let .differentSides(_, sides):
                Image(sides)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.2)
            case let .image(image):
                Image(image)
                    .interpolation(.none)
                    .resizable()
                    .brightness(-0.2)
            case .water:
                Color.blue.opacity(0.2)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.45)
            }
        }
    }
    
    var body: some View {
        PrismView(
            tilt: tilt,
            size: .init(width: length, height: length),
            extrusion: block.active ? length * block.extrusionPercentage : 0,
            levitation: levitation,
            shadowOpacity: 0.25
        ) {
            if let topPressed {
                top
                    .onTapGesture {
                        topPressed()
                    }
            } else {
                top
            }
            
        } left: {
            if let leftPressed {
                left
                    .onTapGesture {
                        leftPressed()
                    }
            } else {
                left
            }
        } right: {
            if let rightPressed {
                right
                    .onTapGesture {
                        rightPressed()
                    }
            } else {
                right
            }
        }
        .allowsHitTesting(!block.blockKind.isWater)
    }
}

/// from https://stackoverflow.com/a/46354989/14351818
public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

func DistanceSquared(from: (x: Int, y: Int), to: (x: Int, y: Int)) -> Int {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}

/// from https://stackoverflow.com/a/43520047/14351818
extension Sequence {
    func group<GroupingType: Hashable>(by key: (Iterator.Element) -> GroupingType) -> [[Iterator.Element]] {
        var groups: [GroupingType: [Iterator.Element]] = [:]
        var groupsOrder: [GroupingType] = []
        forEach { element in
            let key = key(element)
            if case nil = groups[key]?.append(element) {
                groups[key] = [element]
                groupsOrder.append(key)
            }
        }
        return groupsOrder.map { groups[$0]! }
    }
}
