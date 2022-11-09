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
            ControlsView(model: model)
                .opacity(model.gameActive ? 1 : 0)
        }
        .background {
            GameView(model: model)
        }
        .overlay {
            if !model.gameActive {
                MenuView(model: model)
            }
        }
    }
}
