//
//  MinecraftViewModel.swift
//  MC
//
//  Created by A. Zheng (github.com/aheze) on 11/7/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

class MinecraftViewModel: ObservableObject {
    @Published var level = Level.level2
    @Published var selectedItem = Item.dirt
    @Published var offset = CGSize.zero
    
    @Published var currentTask: Task<Void, any Error>?
    @Published var scale = CGFloat(1)
    @Published var savedTranslation = CGFloat(0)
    @Published var additionalTranslation = CGFloat(0)
    
    var tilt: CGFloat {
        let translation = savedTranslation + additionalTranslation
        let tilt = 0.3 - (translation / 100)
        return tilt
    }
    
    let blockLength = CGFloat(50)
}

extension MinecraftViewModel {
    func addBlock(at coordinate: Coordinate) {
        currentTask?.cancel()
        currentTask = nil
        
        if selectedItem == .bucket {
            var blocks = level.world.blocks
            DispatchQueue.global().async {
                blocks = self.modifyWorldForWater(existingBlocks: blocks, at: coordinate, depth: 0, isInitial: true)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                blocks = blocks.uniqued()

                DispatchQueue.main.async {
                    self.level.world.blocks = blocks
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
                
                let task = Task {
                    for index in groupedBlocksCollection.indices {
                        try Task.checkCancellation()
                        
                        let groupedBlocks = groupedBlocksCollection[index]
                        var blocks = self.level.world.blocks
                        for block in groupedBlocks {
                            let blockIndex = block.1
                            if blocks.indices.contains(blockIndex) {
                                blocks[blockIndex].active = true
                            }
                        }
                        
                        await { @MainActor in
                            withAnimation(.spring(response: 0.2, dampingFraction: 1, blendDuration: 1)) {
                                self.level.world.blocks = blocks
                            }
                        }()
                        
                        try await Task.sleep(seconds: 0.1)
                    }
                }
                
                DispatchQueue.main.async {
                    self.currentTask = task
                }
            }
            
        } else {
            /// only allow blocks (items that have a block preview) to be placed, not other items
            guard let associatedBlockKind = selectedItem.associatedBlockKind else { return }
            
            var blocks = level.world.blocks
            DispatchQueue.global().async {
                let block = Block(coordinate: coordinate, blockKind: associatedBlockKind)
                blocks.append(block)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                
                DispatchQueue.main.async {
                    self.level.world.blocks = blocks
                }
            }
        }
    }
    
    func modifyWorldForWater(existingBlocks: [Block], at coordinate: Coordinate, depth: Int, isInitial: Bool = false) -> [Block] {
        var waterSpread = 3
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
}
