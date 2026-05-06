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

        if physicalMemoryBytes <= 4_500_000_000 {
            return LocalModelRecommendation(
                preset: .efficient,
                reason: "Recommended for 4 GB memory devices."
            )
        }

        if physicalMemoryBytes >= 7_000_000_000, thermalState == .nominal {
            return LocalModelRecommendation(
                preset: .expanded,
                reason: "Recommended when memory and thermal headroom are strong."
            )
        }

        return LocalModelRecommendation(
            preset: .balanced,
            reason: "Recommended for general use on this device."
        )
    }
}
