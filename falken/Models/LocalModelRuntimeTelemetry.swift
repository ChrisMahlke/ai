//
//  LocalModelRuntimeTelemetry.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

nonisolated struct LocalModelRuntimeTelemetry: Codable, Equatable, Sendable {
    var appMemoryBeforeLoadBytes: UInt64?
    var appMemoryAfterLoadBytes: UInt64?
    var peakGenerationMemoryBytes: UInt64?
    var appMemoryAfterUnloadBytes: UInt64?
    var lastUnloadReason: String?
    var loadStartedAt: Date?
    var lastLoadedAt: Date?
    var loadDurationSamples: [TimeInterval] = []
    var firstTokenLatencySamples: [TimeInterval] = []
    var tokensPerSecondSamples: [Double] = []
    var generationCount = 0
    var failureCount = 0

    nonisolated static let empty = LocalModelRuntimeTelemetry()

    var hasValues: Bool {
        appMemoryBeforeLoadBytes != nil
        || appMemoryAfterLoadBytes != nil
        || peakGenerationMemoryBytes != nil
        || appMemoryAfterUnloadBytes != nil
        || lastUnloadReason != nil
        || !loadDurationSamples.isEmpty
        || !firstTokenLatencySamples.isEmpty
        || !tokensPerSecondSamples.isEmpty
        || generationCount > 0
        || failureCount > 0
    }

    var averageLoadDuration: TimeInterval? {
        average(loadDurationSamples)
    }

    var averageFirstTokenLatency: TimeInterval? {
        average(firstTokenLatencySamples)
    }

    var averageTokensPerSecond: Double? {
        average(tokensPerSecondSamples)
    }

    var failureRate: Double {
        guard generationCount > 0 else { return 0 }
        return Double(failureCount) / Double(generationCount)
    }

    mutating func recordLoad(duration: TimeInterval) {
        append(duration, to: \.loadDurationSamples)
    }

    mutating func recordGeneration(metrics: GenerationMetrics, didFail: Bool) {
        generationCount += 1
        if didFail {
            failureCount += 1
        }

        if let firstTokenLatency = metrics.firstTokenLatency {
            append(firstTokenLatency, to: \.firstTokenLatencySamples)
        }

        if metrics.tokensPerSecond > 0 {
            append(metrics.tokensPerSecond, to: \.tokensPerSecondSamples)
        }
    }

    private mutating func append(_ value: Double, to keyPath: WritableKeyPath<LocalModelRuntimeTelemetry, [Double]>) {
        self[keyPath: keyPath].append(value)
        if self[keyPath: keyPath].count > 24 {
            self[keyPath: keyPath].removeFirst(self[keyPath: keyPath].count - 24)
        }
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
