//
//  LocalModelRecommendation.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct LocalModelRecommendation: Equatable, Sendable {
    let preset: LocalModelPreset
    let reason: String

    static func current(
        physicalMemoryBytes: UInt64 = ProcessInfo.processInfo.physicalMemory,
        thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    ) -> LocalModelRecommendation {
        if thermalState == .serious || thermalState == .critical {
            return LocalModelRecommendation(
                preset: .efficient,
                reason: "Recommended while the device is hot."
            )
        }

        let capability = DeviceCapabilityProfile.current(physicalMemoryBytes: physicalMemoryBytes)

        return LocalModelRecommendation(
            preset: capability.recommendedPreset,
            reason: "Recommended for \(capability.tier.rawValue)."
        )
    }
}
