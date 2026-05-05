//
//  LocalAIManager+Diagnostics.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension LocalAIManager {
    func recordGenerationMemory() {
        guard let currentMemoryBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint() else { return }

        let currentPeakBytes = runtimeTelemetry.peakGenerationMemoryBytes ?? 0
        if currentMemoryBytes > currentPeakBytes {
            runtimeTelemetry.peakGenerationMemoryBytes = currentMemoryBytes
            refreshDiagnosticsAfterTelemetryChange()
        }
    }

    func diagnosticsForUnavailableModel(_ message: String) -> LocalModelDiagnostics {
        LocalModelDiagnostics(
            modelName: activeModelProfile.title,
            fileName: resource.fileName,
            fileSizeBytes: 0,
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            appMemoryBytes: nil,
            thermalState: ProcessInfo.processInfo.thermalState,
            status: .unavailable(message),
            loadDuration: nil,
            telemetry: runtimeTelemetry,
            settingsValidation: settingsValidation,
            settingsTestResult: settingsTestResult
        )
    }

    func diagnosticsForCurrentModel(
        modelURL: URL,
        status: LocalModelDiagnostics.Status,
        loadDuration: TimeInterval?
    ) -> LocalModelDiagnostics {
        switch memoryPolicy.evaluate(modelURL: modelURL) {
        case .allowed(let snapshot), .denied(let snapshot, _):
            return diagnostics(from: snapshot, status: status, loadDuration: loadDuration)
        }
    }

    func diagnostics(
        from snapshot: LocalModelMemoryPolicy.Snapshot,
        status: LocalModelDiagnostics.Status,
        loadDuration: TimeInterval?
    ) -> LocalModelDiagnostics {
        LocalModelDiagnostics(
            modelName: activeModelProfile.title,
            fileName: resource.fileName,
            fileSizeBytes: snapshot.modelFileBytes,
            physicalMemoryBytes: snapshot.physicalMemoryBytes,
            appMemoryBytes: snapshot.appMemoryBytes,
            thermalState: snapshot.thermalState,
            status: status,
            loadDuration: loadDuration,
            telemetry: runtimeTelemetry,
            settingsValidation: settingsValidation,
            settingsTestResult: settingsTestResult
        )
    }

    func refreshDiagnosticsAfterTelemetryChange() {
        switch loadState {
        case .loaded:
            diagnostics.status = .ready
        case .idle:
            if diagnostics.status == .ready {
                diagnostics.status = .notChecked
            }
        case .loading, .unavailable, .failed:
            break
        }

        diagnostics.telemetry = runtimeTelemetry
        diagnostics.settingsValidation = settingsValidation
        diagnostics.settingsTestResult = settingsTestResult
    }
}
