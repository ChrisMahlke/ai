//
//  LocalModelAdvancedPreset.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

enum TemperaturePreset: String, CaseIterable, Identifiable, Sendable {
    case precise = "Precise"
    case balanced = "Balanced"
    case creative = "Creative"

    var id: String { rawValue }

    var value: Double {
        switch self {
        case .precise:
            return 0.35
        case .balanced:
            return 0.70
        case .creative:
            return 1.05
        }
    }
}

enum ContextWindowPreset: String, CaseIterable, Identifiable, Sendable {
    case compact = "Compact"
    case standard = "Standard"
    case long = "Long"

    var id: String { rawValue }

    var tokens: Int {
        switch self {
        case .compact:
            return 1024
        case .standard:
            return 2048
        case .long:
            return 4096
        }
    }
}
