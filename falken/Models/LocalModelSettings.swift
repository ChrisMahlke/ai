//
//  LocalModelSettings.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

nonisolated struct LocalModelSettings: Codable, Equatable, Sendable {
    var contextTokenLimit: Int
    var outputTokenLimit: Int
    var gpuLayerCount: Int
    var threadCount: Int
    var topK: Int
    var topP: Double
    var temperature: Double
    var seed: UInt32?
    var repeatPenalty: Double

    init(
        contextTokenLimit: Int,
        outputTokenLimit: Int,
        gpuLayerCount: Int,
        threadCount: Int,
        topK: Int,
        topP: Double,
        temperature: Double,
        seed: UInt32? = nil,
        repeatPenalty: Double = 1.10
    ) {
        self.contextTokenLimit = contextTokenLimit
        self.outputTokenLimit = outputTokenLimit
        self.gpuLayerCount = gpuLayerCount
        self.threadCount = threadCount
        self.topK = topK
        self.topP = topP
        self.temperature = temperature
        self.seed = seed
        self.repeatPenalty = repeatPenalty
    }

    nonisolated static let `default` = LocalModelSettings(
        contextTokenLimit: 1536,
        outputTokenLimit: 192,
        gpuLayerCount: 99,
        threadCount: 4,
        topK: 40,
        topP: 0.9,
        temperature: 0.7,
        seed: nil,
        repeatPenalty: 1.10
    )

    var clamped: LocalModelSettings {
        LocalModelSettings(
            contextTokenLimit: min(max(contextTokenLimit, 512), 4096),
            outputTokenLimit: min(max(outputTokenLimit, 64), 512),
            gpuLayerCount: min(max(gpuLayerCount, 0), 99),
            threadCount: min(max(threadCount, 2), 6),
            topK: min(max(topK, 1), 100),
            topP: min(max(topP, 0.1), 1.0),
            temperature: min(max(temperature, 0.0), 1.5),
            seed: seed,
            repeatPenalty: min(max(repeatPenalty, 1.0), 1.4)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case contextTokenLimit
        case outputTokenLimit
        case gpuLayerCount
        case threadCount
        case topK
        case topP
        case temperature
        case seed
        case repeatPenalty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contextTokenLimit = try container.decode(Int.self, forKey: .contextTokenLimit)
        outputTokenLimit = try container.decode(Int.self, forKey: .outputTokenLimit)
        gpuLayerCount = try container.decode(Int.self, forKey: .gpuLayerCount)
        threadCount = try container.decode(Int.self, forKey: .threadCount)
        topK = try container.decode(Int.self, forKey: .topK)
        topP = try container.decode(Double.self, forKey: .topP)
        temperature = try container.decode(Double.self, forKey: .temperature)
        seed = try container.decodeIfPresent(UInt32.self, forKey: .seed)
        repeatPenalty = try container.decodeIfPresent(Double.self, forKey: .repeatPenalty) ?? 1.10
    }
}
