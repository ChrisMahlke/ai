//
//  ContentView.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: viewModel)
    }
}
