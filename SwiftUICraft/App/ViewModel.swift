//
//  ViewModel.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/7/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

/**
 Contains all the game logic.
 */
class ViewModel: ObservableObject {
    // MARK: - Properties

    @Published var status = GameStatus.playing
    
    /// Currently there's 3 levels.
    @Published var levels = [Level.level1, Level.level2, Level.level3]
    
    /// Change this to 0, 1, or 2.
    @Published var selectedLevelIndex = 2
    
    /// The current selected item in the hotbar.
    @Published var selectedItem = Item.dirt
    
    /// Corresponds to up/down/left/right controls.
    @Published var offset = CGSize.zero
    
    /// If liquid is animating in, the task will be stored here.
    @Published var currentLiquidAnimationTask: Task<Void, any Error>?
    
    /// Corresponds to zoom controls.
    @Published var scale = CGFloat(1)
    
    // MARK: - Tilting
    
    /// Saves the drag gesture's translation.
    @Published var savedTranslation = CGFloat(0)
    
    /// This will have a value when the user is dragging.
    @Published var additionalTranslation = CGFloat(0)
    
    /// The `tilt` passed to Prism for adjusting POV.
    var tilt: CGFloat {
        let translation = savedTranslation + additionalTranslation
        let tilt = 0.3 - (translation / 100)
        return max(0.00001, tilt)
    }
    
    /// The current level.
    var level: Level {
        get {
            levels[selectedLevelIndex]
        } set {
            levels[selectedLevelIndex] = newValue
        }
    }
    
    /// The length of each block.
    let blockLength = CGFloat(50)
}

extension ViewModel {
    /// Add the current selected item at a coordinate.
    func addBlock(at coordinate: Coordinate) {
        /// Cancel existing animations if there's any.
        currentLiquidAnimationTask?.cancel()
        currentLiquidAnimationTask = nil
        
        switch selectedItem {
        case .bucket:
            addLiquid(at: coordinate, initialBlockKind: .waterSource, blockKind: .water)
        case .lavaBucket:
            addLiquid(at: coordinate, initialBlockKind: .lavaSource, blockKind: .lava)
        default:
            /// Only allow blocks (items that have a block preview) to be placed, not other items.
            guard let associatedBlockKind = selectedItem.associatedBlockKind else { return }
            
            var blocks = level.world.blocks
            DispatchQueue.global().async {
                /// Prevent duplicates.
                if let firstIndex = blocks.firstIndex(where: { $0.coordinate == coordinate }) {
                    blocks.remove(at: firstIndex)
                }
                let block = Block(coordinate: coordinate, blockKind: associatedBlockKind)
                blocks.append(block)
                blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// maintain order
                
                DispatchQueue.main.async {
                    self.level.world.blocks = blocks
                }
            }
        }
    }
    
    /// Add water or lava at a coordinate and animate it to surrounding blocks.
    func addLiquid(at coordinate: Coordinate, initialBlockKind: BlockKind, blockKind: BlockKind) {
        var blocks = level.world.blocks
        DispatchQueue.global().async {
            blocks = self.modifyWorldForLiquid(existingBlocks: blocks, isInitial: true, initialBlockKind: initialBlockKind, blockKind: blockKind, at: coordinate, depth: 0)
            blocks = blocks.sorted { a, b in a.coordinate < b.coordinate } /// Maintain the order.
            blocks = blocks.uniqued()

            DispatchQueue.main.async {
                self.level.world.blocks = blocks
            }

            /**
             1. The block
             2. The block's index in `blocks`
             3. The block's planar distance from the source block
             */
            let blocksWithIndicesAndDistance: [(Block, Int, Int)] = blocks.indices.compactMap { index in
                let block = blocks[index]
                
                if block.blockKind.isLiquid {
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
                    $0.2 < $1.2 /// Sort by distance.
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
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 1)) {
                            self.level.world.blocks = blocks
                        }
                    }()
                    
                    try await Task.sleep(seconds: 0.02) /// Add a slight delay to make a ripple effect.
                }
            }
            
            DispatchQueue.main.async {
                self.currentLiquidAnimationTask = task
            }
        }
    }
    
    /// A recursive algorithm that places water or lava.
    func modifyWorldForLiquid(
        existingBlocks: [Block],
        maximumSpread: Int = 3,
        isInitial: Bool,
        initialBlockKind: BlockKind,
        blockKind: BlockKind,
        at coordinate: Coordinate,
        depth: Int
    ) -> [Block] {
        var liquidSpread = maximumSpread
        var existingBlocks = existingBlocks
        
        /// add a block if there's none there currently
        if !existingBlocks.contains(where: { $0.coordinate == coordinate }) {
            /// otherwise, add liquid and sink it to the surface
            if let surface = existingBlocks.last(where: {
                $0.coordinate.row == coordinate.row
                    && $0.coordinate.column == coordinate.column
                    && $0.coordinate.levitation < coordinate.levitation
            }) {
                let waterHeight = CGFloat(coordinate.levitation - surface.coordinate.levitation) - (0.2 + CGFloat(depth) * 0.2) /// make the extrusion larger
                let waterAboveSurfaceCoordinate = Coordinate(row: coordinate.row, column: coordinate.column, levitation: surface.coordinate.levitation + 1)
                let waterAboveSurface = Block(coordinate: waterAboveSurfaceCoordinate, blockKind: isInitial ? initialBlockKind : blockKind, extrusionMultiplier: max(0, waterHeight), active: false)
                existingBlocks.append(waterAboveSurface)
                existingBlocks = modifyWorldForLiquid(
                    existingBlocks: existingBlocks,
                    isInitial: false,
                    initialBlockKind: initialBlockKind,
                    blockKind: blockKind,
                    at: waterAboveSurfaceCoordinate,
                    depth: 0
                )
            }
        }
        
        let coordinateUnderneath = Coordinate(row: coordinate.row, column: coordinate.column, levitation: coordinate.levitation - 1)
        
        if
            depth == 0, /// Only spread if the depth is 0 and the block underneath is land.
            existingBlocks.contains(where: { $0.coordinate == coordinateUnderneath && !$0.blockKind.isLiquid })
        {
            /// Check if current block is on a surface.
            if existingBlocks.contains(where: {
                $0.coordinate == coordinateUnderneath
            }) {
                /// Check surrounding blocks.
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
                    liquidSpread = 1
                }
                
                for index in 0...liquidSpread {
                    /// Draw a diamond-shaped ring of blocks.
                    for column in -index...index {
                        let rowOffset = index - abs(column)
                        let liquidCoordinate = Coordinate(row: coordinate.row + rowOffset, column: coordinate.column + column, levitation: coordinate.levitation)
                  
                        /// Add a liquid block.
                        existingBlocks = modifyWorldForLiquid(
                            existingBlocks: existingBlocks,
                            isInitial: false,
                            initialBlockKind: initialBlockKind,
                            blockKind: blockKind,
                            at: liquidCoordinate,
                            depth: depth + index + 1
                        )
                            
                        /// Add a liquid block mirrored across the x-axis.
                        /// No need to add in the case of the first and last.
                        if abs(column) != index {
                            let liquidCoordinate = Coordinate(row: coordinate.row - rowOffset, column: coordinate.column + column, levitation: coordinate.levitation)
                            existingBlocks = modifyWorldForLiquid(
                                existingBlocks: existingBlocks,
                                isInitial: false,
                                initialBlockKind: initialBlockKind,
                                blockKind: blockKind,
                                at: liquidCoordinate,
                                depth: depth + index + 1
                            )
                        }
                    }
                }
            }
        }
        
        return existingBlocks
    }
}

extension ViewModel {
    /// Add the current selected item at a coordinate.
    func removeBlock(at coordinate: Coordinate) {
        /// Cancel existing animations if there's any.
        currentLiquidAnimationTask?.cancel()
        currentLiquidAnimationTask = nil
        
        var blocks = level.world.blocks
        DispatchQueue.global().async {
            /// Prevent duplicates.
            if let firstIndex = blocks.firstIndex(where: { $0.coordinate == coordinate }) {
                blocks.remove(at: firstIndex)
            }
            
            DispatchQueue.main.async {
                self.level.world.blocks = blocks
            }
        }
    }
}
