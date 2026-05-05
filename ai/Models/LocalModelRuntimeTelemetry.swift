//
//  LocalModelRuntimeTelemetry.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelRuntimeTelemetry: Equatable, Sendable {
    var appMemoryBeforeLoadBytes: UInt64?
    var appMemoryAfterLoadBytes: UInt64?
    var peakGenerationMemoryBytes: UInt64?
    var appMemoryAfterUnloadBytes: UInt64?
    var lastUnloadReason: String?
    var loadStartedAt: Date?
    var lastLoadedAt: Date?

    nonisolated static let empty = LocalModelRuntimeTelemetry()

    var hasValues: Bool {
        appMemoryBeforeLoadBytes != nil
        || appMemoryAfterLoadBytes != nil
        || peakGenerationMemoryBytes != nil
        || appMemoryAfterUnloadBytes != nil
        || lastUnloadReason != nil
    }
}
