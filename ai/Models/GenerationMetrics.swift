//
//  GenerationMetrics.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct GenerationMetrics: Equatable, Sendable {
    static let empty = GenerationMetrics(tokenChunks: 0, elapsedSeconds: 0)

    let tokenChunks: Int
    let elapsedSeconds: TimeInterval

    var chunksPerSecond: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return Double(tokenChunks) / elapsedSeconds
    }

    var hasValue: Bool {
        tokenChunks > 0
    }

    func addingChunk(elapsedSeconds: TimeInterval) -> GenerationMetrics {
        GenerationMetrics(
            tokenChunks: tokenChunks + 1,
            elapsedSeconds: max(elapsedSeconds, 0)
        )
    }
}
