//
//  ContentView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/6/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Prism
import SwiftUI

struct ContentView: View {
    @StateObject var model = MinecraftViewModel()
    
    var body: some View {
        Color.clear.overlay {
            controls
                .opacity(model.gameActive ? 1 : 0)
        }
        .background {
            Color.clear
                .overlay {
                    game
                        .scaleEffect(model.scale)
                        .offset(y: 120)
                }
                .offset(model.offset)
                .drawingGroup()
                .background {
                    LinearGradient(colors: model.level.background.map { Color(uiColor: .init(hex: $0)) }, startPoint: .top, endPoint: .bottom)
                }
                .ignoresSafeArea()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            model.additionalTranslation = value.translation.width
                        }
                        .onEnded { value in
                            model.savedTranslation += model.additionalTranslation
                            model.additionalTranslation = 0
                        }
                )
        }
        .overlay {
            if !model.gameActive {
                Color.clear.overlay {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 20) {
                            MenuButton(text: "Resume") {
                                model.gameActive = true
                            }
                            
                            MenuButton(text: "Reset Liquids") {
                                var blocks = model.level.world.blocks
                                DispatchQueue.global().async {
                                    blocks = blocks.filter { !$0.blockKind.isLiquid }
    
                                    DispatchQueue.main.async {
                                        withAnimation {
                                            model.level.world.blocks = blocks
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            levelButton(index: 0)
                            levelButton(index: 1)
                            levelButton(index: 2)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.75))
                    }
                }
            
                .background {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    func levelButton(index: Int) -> some View {
        let active = model.selectedLevelIndex == index
        
        return HStack(spacing: 20) {
            MenuButton(text: "Level \(index + 1)", active: active) {
                model.selectedLevelIndex = index
            }
            
            if active {
                KeyboardButton(key: .reset) {
                    let level: Level
                    switch index {
                    case 0:
                        level = Level.level1
                    case 1:
                        level = Level.level2
                    case 2:
                        level = Level.level3
                    default:
                        fatalError("Level \(index) out of range.")
                    }
                    
                    model.levels[index] = level
                }
            }
        }
    }
    
    var game: some View {
        PrismCanvas(tilt: model.tilt) {
            let size = CGSize(
                width: CGFloat(model.level.world.width) * model.blockLength,
                height: CGFloat(model.level.world.height) * model.blockLength
            )
            
            PrismColorView(tilt: model.tilt, size: size, extrusion: 20, levitation: -20, color: Color.white)
                .overlay {
                    ZStack(alignment: .topLeading) {
                        ForEach(model.level.world.blocks, id: \.hashValue) { block in
                            BlockView(
                                tilt: model.tilt,
                                length: model.blockLength,
                                levitation: CGFloat(block.coordinate.levitation) * model.blockLength,
                                block: block
                            ) /** topPressed */ {
                                let coordinate = Coordinate(
                                    row: block.coordinate.row,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation + 1
                                )
                                model.addBlock(at: coordinate)
                            } leftPressed: {
                                let coordinate = Coordinate(
                                    row: block.coordinate.row + 1,
                                    column: block.coordinate.column,
                                    levitation: block.coordinate.levitation
                                )
                                model.addBlock(at: coordinate)
                            } rightPressed: {
                                let coordinate = Coordinate(
                                    row: block.coordinate.row,
                                    column: block.coordinate.column + 1,
                                    levitation: block.coordinate.levitation
                                )
                                model.addBlock(at: coordinate)
                            }
                            .offset(
                                x: CGFloat(block.coordinate.column) * model.blockLength,
                                y: CGFloat(block.coordinate.row) * model.blockLength
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
                        KeyboardButton(key: .pause) {
                            model.gameActive = false
                        }
                        KeyboardButton(key: .zoomOut) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.scale -= 0.1
                            }
                        }
                        KeyboardButton(key: .zoomIn) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.scale += 0.1
                            }
                        }
                    }
                    
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                        .frame(height: 4)
                    
                    GridRow {
                        block
                        KeyboardButton(key: .direction(.up)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.height += 100
                            }
                        }
                        block
                    }
                    GridRow {
                        KeyboardButton(key: .direction(.left)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.width += 100
                            }
                        }
                        KeyboardButton(key: .center) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset = .zero
                            }
                        }
                        KeyboardButton(key: .direction(.right)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.width -= 100
                            }
                        }
                    }
                    GridRow {
                        block
                        KeyboardButton(key: .direction(.down)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.height -= 100
                            }
                        }
                        block
                    }
                }
                Spacer()
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    Text("SWIFTUI")
                        .foregroundColor(.orange)
                        .brightness(0.6)
                    
                    Text("CRAFT")
                        .foregroundColor(.white)
                }
                .font(.system(size: 40, weight: .heavy))
                .shadow(color: .black, radius: 0, x: 3, y: 3)
                .rotation3DEffect(.degrees(10), axis: (1, 0, 0), perspective: 2)
                
                Text("@aheze0")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .opacity(0.5)
            }
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 0) {
                ForEach(model.level.items, id: \.rawValue) { item in
                    let selected = model.selectedItem == item
                        
                    Button {
                        model.selectedItem = item
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
    
    @State var animated = false

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
                Color.blue.opacity(0.3)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.6)
            case .laser:
                Color.yellow.opacity(0.5)
            case .lava:
                let delay = abs(block.extrusionPercentage - 1) / CGFloat(0.6)
                
                LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(0.8)
                    .hueRotation(.degrees(animated ? -20 : 20))
                    .animation(.linear(duration: 1.4).repeatForever().delay(delay), value: animated)
            case .lavaSource:
                Color.red
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
                Color.blue.opacity(0.15)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.35)
            case .laser:
                Color.yellow.opacity(0.3)
                    .overlay {
                        Rectangle()
                            .strokeBorder(
                                Color.white,
                                style: .init(
                                    lineWidth: 1,
                                    lineCap: .square,
                                    dash: [40, 20],
                                    dashPhase: animated ? -240 : 0
                                )
                            )
                            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: animated)
                    }
                    .overlay(alignment: .bottom) {
                        Text("getfind.app")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .tracking(2)
                            .opacity(0.75)
                            .fixedSize()
                            .rotationEffect(.degrees(-90))
                            .offset(y: -180)
                    }
            case .lava:
                Color.orange
                    .opacity(0.7)
            case .lavaSource:
                Color.red
                    .brightness(-0.1)
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
                Color.blue.opacity(0.1)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.25)
            case .laser:
                Color.yellow.opacity(0.2)
                    .overlay {
                        Rectangle()
                            .strokeBorder(
                                Color.white,
                                style: .init(
                                    lineWidth: 1,
                                    lineCap: .square,
                                    dash: [40, 20],
                                    dashPhase: animated ? 240 : 0
                                )
                            )
                            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: animated)
                    }
            case .lava:
                Color.orange
                    .opacity(0.6)
            case .lavaSource:
                Color.red
                    .brightness(-0.2)
            }
        }
    }
    
    var body: some View {
        let extrusion: CGFloat = {
            if block.blockKind == .laser {
                if block.active {
                    return length * 10
                } else {
                    return length * 0.2
                }
            } else {
                if block.active {
                    return length * block.extrusionPercentage
                } else {
                    if block.extrusionPercentage > 1 {
                        return length * 0.2 /// water in the air
                    } else {
                        return 0 /// water on ground
                    }
                }
            }
        }()
        
        let adjustedLength: CGFloat = {
            if block.blockKind == .laser {
                return length * 0.5
            } else {
                return length
            }
        }()
        
        let adjustedLevitation: CGFloat = {
            if block.active {
                return levitation
            } else {
                if block.extrusionPercentage > 1 {
                    return levitation + length * (block.extrusionPercentage - 0.2)
                } else {
                    return levitation
                }
            }
        }()
        
        PrismView(
            tilt: tilt,
            size: .init(width: adjustedLength, height: adjustedLength),
            extrusion: extrusion,
            levitation: adjustedLevitation,
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
        .frame(width: length, height: length)
        .allowsHitTesting(!block.blockKind.isLiquid)
        .opacity(block.active ? 1 : 0)
        .onAppear {
            animated = true
        }
    }
}

struct MenuButton: View {
    var text: String
    var active: Bool? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("button_background")
                .resizable()
                .resizable(capInsets: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20), resizingMode: .stretch)
                .frame(width: 280, height: 70)
                .overlay {
                    Text(text)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.75))
                }
        }
        .overlay {
            if let active {
                if active {
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 6)
                        .padding(-6)
                }
            }
        }
    }
}
