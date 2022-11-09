//
//  GameView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Prism
import SwiftUI

struct GameView: View {
    @ObservedObject var model: ViewModel

    var body: some View {
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
}
