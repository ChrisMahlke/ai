//
//  OverflowMenuItem.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum OverflowMenuItem: String, CaseIterable, Identifiable, Sendable {
    case rename = "Rename"
    case archive = "Archive"
    case models = "Models"
    case diagnostics = "Diagnostics"
    case settings = "Settings"
    case help = "Help"

    var id: String {
        rawValue
    }

    var title: String {
        rawValue
    }

    var description: String {
        switch self {
        case .rename:
            "Rename this chat or update its display title."
        case .archive:
            "Move this chat out of the main conversation list."
        case .models:
            "Manage installed local models and choose the active on-device profile."
        case .diagnostics:
            "Copy anonymized app and model diagnostics for troubleshooting."
        case .settings:
            "Configure local model defaults, Gemini access, and app behavior."
        case .help:
            "Find guidance, troubleshooting, and app information."
        }
    }
}
