//
//  ControlsView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

struct ControlsView: View {
    @ObservedObject var model: ViewModel
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Grid {
                    GridRow {
                        ControlView(control: .pause) {
                            model.gameActive = false
                        }
                        ControlView(control: .zoomOut) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.scale -= 0.1
                            }
                        }
                        ControlView(control: .zoomIn) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.scale += 0.1
                            }
                        }
                    }
                    
                    Color.clear.gridCellUnsizedAxes(.horizontal)
                        .frame(height: 4)
                    
                    GridRow {
                        placeholder
                        ControlView(control: .direction(.up)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.height += 100
                            }
                        }
                        placeholder
                    }
                    GridRow {
                        ControlView(control: .direction(.left)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.width += 100
                            }
                        }
                        ControlView(control: .center) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset = .zero
                            }
                        }
                        ControlView(control: .direction(.right)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.width -= 100
                            }
                        }
                    }
                    GridRow {
                        placeholder
                        ControlView(control: .direction(.down)) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                                model.offset.height -= 100
                            }
                        }
                        placeholder
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

    /// a clear view for grid spacing.
    var placeholder: some View {
        Color.clear.gridCellUnsizedAxes([.vertical, .horizontal])
    }
}
