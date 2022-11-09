//
//  BlockView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Prism
import SwiftUI

/**
 A single block for drawing in `GameView`.
 
 Powered by Prism.
 */
struct BlockView: View {
    var tilt: CGFloat
    var length: CGFloat
    var levitation: CGFloat
    var block: Block
    
    var topTapped: (() -> Void)?
    var leftTapped: (() -> Void)?
    var rightTapped: (() -> Void)?
    var topHeld: (() -> Void)?
    var leftHeld: (() -> Void)?
    var rightHeld: (() -> Void)?
    
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
                
                /// Make the hue change in a ripple.
                let delay = abs(block.extrusionMultiplier - 1) / CGFloat(0.6)
                
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
                    return length * block.extrusionMultiplier
                } else {
                    if block.extrusionMultiplier > 1 {
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
                if block.extrusionMultiplier > 1 {
                    return levitation + length * (block.extrusionMultiplier - 0.2)
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
            if let topTapped, let topHeld {
                top
                    .onTapGesture {
                        topTapped()
                    }
                    .onLongPressGesture(minimumDuration: block.holdDurationForRemoval) {
                        topHeld()
                    }
            } else {
                top
            }
            
        } left: {
            if let leftTapped, let leftHeld {
                left
                    .onTapGesture {
                        leftTapped()
                    }
                    .onLongPressGesture(minimumDuration: block.holdDurationForRemoval) {
                        leftHeld()
                    }
            } else {
                left
            }
        } right: {
            if let rightTapped, let rightHeld {
                right
                    .onTapGesture {
                        rightTapped()
                    }
                    .onLongPressGesture(minimumDuration: block.holdDurationForRemoval) {
                        rightHeld()
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
