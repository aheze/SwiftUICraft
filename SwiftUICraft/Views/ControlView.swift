//
//  ControlView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/9/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/// A singular D-Pad button.
struct ControlView: View {
    var control: Control
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("button_background")
                .interpolation(.none)
                .resizable()
                .frame(width: 60, height: 60)
                .overlay {
                    if case let .direction(direction) = control {
                        Image(control.image)
                            .interpolation(.none)
                            .resizable()
                            .rotationEffect(.degrees(direction.rotation))
                    } else {
                        Image(control.image)
                            .interpolation(.none)
                            .resizable()
                    }
                }
        }
    }
}
