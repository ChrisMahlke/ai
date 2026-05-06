//
//  AppHaptics.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import UIKit

@MainActor
enum AppHaptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func stop() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
