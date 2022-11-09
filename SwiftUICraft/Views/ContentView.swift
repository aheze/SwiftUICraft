//
//  ContentView.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/6/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import Prism
import SwiftUI

struct ContentView: View {
    @StateObject var model = ViewModel()

    var body: some View {
        Color.clear.overlay {
            if model.status == .playing {
                ControlsView(model: model)
            }
        }
        .background {
            GameView(model: model)
        }
        .overlay {
            if model.status == .paused {
                MenuView(model: model)
            }
        }
    }
}
