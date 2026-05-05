//
//  LocalModelSettings.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelSettings: Codable, Equatable, Sendable {
    var contextTokenLimit: Int
    var outputTokenLimit: Int
    var gpuLayerCount: Int
    var threadCount: Int
    var topK: Int
    var topP: Double
    var temperature: Double

    nonisolated static let `default` = LocalModelSettings(
        contextTokenLimit: 1536,
        outputTokenLimit: 192,
        gpuLayerCount: 99,
        threadCount: 4,
        topK: 40,
        topP: 0.9,
        temperature: 0.7
    )

    var clamped: LocalModelSettings {
        LocalModelSettings(
            contextTokenLimit: min(max(contextTokenLimit, 512), 2048),
            outputTokenLimit: min(max(outputTokenLimit, 64), 512),
            gpuLayerCount: min(max(gpuLayerCount, 0), 99),
            threadCount: min(max(threadCount, 2), 6),
            topK: min(max(topK, 1), 100),
            topP: min(max(topP, 0.1), 1.0),
            temperature: min(max(temperature, 0.0), 1.5)
        )
    }
}
