//
//  ChatViewModel+Diagnostics.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension ChatViewModel {
    func diagnosticsReport() -> String {
        ChatDiagnosticsReporter.report(
            selectedProvider: selectedProvider,
            activeModelProfile: activeModelProfile,
            diagnostics: modelDiagnostics,
            appearanceMode: appearanceMode,
            recentChatCount: recentChats.count,
            currentMessageCount: messages.count,
            installedModels: installedModels
        )
    }
}

struct ChatDiagnosticsReporter {
    static func report(
        selectedProvider: ChatProvider,
        activeModelProfile: LocalModelProfile,
        diagnostics: LocalModelDiagnostics,
        appearanceMode: AppAppearanceMode,
        recentChatCount: Int,
        currentMessageCount: Int,
        installedModels: [InstalledLocalModel]
    ) -> String {
        let installedSummary = installedModels
            .map { model in
                let size = model.fileSizeBytes > 0 ? ByteCountFormatter.string(fromByteCount: Int64(model.fileSizeBytes), countStyle: .memory) : "not installed"
                return "- \(model.profile.title): \(size)"
            }
            .joined(separator: "\n")
        let appMemory = diagnostics.appMemoryBytes.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .memory) } ?? "unknown"
        let loadTime = diagnostics.loadDuration.map { String(format: "%.1fs", $0) } ?? "n/a"

        return """
        \(AppBrand.name) diagnostics

        Provider: \(selectedProvider.title)
        Active local model: \(activeModelProfile.title)
        Active model file: \(diagnostics.fileName)
        Active model size: \(ByteCountFormatter.string(fromByteCount: Int64(diagnostics.fileSizeBytes), countStyle: .memory))
        Model status: \(diagnostics.status.anonymizedDescription)
        Device memory: \(ByteCountFormatter.string(fromByteCount: Int64(diagnostics.physicalMemoryBytes), countStyle: .memory))
        App memory: \(appMemory)
        Thermal state: \(diagnostics.thermalState.anonymizedDescription)
        Load time: \(loadTime)
        Appearance: \(appearanceMode.title)
        Recent chats: \(recentChatCount)
        Current messages: \(currentMessageCount)

        Installed local models:
        \(installedSummary)
        """
    }
}

private extension LocalModelDiagnostics.Status {
    var anonymizedDescription: String {
        switch self {
        case .notChecked:
            return "not checked"
        case .checking:
            return "checking"
        case .ready:
            return "ready"
        case .unavailable:
            return "unavailable"
        case .failed:
            return "failed"
        }
    }
}

private extension ProcessInfo.ThermalState {
    var anonymizedDescription: String {
        switch self {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "unknown"
        }
    }
}
