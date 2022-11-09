//
//  ItemView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Prism
import SwiftUI

/// Displays a hotbar item.
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
