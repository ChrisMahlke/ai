//
//  GenerationMetrics.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct GenerationMetrics: Equatable, Sendable {
    static let empty = GenerationMetrics(
        tokenChunks: 0,
        elapsedSeconds: 0,
        firstTokenLatency: nil,
        promptEstimatedTokens: 0,
        outputEstimatedTokens: 0
    )

    let tokenChunks: Int
    let elapsedSeconds: TimeInterval
    let firstTokenLatency: TimeInterval?
    let promptEstimatedTokens: Int
    let outputEstimatedTokens: Int

    var chunksPerSecond: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return Double(tokenChunks) / elapsedSeconds
    }

    var hasValue: Bool {
        tokenChunks > 0
    }

    var tokensPerSecond: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return Double(outputEstimatedTokens) / elapsedSeconds
    }

    func starting(prompt: String) -> GenerationMetrics {
        GenerationMetrics(
            tokenChunks: 0,
            elapsedSeconds: 0,
            firstTokenLatency: nil,
            promptEstimatedTokens: Self.estimateTokens(in: prompt),
            outputEstimatedTokens: 0
        )
    }

    func addingChunk(_ chunk: String, elapsedSeconds: TimeInterval) -> GenerationMetrics {
        let estimatedOutputTokens = outputEstimatedTokens + Self.estimateTokens(in: chunk)
        return GenerationMetrics(
            tokenChunks: tokenChunks + 1,
            elapsedSeconds: max(elapsedSeconds, 0),
            firstTokenLatency: firstTokenLatency ?? max(elapsedSeconds, 0),
            promptEstimatedTokens: promptEstimatedTokens,
            outputEstimatedTokens: max(estimatedOutputTokens, tokenChunks + 1)
        )
    }

    static func estimateTokens(in text: String) -> Int {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return 0 }

        return max(1, Int((Double(trimmedText.count) / 4.0).rounded(.up)))
    }
}
