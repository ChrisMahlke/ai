//
//  LocalModelProfile.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum LocalModelProfile: String, CaseIterable, Codable, Identifiable, Sendable {
    case smallFast
    case betterQuality

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .smallFast:
            return "Small / Fast"
        case .betterQuality:
            return "Better Quality"
        }
    }

    var subtitle: String {
        switch self {
        case .smallFast:
            return "1B quantized model, recommended for iPhone 11 Pro."
        case .betterQuality:
            return "Larger 4B quantized model for devices with more memory."
        }
    }

    var installationNote: String {
        switch self {
        case .smallFast:
            return "Install google_gemma-3-1b-it-Q4_K_M.gguf in falken/Models and include it in the app target."
        case .betterQuality:
            return "Install google_gemma-3-4b-it-Q4_K_M.gguf in falken/Models and include it in the app target. Use on higher-memory devices only."
        }
    }

    var resource: LocalModelResource {
        switch self {
        case .smallFast:
            return .gemma3OneBInt4
        case .betterQuality:
            return .gemma3FourBInt4
        }
    }
}
