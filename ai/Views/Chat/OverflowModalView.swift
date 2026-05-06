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
    let selectedProvider: ChatProvider
    let providerStatus: ProviderStatus
    let activeModelProfile: LocalModelProfile
    let installedModels: [InstalledLocalModel]
    let appearanceMode: AppAppearanceMode
    let diagnosticsReport: String
    let close: () -> Void
    let renameChat: (String) -> Void
    let archiveChat: () -> Void
    let saveModelSettings: (LocalModelSettings) -> Void
    let selectProvider: (ChatProvider) -> Void
    let selectModelProfile: (LocalModelProfile) -> Void
    let updateAppearanceMode: (AppAppearanceMode) -> Void
    let validateModelSettings: () -> Void
    let testModelSettings: () -> Void
    let copyDiagnostics: () -> Void
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
        selectedProvider: ChatProvider,
        providerStatus: ProviderStatus,
        activeModelProfile: LocalModelProfile,
        installedModels: [InstalledLocalModel],
        appearanceMode: AppAppearanceMode,
        diagnosticsReport: String,
        close: @escaping () -> Void,
        renameChat: @escaping (String) -> Void,
        archiveChat: @escaping () -> Void,
        saveModelSettings: @escaping (LocalModelSettings) -> Void,
        selectProvider: @escaping (ChatProvider) -> Void,
        selectModelProfile: @escaping (LocalModelProfile) -> Void,
        updateAppearanceMode: @escaping (AppAppearanceMode) -> Void,
        validateModelSettings: @escaping () -> Void,
        testModelSettings: @escaping () -> Void,
        copyDiagnostics: @escaping () -> Void,
        clearChatHistory: @escaping () -> Void
    ) {
        self.item = item
        self.currentChatTitle = currentChatTitle
        self.hasArchivableChat = hasArchivableChat
        self.modelSettings = modelSettings
        self.modelDiagnostics = modelDiagnostics
        self.selectedProvider = selectedProvider
        self.providerStatus = providerStatus
        self.activeModelProfile = activeModelProfile
        self.installedModels = installedModels
        self.appearanceMode = appearanceMode
        self.diagnosticsReport = diagnosticsReport
        self.close = close
        self.renameChat = renameChat
        self.archiveChat = archiveChat
        self.saveModelSettings = saveModelSettings
        self.selectProvider = selectProvider
        self.selectModelProfile = selectModelProfile
        self.updateAppearanceMode = updateAppearanceMode
        self.validateModelSettings = validateModelSettings
        self.testModelSettings = testModelSettings
        self.copyDiagnostics = copyDiagnostics
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
                        case .models:
                            ModelManagementContent(
                                activeModelProfile: activeModelProfile,
                                installedModels: installedModels,
                                selectModelProfile: selectModelProfile
                            )
                        case .diagnostics:
                            DiagnosticsExportContent(
                                report: diagnosticsReport,
                                copyDiagnostics: copyDiagnostics
                            )
                        case .settings:
                            LocalModelSettingsContent(
                                currentSettings: modelSettings,
                                draftSettings: $draftSettings,
                                diagnostics: modelDiagnostics,
                                selectedProvider: selectedProvider,
                                providerStatus: providerStatus,
                                appearanceMode: appearanceMode,
                                save: saveModelSettings,
                                selectProvider: selectProvider,
                                updateAppearanceMode: updateAppearanceMode,
                                validate: validateModelSettings,
                                test: testModelSettings,
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
        .preferredColorScheme(appearanceMode.colorScheme)
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
                    .background(AppTheme.subtleFill)
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
                .foregroundStyle(AppTheme.foreground.opacity(0.92))

            Text(item.description)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(AppTheme.foreground.opacity(0.66))
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
                            .fill(AppTheme.foreground.opacity(0.07))
                            .stroke(AppTheme.foreground.opacity(0.12), lineWidth: 1)
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
                            .background(AppTheme.subtleFill)
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
                            .background(AppTheme.primaryAction)
                            .foregroundStyle(AppTheme.primaryActionText)
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
                    .foregroundStyle(AppTheme.foreground.opacity(0.88))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(hasArchivableChat ? "Archive saves this chat in Recent chats and starts a new empty chat." : "Start a conversation first, then archive it from here.")
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.foreground.opacity(0.56))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    archiveChat()
                } label: {
                    Text(hasArchivableChat ? "Archive and start new" : "Nothing to archive")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(hasArchivableChat ? AppTheme.primaryAction : AppTheme.foreground.opacity(0.12))
                        .foregroundStyle(hasArchivableChat ? AppTheme.primaryActionText : AppTheme.foreground.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!hasArchivableChat)
            }
        }
    }

    private var helpContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSummaryPanel()
            HelpRequestFlowPanel()
            HelpDefinitionPanel()

            HelpPanel(
                title: "Models and providers",
                text: "Local is the default provider. It loads a bundled GGUF model from the app, keeps the prompt and response on this device, and streams tokens back into the chat. Gemini is an optional cloud provider for cases where you want a remote model instead of the on-device model."
            )

            HelpPanel(
                title: "Memory and performance",
                text: "The app is tuned for iPhone and iPad constraints. A smaller quantized model uses less RAM and usually responds sooner. Larger models can improve answer quality, but they increase app size, load time, memory pressure, and thermal load. If the device is warm or responses slow down, use a smaller profile or the Efficient preset."
            )

            HelpPanel(
                title: "Chats and storage",
                text: "Chats are stored locally on this device. New chat saves the current conversation to Recent chats when there is content to keep. Rename changes only the display title. Archive moves the current chat into Recent chats and starts a blank conversation."
            )

            HelpPanel(
                title: "Privacy and diagnostics",
                text: "Local model prompts and responses do not need to leave the device. Diagnostics are designed for troubleshooting and avoid chat message text or user identifiers. They report technical state such as active provider, model profile, memory, thermal state, and installed model status."
            )

            HelpTroubleshootingPanel()
        }
    }
}
