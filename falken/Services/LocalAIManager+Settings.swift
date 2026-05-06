//
//  LocalAIManager+Settings.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import LlamaBackendKit

@MainActor
extension LocalAIManager {
    func updateSettings(_ newSettings: LocalModelSettings) {
        let clampedSettings = newSettings.clamped
        guard clampedSettings != settings else { return }

        settings = clampedSettings
        settingsStore.save(clampedSettings)
        unloadModel(reason: "Reloading local model with updated settings.")
        settingsValidation = .notChecked
        settingsTestResult = .notRun

        var updatedDiagnostics = diagnostics
        updatedDiagnostics.status = .notChecked
        updatedDiagnostics.loadDuration = nil
        updatedDiagnostics.settingsValidation = settingsValidation
        updatedDiagnostics.settingsTestResult = settingsTestResult
        diagnostics = updatedDiagnostics
    }

    func installedModels() -> [InstalledLocalModel] {
        resourceValidator.installedModels()
    }

    func selectModelProfile(_ profile: LocalModelProfile) {
        guard profile != activeModelProfile else { return }

        unloadModel(reason: "Switching local model profile to \(profile.title).")
        activeModelProfile = profile
        resource = profile.resource
        modelProfileStore.save(profile)
        settingsValidation = .notChecked
        settingsTestResult = .notRun
        diagnostics = LocalModelDiagnostics(
            modelName: profile.title,
            fileName: profile.resource.fileName,
            fileSizeBytes: 0,
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            appMemoryBytes: LocalModelMemoryPolicy.currentAppMemoryFootprint(),
            thermalState: ProcessInfo.processInfo.thermalState,
            status: .notChecked,
            loadDuration: nil,
            telemetry: runtimeTelemetry,
            settingsValidation: settingsValidation,
            settingsTestResult: settingsTestResult
        )
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

    func testCurrentSettings(
        progress: @escaping @MainActor (Double, String) -> Void = { _, _ in }
    ) async {
        let startedAt = Date()
        settingsTestResult = LocalModelSettingsTestResult(
            status: .running,
            duration: nil,
            testedAt: nil
        )
        refreshDiagnosticsAfterTelemetryChange()

        await loadModelIfNeeded(progress: progress)
        guard case .loaded = loadState else {
            settingsTestResult = LocalModelSettingsTestResult(
                status: .failed("The local model is not loaded."),
                duration: Date().timeIntervalSince(startedAt),
                testedAt: Date()
            )
            refreshDiagnosticsAfterTelemetryChange()
            return
        }

        let stream = generateResponse(
            prompt: "Reply with exactly: OK",
            history: [ChatMessage(role: .user, text: "Reply with exactly: OK")]
        )
        var response = ""

        for await token in stream {
            response += token
            if response.count >= 32 {
                cancelGeneration()
                break
            }
        }

        let duration = Date().timeIntervalSince(startedAt)
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedResponse.isEmpty {
            settingsTestResult = LocalModelSettingsTestResult(
                status: .failed("The model returned an empty test response."),
                duration: duration,
                testedAt: Date()
            )
        } else {
            settingsTestResult = LocalModelSettingsTestResult(
                status: .passed(trimmedResponse),
                duration: duration,
                testedAt: Date()
            )
        }

        refreshDiagnosticsAfterTelemetryChange()
    }

    func makeInferenceOptions(from settings: LocalModelSettings) -> LlamaInferenceOptions {
        let clampedSettings = settings.clamped
        return LlamaInferenceOptions(
            contextTokenLimit: Int32(min(clampedSettings.contextTokenLimit, resource.maxSequenceLength)),
            batchTokenLimit: 512,
            outputTokenLimit: Int32(clampedSettings.outputTokenLimit),
            gpuLayerCount: Int32(clampedSettings.gpuLayerCount),
            threadCount: Int32(clampedSettings.threadCount),
            topK: Int32(clampedSettings.topK),
            topP: Float(clampedSettings.topP),
            temperature: Float(clampedSettings.temperature),
            seed: clampedSettings.seed ?? UInt32.max,
            repeatPenalty: Float(clampedSettings.repeatPenalty)
        )
    }

    func validateAppliedSettings(
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
            temperature: Double(options.temperature),
            seed: options.seed == UInt32.max ? nil : options.seed,
            repeatPenalty: Double(options.repeatPenalty)
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

    func settingsMatch(_ left: LocalModelSettings, _ right: LocalModelSettings) -> Bool {
        left.contextTokenLimit == right.contextTokenLimit
        && left.outputTokenLimit == right.outputTokenLimit
        && left.gpuLayerCount == right.gpuLayerCount
        && left.threadCount == right.threadCount
        && left.topK == right.topK
        && abs(left.topP - right.topP) < 0.001
        && abs(left.temperature - right.temperature) < 0.001
        && left.seed == right.seed
        && abs(left.repeatPenalty - right.repeatPenalty) < 0.001
    }
}
