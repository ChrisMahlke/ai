//
//  LocalAIManager+Loading.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import LlamaBackendKit

@MainActor
extension LocalAIManager {
    func loadModelIfNeeded(
        progress: @escaping @MainActor (Double, String) -> Void = { _, _ in }
    ) async {
        if case .loaded = loadState {
            return
        }

        updateLoading(0.05, "Preparing local model", progress)
        await briefYield()

        updateLoading(0.18, "Checking bundled model", progress)
        let modelURL: URL
        switch resourceValidator.validate(resource: resource) {
        case .valid(let validURL, _):
            modelURL = validURL
        case .invalid(let message):
            loadState = .unavailable(message)
            diagnostics = diagnosticsForUnavailableModel(message)
            progress(1.0, message)
            return
        }

        switch memoryPolicy.evaluate(modelURL: modelURL) {
        case .allowed(let snapshot):
            diagnostics = diagnostics(from: snapshot, status: .checking, loadDuration: nil)
        case .denied(let snapshot, let reason):
            loadState = .unavailable(reason)
            diagnostics = diagnostics(from: snapshot, status: .unavailable(reason), loadDuration: nil)
            progress(1.0, reason)
            return
        }

        updateLoading(0.42, "Loading \(activeModelProfile.title)", progress)

        do {
            let startedAt = Date()
            runtimeTelemetry.loadStartedAt = startedAt
            runtimeTelemetry.appMemoryBeforeLoadBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint()
            settingsValidation = LocalModelSettingsValidation(
                status: .checking,
                requestedSettings: settings.clamped,
                appliedSettings: nil,
                validatedAt: nil
            )
            diagnostics = diagnosticsForCurrentModel(modelURL: modelURL, status: .checking, loadDuration: nil)

            let options = makeInferenceOptions(from: settings.clamped)
            let validation = validateAppliedSettings(requestedSettings: settings.clamped, options: options)
            settingsValidation = validation
            diagnostics = diagnosticsForCurrentModel(modelURL: modelURL, status: .checking, loadDuration: nil)

            if case .invalid(let message) = validation.status {
                loadState = .failed(message)
                diagnostics = diagnosticsForCurrentModel(modelURL: modelURL, status: .failed(message), loadDuration: nil)
                progress(1.0, "Local model settings are invalid")
                return
            }

            try await engine.load(modelPath: modelURL.path, options: options) { progressValue, message in
                Task { @MainActor in
                    progress(progressValue, message)
                }
            }

            loadState = .loaded
            runtimeTelemetry.appMemoryAfterLoadBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint()
            runtimeTelemetry.lastLoadedAt = Date()
            diagnostics = diagnosticsForCurrentModel(
                modelURL: modelURL,
                status: .ready,
                loadDuration: Date().timeIntervalSince(startedAt)
            )
            progress(1.0, "Local model ready")
        } catch {
            loadState = .failed(error.localizedDescription)
            runtimeTelemetry.appMemoryAfterLoadBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint()
            diagnostics = diagnosticsForCurrentModel(
                modelURL: modelURL,
                status: .failed(error.localizedDescription),
                loadDuration: nil
            )
            progress(1.0, "Local model failed to load")
        }
    }

    func unloadModel(reason: String? = nil) {
        engine.cancelGeneration()
        let engine = engine
        runtimeTelemetry.lastUnloadReason = reason
        Task { [weak self] in
            await engine.unloadAsync()
            await MainActor.run {
                guard let self else { return }

                self.runtimeTelemetry.appMemoryAfterUnloadBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint()
                self.loadState = .idle
                self.refreshDiagnosticsAfterTelemetryChange()
            }
        }
        loadState = .idle
        refreshDiagnosticsAfterTelemetryChange()
    }

    func updateLoading(
        _ progressValue: Double,
        _ message: String,
        _ progress: @escaping @MainActor (Double, String) -> Void
    ) {
        loadState = .loading(progress: progressValue, message: message)
        progress(progressValue, message)
    }

    func briefYield() async {
        try? await Task.sleep(for: .milliseconds(120))
    }
}
