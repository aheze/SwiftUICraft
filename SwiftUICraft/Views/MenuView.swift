//
//  MenuView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/// The game menu that displays when `model.status == .paused`.
struct MenuView: View {
    @ObservedObject var model: ViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        let largeWidth = horizontalSizeClass == .regular || verticalSizeClass == .compact

        Color.clear.overlay {
            let layout = largeWidth
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 30))
                : AnyLayout(VStackLayout(alignment: .leading, spacing: 40))

            layout {
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

                    /// This may take a couple seconds
                    MenuButton(text: model.homeIndicatorShown ? "Suppress System UI" : "Show System UI") {
                        model.homeIndicatorShown.toggle()
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    levelButton(index: 0)
                    levelButton(index: 1)
                    levelButton(index: 2)
                }
                .background(
                    Color.black.opacity(0.75)
                        .padding(-16)
                )
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
                .frame(width: 280, height: 60)
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
