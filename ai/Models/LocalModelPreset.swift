//
//  LocalModelPreset.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

enum LocalModelPreset: String, CaseIterable, Identifiable, Sendable {
    case efficient = "Efficient"
    case balanced = "Balanced"
    case expanded = "Expanded"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .efficient:
            return "Lowest memory footprint for older iPhones."
        case .balanced:
            return "Recommended default for iPhone 11 Pro."
        case .expanded:
            return "Longer replies and context when memory allows."
        }
    }

    var settings: LocalModelSettings {
        switch self {
        case .efficient:
            return LocalModelSettings(
                contextTokenLimit: 1024,
                outputTokenLimit: 128,
                gpuLayerCount: 99,
                threadCount: 3,
                topK: 35,
                topP: 0.88,
                temperature: 0.65
            )
        case .balanced:
            return .default
        case .expanded:
            return LocalModelSettings(
                contextTokenLimit: 2048,
                outputTokenLimit: 256,
                gpuLayerCount: 99,
                threadCount: 4,
                topK: 45,
                topP: 0.9,
                temperature: 0.72
            )
        }
    }

    static func exactMatch(for settings: LocalModelSettings) -> LocalModelPreset? {
        let clampedSettings = settings.clamped
        return allCases.first { $0.settings.clamped == clampedSettings }
    }
}
