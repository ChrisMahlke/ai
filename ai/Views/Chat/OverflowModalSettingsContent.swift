//
//  OverflowModalSettingsContent.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct LocalModelSettingsContent: View {
    let currentSettings: LocalModelSettings
    @Binding var draftSettings: LocalModelSettings
    let diagnostics: LocalModelDiagnostics
    let selectedProvider: ChatProvider
    let providerStatus: ProviderStatus
    let appearanceMode: AppAppearanceMode
    let save: (LocalModelSettings) -> Void
    let selectProvider: (ChatProvider) -> Void
    let updateAppearanceMode: (AppAppearanceMode) -> Void
    let validate: () -> Void
    let test: () -> Void
    let clearChatHistory: () -> Void

    private var hasChanges: Bool {
        draftSettings.clamped != currentSettings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            providerPanel
            appearancePanel
            presetPanel
            diagnosticsPanel
            generationPanel
            samplingPanel
            performancePanel
            actions
            dataPanel
        }
    }

    private var appearancePanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Appearance")

                HStack(spacing: 8) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Button {
                            updateAppearanceMode(mode)
                        } label: {
                            Text(mode.title)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(mode == appearanceMode ? Color.white.opacity(0.16) : Color.white.opacity(0.055))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(mode.title) appearance")
                    }
                }

                Text("Light mode is intentionally restrained; high-contrast message bubbles and the local-model workflow stay unchanged.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var providerPanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Provider")

                    Spacer()

                    ProviderHealthBadge(status: providerStatus)
                }

                HStack(spacing: 10) {
                    ForEach(ChatProvider.allCases) { provider in
                        ProviderButton(
                            provider: provider,
                            isSelected: provider == selectedProvider,
                            select: {
                                selectProvider(provider)
                            }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(providerStatus.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))

                    Text(providerStatus.detail)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var presetPanel: some View {
        let recommendation = LocalModelRecommendation.current(
            physicalMemoryBytes: diagnostics.physicalMemoryBytes,
            thermalState: diagnostics.thermalState
        )

        return ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionTitle("Preset")

                    Spacer()

                    Text(LocalModelPreset.exactMatch(for: draftSettings) == nil ? "Custom" : "Preset")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.44))
                        .padding(.horizontal, 9)
                        .frame(height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                        )
                }

                VStack(spacing: 8) {
                    ForEach(LocalModelPreset.allCases) { preset in
                        PresetButton(
                            preset: preset,
                            isSelected: LocalModelPreset.exactMatch(for: draftSettings) == preset,
                            isRecommended: recommendation.preset == preset,
                            select: {
                                draftSettings = preset.settings
                            }
                        )
                    }
                }

                Text(settingsSummary)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    draftSettings = recommendation.preset.settings
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 12, weight: .semibold))

                        Text("Use \(recommendation.preset.rawValue)")
                            .font(.system(size: 13, weight: .semibold))

                        Spacer(minLength: 8)

                        Text(recommendation.reason)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.44))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var settingsSummary: String {
        let settings = draftSettings.clamped
        let gpuLayers = settings.gpuLayerCount == 99 ? "Auto GPU" : "\(settings.gpuLayerCount) GPU layers"
        return "\(settings.contextTokenLimit) context · \(settings.outputTokenLimit) output · \(settings.threadCount) threads · \(gpuLayers)"
    }

    private var diagnosticsPanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Model diagnostics")

                VStack(spacing: 10) {
                    DiagnosticRow(label: "Model", value: diagnostics.modelName)
                    DiagnosticRow(label: "File", value: diagnostics.fileName)
                    DiagnosticRow(label: "Size", value: byteString(diagnostics.fileSizeBytes))
                    DiagnosticRow(label: "Status", value: statusText)
                    DiagnosticRow(label: "Settings", value: settingsValidationText)
                    DiagnosticRow(label: "Test", value: settingsTestText)
                    DiagnosticRow(label: "Device memory", value: byteString(diagnostics.physicalMemoryBytes))

                    if let appMemoryBytes = diagnostics.appMemoryBytes {
                        DiagnosticRow(label: "App memory", value: byteString(appMemoryBytes))
                    }

                    DiagnosticRow(label: "Thermal", value: thermalText(diagnostics.thermalState))

                    if let loadDuration = diagnostics.loadDuration {
                        DiagnosticRow(label: "Load time", value: String(format: "%.1fs", loadDuration))
                    }

                    if diagnostics.telemetry.hasValues {
                        telemetryRows
                    }
                }

                HStack(spacing: 10) {
                    Button(action: validate) {
                        Text("Validate")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: test) {
                        Text("Test")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var telemetryRows: some View {
        if let memoryBeforeLoad = diagnostics.telemetry.appMemoryBeforeLoadBytes {
            DiagnosticRow(label: "Before load", value: byteString(memoryBeforeLoad))
        }

        if let memoryAfterLoad = diagnostics.telemetry.appMemoryAfterLoadBytes {
            DiagnosticRow(label: "After load", value: byteString(memoryAfterLoad))
        }

        if let peakGenerationMemory = diagnostics.telemetry.peakGenerationMemoryBytes {
            DiagnosticRow(label: "Peak gen", value: byteString(peakGenerationMemory))
        }

        if let memoryAfterUnload = diagnostics.telemetry.appMemoryAfterUnloadBytes {
            DiagnosticRow(label: "After unload", value: byteString(memoryAfterUnload))
        }

        if let lastUnloadReason = diagnostics.telemetry.lastUnloadReason {
            DiagnosticRow(label: "Last unload", value: lastUnloadReason)
        }
    }

    private var generationPanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Generation")

                IntegerSettingRow(
                    title: "Context",
                    valueText: "\(draftSettings.contextTokenLimit) tokens",
                    note: "Conversation memory kept for each reply.",
                    value: $draftSettings.contextTokenLimit,
                    range: 512...2048,
                    step: 128
                )

                IntegerSettingRow(
                    title: "Response",
                    valueText: "\(draftSettings.outputTokenLimit) tokens",
                    note: "Maximum length of the next assistant message.",
                    value: $draftSettings.outputTokenLimit,
                    range: 64...512,
                    step: 32
                )
            }
        }
    }

    private var samplingPanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Sampling")

                DecimalSettingSlider(
                    title: "Temperature",
                    valueText: String(format: "%.2f", draftSettings.temperature),
                    note: "Lower is steadier. Higher is more varied.",
                    value: Binding(
                        get: { draftSettings.temperature },
                        set: { draftSettings.temperature = $0 }
                    ),
                    range: 0.0...1.5,
                    step: 0.05
                )

                DecimalSettingSlider(
                    title: "Top P",
                    valueText: String(format: "%.2f", draftSettings.topP),
                    note: "Limits sampling to the most likely token mass.",
                    value: Binding(
                        get: { draftSettings.topP },
                        set: { draftSettings.topP = $0 }
                    ),
                    range: 0.1...1.0,
                    step: 0.05
                )

                IntegerSettingRow(
                    title: "Top K",
                    valueText: "\(draftSettings.topK)",
                    note: "Limits each step to the strongest candidates.",
                    value: $draftSettings.topK,
                    range: 1...100,
                    step: 1
                )
            }
        }
    }

    private var performancePanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Performance")

                IntegerSettingRow(
                    title: "GPU layers",
                    valueText: draftSettings.gpuLayerCount == 99 ? "Auto" : "\(draftSettings.gpuLayerCount)",
                    note: "More layers can be faster but use more memory.",
                    value: $draftSettings.gpuLayerCount,
                    range: 0...99,
                    step: 1
                )

                IntegerSettingRow(
                    title: "Threads",
                    valueText: "\(draftSettings.threadCount)",
                    note: "Keep this modest on iPhone to reduce heat.",
                    value: $draftSettings.threadCount,
                    range: 2...6,
                    step: 1
                )
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                draftSettings = .default
            } label: {
                Text("Reset")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                let clamped = draftSettings.clamped
                draftSettings = clamped
                save(clamped)
            } label: {
                Text(hasChanges ? "Save" : "Saved")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(hasChanges ? Color.white : Color.white.opacity(0.14))
                    .foregroundStyle(hasChanges ? Color.black : Color.white.opacity(0.52))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)
        }
        .padding(.top, 2)
    }

    private var dataPanel: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle("Data")

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chat history")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Remove the saved current chat and recent chat list from this device.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Button(role: .destructive, action: clearChatHistory) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red.opacity(0.9))
                            .frame(width: 76, height: 38)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusText: String {
        switch diagnostics.status {
        case .notChecked:
            return "Not checked"
        case .checking:
            return "Checking"
        case .ready:
            return "Ready"
        case .unavailable(let message):
            return "Unavailable: \(message)"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }

    private var settingsValidationText: String {
        switch diagnostics.settingsValidation.status {
        case .notChecked:
            return "Not checked"
        case .checking:
            return "Checking"
        case .valid:
            return "Saved settings match backend options"
        case .invalid(let message):
            return message
        }
    }

    private var settingsTestText: String {
        switch diagnostics.settingsTestResult.status {
        case .notRun:
            return "Not run"
        case .running:
            return "Running"
        case .passed(let response):
            if let duration = diagnostics.settingsTestResult.duration {
                return String(format: "Passed in %.1fs: %@", duration, response)
            }

            return "Passed: \(response)"
        case .failed(let message):
            return message
        }
    }

    private func byteString(_ bytes: UInt64) -> String {
        guard bytes > 0 else { return "Unknown" }

        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    private func thermalText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
}
