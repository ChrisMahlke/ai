//
//  DeviceCapabilityProfile.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation
import UIKit

struct DeviceCapabilityProfile: Equatable, Sendable {
    enum Tier: String, Sendable {
        case iPhone11Pro = "iPhone 11 Pro"
        case newerIPhone = "Newer iPhone"
        case iPadStandard = "iPad standard memory"
        case iPadHighMemory = "iPad high memory"
    }

    let tier: Tier
    let physicalMemoryBytes: UInt64
    let recommendedModelProfile: LocalModelProfile
    let recommendedPreset: LocalModelPreset
    let contextCeiling: Int

    static func current(
        physicalMemoryBytes: UInt64 = ProcessInfo.processInfo.physicalMemory,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> DeviceCapabilityProfile {
        let isPad = userInterfaceIdiom == .pad

        if isPad, physicalMemoryBytes >= 7_000_000_000 {
            return DeviceCapabilityProfile(
                tier: .iPadHighMemory,
                physicalMemoryBytes: physicalMemoryBytes,
                recommendedModelProfile: .betterQuality,
                recommendedPreset: .expanded,
                contextCeiling: 4096
            )
        }

        if isPad {
            return DeviceCapabilityProfile(
                tier: .iPadStandard,
                physicalMemoryBytes: physicalMemoryBytes,
                recommendedModelProfile: .smallFast,
                recommendedPreset: .balanced,
                contextCeiling: 2048
            )
        }

        if physicalMemoryBytes <= 4_500_000_000 {
            return DeviceCapabilityProfile(
                tier: .iPhone11Pro,
                physicalMemoryBytes: physicalMemoryBytes,
                recommendedModelProfile: .smallFast,
                recommendedPreset: .efficient,
                contextCeiling: 1536
            )
        }

        return DeviceCapabilityProfile(
            tier: .newerIPhone,
            physicalMemoryBytes: physicalMemoryBytes,
            recommendedModelProfile: physicalMemoryBytes >= 7_000_000_000 ? .betterQuality : .smallFast,
            recommendedPreset: physicalMemoryBytes >= 7_000_000_000 ? .expanded : .balanced,
            contextCeiling: physicalMemoryBytes >= 7_000_000_000 ? 4096 : 2048
        )
    }
}
