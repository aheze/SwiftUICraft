//
//  ControlsView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import SwiftUI

/// The D-Pad and hotbar.
struct ControlsView: View {
    @ObservedObject var model: ViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        let largeWidth = horizontalSizeClass == .regular || verticalSizeClass == .compact

        Color.clear
            .overlay(alignment: .top) {
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
                
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                if largeWidth {
                    Text("@aheze0")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                        .opacity(0.5)
                        .padding(.top, 4)
                }
            }
            .overlay(alignment: .bottom) {
                let layout = largeWidth
                    ? AnyLayout(HStackLayout(alignment: .bottom, spacing: 16))
                    : AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                
                layout {
                    dPad
                    
                    OverflowLayout(spacing: 0) {
                        ForEach(model.level.items, id: \.rawValue) { item in
                            let selected = model.selectedItem == item
                        
                            Button {
                                model.selectedItem = item
                            } label: {
                                ItemView(item: item)
                            }
                            .background {
                                Rectangle()
                                    .strokeBorder(Color.black, lineWidth: 3)
                                    .padding(-3)
                                    .opacity(0.5)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
    }
    
    var dPad: some View {
        Grid {
            GridRow {
                ControlView(control: .pause) {
                    model.status = .paused
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
                        model.offset.height += 50
                    }
                }
                placeholder
            }
            GridRow {
                ControlView(control: .direction(.left)) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                        model.offset.width += 50
                    }
                }
                ControlView(control: .center) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                        model.offset = .zero
                        model.scale = 1
                    }
                }
                ControlView(control: .direction(.right)) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                        model.offset.width -= 50
                    }
                }
            }
            GridRow {
                placeholder
                ControlView(control: .direction(.down)) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 1, blendDuration: 1)) {
                        model.offset.height -= 50
                    }
                }
                placeholder
            }
        }
    }

    /// a clear view for grid spacing.
    var placeholder: some View {
        Color.clear.gridCellUnsizedAxes([.vertical, .horizontal])
    }
}
