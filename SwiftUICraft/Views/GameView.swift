//
//  GameView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Prism
import SwiftUI

/**
 The 3D game content.

 It's all SwiftUI — no SceneKit, SpriteKit, or anything else!
 */
struct GameView: View {
    @ObservedObject var model: ViewModel

    var body: some View {
        Color.clear
            .overlay {
                game
                    .scaleEffect(model.scale)
                    .offset(y: 120) /// Start off slightly downwards so that everything is visible.
            }
            .offset(model.offset) /// Up/down/left/right,
            .drawingGroup()
            .background {
                LinearGradient(colors: model.level.background.map { Color(uiColor: .init(hex: $0)) }, startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            .simultaneousGesture( /// For changing the tilt / POV.
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

    var game: some View {
        PrismCanvas(tilt: model.tilt) {
            let size = CGSize(
                width: CGFloat(model.level.world.width) * model.blockLength,
                height: CGFloat(model.level.world.height) * model.blockLength
            )

            /// Add a white base.
            PrismColorView(tilt: model.tilt, size: size, extrusion: 20, levitation: -20, color: Color.white)
                .overlay {
                    /// Enumerate over all blocks in the world and display them.
                    /// `model.level.world.blocks` must be sorted ascending for the 3D illusion to work.
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
                            .offset( /// Position the block.
                                x: CGFloat(block.coordinate.column) * model.blockLength,
                                y: CGFloat(block.coordinate.row) * model.blockLength
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
        }
        .scaleEffect(y: 0.69) /// Make everything a bit squished for a perspective illusion.
    }
}
