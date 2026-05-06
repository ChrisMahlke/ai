//
//  LocalModelSettingsImpact.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct LocalModelSettingsImpact: Equatable, Sendable {
    let estimatedMemoryBytes: UInt64
    let estimatedContextMemoryBytes: UInt64
    let contextDelta: Int
    let outputDelta: Int
    let risk: Risk

    enum Risk: String, Sendable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"

        var guidance: String {
            switch self {
            case .low:
                return "Expected to fit comfortably on this device."
            case .moderate:
                return "Watch for slower first tokens or thermal pressure."
            case .high:
                return "Use Efficient settings if loading or generation fails."
            }
        }
    }

    static func estimate(
        currentSettings: LocalModelSettings,
        draftSettings: LocalModelSettings,
        diagnostics: LocalModelDiagnostics
    ) -> LocalModelSettingsImpact {
        let current = currentSettings.clamped
        let draft = draftSettings.clamped
        let modelBytes = diagnostics.fileSizeBytes
        let contextBytes = UInt64(max(draft.contextTokenLimit, 0)) * 384 * 1024
        let outputBytes = UInt64(max(draft.outputTokenLimit, 0)) * 64 * 1024
        let gpuOverheadBytes = draft.gpuLayerCount == 0 ? 0 : modelBytes / 8
        let estimatedBytes = modelBytes + contextBytes + outputBytes + gpuOverheadBytes
        let availableMemory = diagnostics.physicalMemoryBytes
        let memoryRatio = availableMemory > 0 ? Double(estimatedBytes) / Double(availableMemory) : 0

        let risk: Risk
        if memoryRatio > 0.58 || draft.contextTokenLimit >= 2048 || draft.threadCount >= 6 {
            risk = .high
        } else if memoryRatio > 0.42 || draft.contextTokenLimit >= 1536 || draft.outputTokenLimit >= 256 {
            risk = .moderate
        } else {
            risk = .low
        }

        return LocalModelSettingsImpact(
            estimatedMemoryBytes: estimatedBytes,
            estimatedContextMemoryBytes: contextBytes,
            contextDelta: draft.contextTokenLimit - current.contextTokenLimit,
            outputDelta: draft.outputTokenLimit - current.outputTokenLimit,
            risk: risk
        )
    }
}
