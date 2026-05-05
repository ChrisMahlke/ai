//
//  OverflowModalView.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import SwiftUI

struct OverflowModalView: View {
    let item: OverflowMenuItem
    let currentChatTitle: String
    let hasArchivableChat: Bool
    let modelSettings: LocalModelSettings
    let modelDiagnostics: LocalModelDiagnostics
    let close: () -> Void
    let renameChat: (String) -> Void
    let archiveChat: () -> Void
    let saveModelSettings: (LocalModelSettings) -> Void
    let validateModelSettings: () -> Void
    let clearChatHistory: () -> Void

    @State private var draftSettings: LocalModelSettings
    @State private var draftTitle: String
    @State private var isConfirmingHistoryClear = false

    init(
        item: OverflowMenuItem,
        currentChatTitle: String,
        hasArchivableChat: Bool,
        modelSettings: LocalModelSettings,
        modelDiagnostics: LocalModelDiagnostics,
        close: @escaping () -> Void,
        renameChat: @escaping (String) -> Void,
        archiveChat: @escaping () -> Void,
        saveModelSettings: @escaping (LocalModelSettings) -> Void,
        validateModelSettings: @escaping () -> Void,
        clearChatHistory: @escaping () -> Void
    ) {
        self.item = item
        self.currentChatTitle = currentChatTitle
        self.hasArchivableChat = hasArchivableChat
        self.modelSettings = modelSettings
        self.modelDiagnostics = modelDiagnostics
        self.close = close
        self.renameChat = renameChat
        self.archiveChat = archiveChat
        self.saveModelSettings = saveModelSettings
        self.validateModelSettings = validateModelSettings
        self.clearChatHistory = clearChatHistory
        _draftSettings = State(initialValue: modelSettings)
        _draftTitle = State(initialValue: currentChatTitle == "New chat" ? "" : currentChatTitle)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        titleBlock

                        switch item {
                        case .rename:
                            renameContent
                        case .archive:
                            archiveContent
                        case .settings:
                            LocalModelSettingsContent(
                                currentSettings: modelSettings,
                                draftSettings: $draftSettings,
                                diagnostics: modelDiagnostics,
                                save: saveModelSettings,
                                validate: validateModelSettings,
                                clearChatHistory: {
                                    isConfirmingHistoryClear = true
                                }
                            )
                        case .help:
                            helpContent
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .onChange(of: modelSettings) { _, newValue in
            draftSettings = newValue
        }
        .onChange(of: currentChatTitle) { _, newValue in
            draftTitle = newValue == "New chat" ? "" : newValue
        }
        .confirmationDialog(
            "Clear chat history?",
            isPresented: $isConfirmingHistoryClear,
            titleVisibility: .visible
        ) {
            Button("Clear history", role: .destructive) {
                clearChatHistory()
                close()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the current chat and all recent chats on this device.")
        }
    }

    private var header: some View {
        HStack {
            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            Text(item.description)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private var placeholderContent: some View {
        EmptyView()
    }

    private var renameContent: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Title")

                TextField("Chat title", text: $draftTitle)
                    .font(.system(size: 17, weight: .regular))
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.07))
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    Button {
                        draftTitle = ""
                        renameChat("")
                        close()
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
                        renameChat(draftTitle)
                        close()
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.white)
                            .foregroundStyle(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var archiveContent: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Current chat")

                Text(hasArchivableChat ? currentChatTitle : "No messages yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(hasArchivableChat ? "Archive saves this chat in Recent chats and starts a new empty chat." : "Start a conversation first, then archive it from here.")
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(.white.opacity(0.56))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    archiveChat()
                } label: {
                    Text(hasArchivableChat ? "Archive and start new" : "Nothing to archive")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(hasArchivableChat ? Color.white : Color.white.opacity(0.12))
                        .foregroundStyle(hasArchivableChat ? Color.black : Color.white.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!hasArchivableChat)
            }
        }
    }

    private var helpContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpPanel(
                title: "Offline first",
                text: "The default responder runs locally with the bundled quantized model. Network-backed Gemini support can be layered in without replacing the local path."
            )

            HelpPanel(
                title: "Memory",
                text: "Use Efficient if the device is warm, low on memory, or responding slowly. History is pruned before it is saved so storage and RAM remain bounded."
            )

            HelpPanel(
                title: "Chats",
                text: "The menu stores recent chats on this device. Rename sets a display title, Archive saves the current chat and opens a new one, and Share exports plain text."
            )
        }
    }
}

private struct LocalModelSettingsContent: View {
    let currentSettings: LocalModelSettings
    @Binding var draftSettings: LocalModelSettings
    let diagnostics: LocalModelDiagnostics
    let save: (LocalModelSettings) -> Void
    let validate: () -> Void
    let clearChatHistory: () -> Void

    private var hasChanges: Bool {
        draftSettings.clamped != currentSettings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            presetPanel
            diagnosticsPanel
            generationPanel
            samplingPanel
            performancePanel
            actions
            dataPanel
        }
    }

    private var presetPanel: some View {
        ModalPanel {
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

                Button(action: validate) {
                    Text("Validate settings")
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

private struct ModalPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.055))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

private struct HelpPanel: View {
    let title: String
    let text: String

    var body: some View {
        ModalPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.48))
            .textCase(.uppercase)
    }
}

private struct DiagnosticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.46))
                .frame(width: 96, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct PresetButton: View {
    let preset: LocalModelPreset
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(preset.subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white.opacity(0.88) : .white.opacity(0.24))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.045))
                    .stroke(Color.white.opacity(isSelected ? 0.18 : 0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct IntegerSettingRow: View {
    let title: String
    let valueText: String
    let note: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 58, alignment: .trailing)
            }

            HStack(spacing: 10) {
                adjustmentButton(systemName: "minus", isEnabled: value > range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }

                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { newValue in
                            value = clampedSteppedValue(newValue)
                        }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(.white.opacity(0.86))

                adjustmentButton(systemName: "plus", isEnabled: value < range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
    }

    private func adjustmentButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(isEnabled ? 0.1 : 0.05))
                .foregroundStyle(Color.white.opacity(isEnabled ? 0.86 : 0.24))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func clampedSteppedValue(_ newValue: Double) -> Int {
        let stepped = Int((newValue / Double(step)).rounded()) * step
        return min(max(stepped, range.lowerBound), range.upperBound)
    }
}

private struct DecimalSettingSlider: View {
    let title: String
    let valueText: String
    let note: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                    .frame(minWidth: 46, alignment: .trailing)
            }

            Slider(value: $value, in: range, step: step)
                .tint(.white.opacity(0.86))
        }
    }
}
