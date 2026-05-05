//
//  LocalAIManager.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import Foundation
import LlamaBackendKit
import UIKit

@MainActor
final class LocalAIManager: ObservableObject {
    static let shared = LocalAIManager()

    enum LoadState: Equatable {
        case idle
        case loading(progress: Double, message: String)
        case loaded
        case unavailable(String)
        case failed(String)
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var settings: LocalModelSettings
    @Published private(set) var diagnostics = LocalModelDiagnostics.empty

    private let resource: LocalModelResource
    private let configuration: InferenceConfiguration
    private let engine = LlamaLocalEngine()
    private let memoryPolicy = LocalModelMemoryPolicy()
    private let resourceValidator = LocalModelResourceValidator()
    private let settingsStore: LocalModelSettingsStore
    private var runtimeTelemetry = LocalModelRuntimeTelemetry.empty
    private var settingsValidation = LocalModelSettingsValidation.notChecked
    private var notificationObservers: [NSObjectProtocol] = []

    init(
        resource: LocalModelResource = .gemma3OneBInt4,
        configuration: InferenceConfiguration = .default,
        settingsStore: LocalModelSettingsStore? = nil
    ) {
        self.resource = resource
        self.configuration = configuration
        let resolvedSettingsStore = settingsStore ?? LocalModelSettingsStore()
        self.settingsStore = resolvedSettingsStore
        self.settings = resolvedSettingsStore.load()

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model after system memory warning.")
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model while the app is in the background.")
            }
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.unloadModel(reason: "Unloaded local model before app termination.")
            }
        })
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

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

        updateLoading(0.42, "Loading \(configuration.localModelIdentifier)", progress)

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

    func updateSettings(_ newSettings: LocalModelSettings) {
        let clampedSettings = newSettings.clamped
        guard clampedSettings != settings else { return }

        settings = clampedSettings
        settingsStore.save(clampedSettings)
        unloadModel(reason: "Reloading local model with updated settings.")
        settingsValidation = .notChecked

        var updatedDiagnostics = diagnostics
        updatedDiagnostics.status = .notChecked
        updatedDiagnostics.loadDuration = nil
        updatedDiagnostics.settingsValidation = settingsValidation
        diagnostics = updatedDiagnostics
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

    func cancelGeneration() {
        engine.cancelGeneration()
    }

    func validateSettingsAndReload(
        progress: @escaping @MainActor (Double, String) -> Void = { _, _ in }
    ) async {
        engine.cancelGeneration()
        runtimeTelemetry.lastUnloadReason = "Reloading local model to validate settings."
        await engine.unloadAsync()
        runtimeTelemetry.appMemoryAfterUnloadBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint()
        loadState = .idle
        refreshDiagnosticsAfterTelemetryChange()
        await loadModelIfNeeded(progress: progress)
    }

    func generateResponse(prompt: String, history: [ChatMessage]) -> AsyncStream<String> {
        guard case .loaded = loadState else {
            return singleMessageStream("The local model is not loaded yet.")
        }

        let engine = engine
        let messages = chatTurns(prompt: prompt, history: history)

        return AsyncStream { continuation in
            let generationTask = Task {
                do {
                    try await engine.generateChat(messages: messages) { token in
                        continuation.yield(token)
                        Task { @MainActor [weak self] in
                            self?.recordGenerationMemory()
                        }
                    }
                    continuation.finish()
                } catch LlamaBackendError.cancelled {
                    continuation.finish()
                } catch {
                    continuation.yield(error.localizedDescription)
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                generationTask.cancel()
                engine.cancelGeneration()
            }
        }
    }

    private func makeInferenceOptions(from settings: LocalModelSettings) -> LlamaInferenceOptions {
        let clampedSettings = settings.clamped
        return LlamaInferenceOptions(
            contextTokenLimit: Int32(min(clampedSettings.contextTokenLimit, resource.maxSequenceLength)),
            batchTokenLimit: 512,
            outputTokenLimit: Int32(clampedSettings.outputTokenLimit),
            gpuLayerCount: Int32(clampedSettings.gpuLayerCount),
            threadCount: Int32(clampedSettings.threadCount),
            topK: Int32(clampedSettings.topK),
            topP: Float(clampedSettings.topP),
            temperature: Float(clampedSettings.temperature)
        )
    }

    private func validateAppliedSettings(
        requestedSettings: LocalModelSettings,
        options: LlamaInferenceOptions
    ) -> LocalModelSettingsValidation {
        let appliedSettings = LocalModelSettings(
            contextTokenLimit: Int(options.contextTokenLimit),
            outputTokenLimit: Int(options.outputTokenLimit),
            gpuLayerCount: Int(options.gpuLayerCount),
            threadCount: Int(options.threadCount),
            topK: Int(options.topK),
            topP: Double(options.topP),
            temperature: Double(options.temperature)
        ).clamped
        let expectedSettings = requestedSettings.clamped

        guard settingsMatch(appliedSettings, expectedSettings) else {
            return LocalModelSettingsValidation(
                status: .invalid("Saved settings do not match the backend options that would be applied."),
                requestedSettings: expectedSettings,
                appliedSettings: appliedSettings,
                validatedAt: Date()
            )
        }

        return LocalModelSettingsValidation(
            status: .valid,
            requestedSettings: expectedSettings,
            appliedSettings: appliedSettings,
            validatedAt: Date()
        )
    }

    private func settingsMatch(_ left: LocalModelSettings, _ right: LocalModelSettings) -> Bool {
        left.contextTokenLimit == right.contextTokenLimit
        && left.outputTokenLimit == right.outputTokenLimit
        && left.gpuLayerCount == right.gpuLayerCount
        && left.threadCount == right.threadCount
        && left.topK == right.topK
        && abs(left.topP - right.topP) < 0.001
        && abs(left.temperature - right.temperature) < 0.001
    }

    private func recordGenerationMemory() {
        guard let currentMemoryBytes = LocalModelMemoryPolicy.currentAppMemoryFootprint() else { return }

        let currentPeakBytes = runtimeTelemetry.peakGenerationMemoryBytes ?? 0
        if currentMemoryBytes > currentPeakBytes {
            runtimeTelemetry.peakGenerationMemoryBytes = currentMemoryBytes
            refreshDiagnosticsAfterTelemetryChange()
        }
    }

    private func updateLoading(
        _ progressValue: Double,
        _ message: String,
        _ progress: @escaping @MainActor (Double, String) -> Void
    ) {
        loadState = .loading(progress: progressValue, message: message)
        progress(progressValue, message)
    }

    private func briefYield() async {
        try? await Task.sleep(for: .milliseconds(120))
    }

    private func singleMessageStream(_ message: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield(message)
            continuation.finish()
        }
    }

    private func chatTurns(prompt: String, history: [ChatMessage]) -> [LlamaChatTurn] {
        let conversationalHistory = history.isEmpty ? [ChatMessage(role: .user, text: prompt)] : history
        var turns = [
            LlamaChatTurn(
                role: "system",
                content: "You are a concise, helpful assistant running locally on this device."
            )
        ]

        for message in conversationalHistory {
            switch message.role {
            case .user:
                turns.append(LlamaChatTurn(role: "user", content: message.text))
            case .assistant:
                turns.append(LlamaChatTurn(role: "assistant", content: message.text))
            }
        }

        return turns
    }

    private func diagnosticsForUnavailableModel(_ message: String) -> LocalModelDiagnostics {
        LocalModelDiagnostics(
            modelName: configuration.localModelIdentifier,
            fileName: resource.fileName,
            fileSizeBytes: 0,
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            appMemoryBytes: nil,
            thermalState: ProcessInfo.processInfo.thermalState,
            status: .unavailable(message),
            loadDuration: nil,
            telemetry: runtimeTelemetry,
            settingsValidation: settingsValidation
        )
    }

    private func diagnosticsForCurrentModel(
        modelURL: URL,
        status: LocalModelDiagnostics.Status,
        loadDuration: TimeInterval?
    ) -> LocalModelDiagnostics {
        switch memoryPolicy.evaluate(modelURL: modelURL) {
        case .allowed(let snapshot), .denied(let snapshot, _):
            return diagnostics(from: snapshot, status: status, loadDuration: loadDuration)
        }
    }

    private func diagnostics(
        from snapshot: LocalModelMemoryPolicy.Snapshot,
        status: LocalModelDiagnostics.Status,
        loadDuration: TimeInterval?
    ) -> LocalModelDiagnostics {
        LocalModelDiagnostics(
            modelName: configuration.localModelIdentifier,
            fileName: resource.fileName,
            fileSizeBytes: snapshot.modelFileBytes,
            physicalMemoryBytes: snapshot.physicalMemoryBytes,
            appMemoryBytes: snapshot.appMemoryBytes,
            thermalState: snapshot.thermalState,
            status: status,
            loadDuration: loadDuration,
            telemetry: runtimeTelemetry,
            settingsValidation: settingsValidation
        )
    }

    private func refreshDiagnosticsAfterTelemetryChange() {
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
    }
}
