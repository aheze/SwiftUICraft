//
//  MenuView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

struct MenuView: View {
    @ObservedObject var model: ViewModel

    var body: some View {
        Color.clear.overlay {
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 20) {
                    MenuButton(text: "Resume") {
                        model.status = .playing
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

extension MenuView {
    func levelButton(index: Int) -> some View {
        let active = model.selectedLevelIndex == index

        return HStack(spacing: 20) {
            MenuButton(text: "Level \(index + 1)", active: active) {
                model.selectedLevelIndex = index
            }

            if active {
                ControlView(control: .reset) {
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
