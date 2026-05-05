//
//  LocalModelDiagnostics.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import UIKit

struct LocalModelDiagnostics: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case notChecked
        case checking
        case ready
        case unavailable(String)
        case failed(String)
    }

    var modelName: String
    var fileName: String
    var fileSizeBytes: UInt64
    var physicalMemoryBytes: UInt64
    var appMemoryBytes: UInt64?
    var thermalState: ProcessInfo.ThermalState
    var status: Status
    var loadDuration: TimeInterval?
    var telemetry: LocalModelRuntimeTelemetry
    var settingsValidation: LocalModelSettingsValidation

    nonisolated static let empty = LocalModelDiagnostics(
        modelName: "Local model",
        fileName: "Not checked",
        fileSizeBytes: 0,
        physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
        appMemoryBytes: nil,
        thermalState: ProcessInfo.processInfo.thermalState,
        status: .notChecked,
        loadDuration: nil,
        telemetry: .empty,
        settingsValidation: .notChecked
    )
}
