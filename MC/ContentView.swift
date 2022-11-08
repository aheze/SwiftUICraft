//
//  ContentView.swift
//  MC
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
                    LinearGradient(colors: [.blue, .white, .white, .brown], startPoint: .top, endPoint: .bottom)
                        .opacity(0.75)
                        .background(Color.white)
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
    }
    
    
    
    
    
    var game: some View {
        PrismCanvas(tilt: model.tilt) {
            let size = CGSize(
                width: CGFloat(model.level.world.width) * model.blockLength,
                height: CGFloat(model.level.world.height) * model.blockLength
            )
            
            PrismColorView(tilt: model.tilt, size: size, extrusion: 20, levitation: -20, color: Color.blue.opacity(0.5))
                .overlay {
                    ZStack(alignment: .topLeading) {
                        ForEach(model.level.world.blocks) { block in
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
                        KeyboardButton(key: .reset) {
                            var blocks = model.level.world.blocks
                            DispatchQueue.global().async {
                                blocks = blocks.filter { !$0.blockKind.isWater }
                                
                                DispatchQueue.main.async {
                                    model.level.world.blocks = blocks
                                }
                            }
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
                Color.blue.opacity(0.15)
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
                Color.blue.opacity(0.1)
            case .waterSource:
                Color.blue.brightness(-0.1).opacity(0.45)
            }
        }
    }
    
    var body: some View {
        let extrusion: CGFloat = {
            if block.active {
                return length * block.extrusionPercentage
            } else {
                if block.extrusionPercentage > 1 {
                    return length * 0.2 /// water in the air
                } else {
                    return 0 /// water on ground
                }
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
            size: .init(width: length, height: length),
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
        .allowsHitTesting(!block.blockKind.isWater)
        .opacity(block.active ? 1 : 0)
    }
}

