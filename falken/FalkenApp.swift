//
//  FalkenApp.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

@main
struct FalkenApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let cleanupService = BackgroundCleanupService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    cleanupService.run()
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background else { return }

                    cleanupService.run()
                }
        }
    }
}
