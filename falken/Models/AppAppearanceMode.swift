//
//  AppAppearanceMode.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import SwiftUI

nonisolated enum AppAppearanceMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case dark
    case light

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}
