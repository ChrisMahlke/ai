//
//  ChatViewModel+Backend.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import UIKit

@MainActor
extension ChatViewModel {
    func loadBackendIfNeeded() async {
        guard selectedProvider == .local, let localAIManager else { return }

        await localAIManager.loadModelIfNeeded { [weak self] progress, message in
            self?.setRuntimeState(.loadingModel(progress: progress, message: message))
        }
        updateBackendNotice(from: localAIManager.loadState)
    }

    func updateModelSettings(_ settings: LocalModelSettings) {
        localAIManager?.updateSettings(settings)
        setRuntimeState(.idle)
    }

    func selectModelProfile(_ profile: LocalModelProfile) {
        guard let localAIManager else { return }

        AppHaptics.selection()
        stopGeneration(triggerHaptic: false)
        localAIManager.selectModelProfile(profile)
        activeModelProfile = localAIManager.activeModelProfile
        installedModels = localAIManager.installedModels()
        retryLocalModelLoad()
    }

    func refreshInstalledModels() {
        installedModels = localAIManager?.installedModels() ?? LocalModelResourceValidator().installedModels()
    }

    func updateAppearanceMode(_ mode: AppAppearanceMode) {
        appearanceMode = mode
        appearanceStore.save(mode)
    }

    func completeOnboarding() {
        onboardingStore.markCompleted()
        isOnboardingPresented = false
    }

    func copyDiagnosticsReport() {
        UIPasteboard.general.string = diagnosticsReport()
    }

    func selectProvider(_ provider: ChatProvider) {
        guard provider != selectedProvider else { return }

        AppHaptics.selection()
        stopGeneration(triggerHaptic: false)
        selectedProvider = provider
        providerStore.save(provider)
        backendNotice = nil
        setRuntimeState(.idle)

        if provider == .local {
            retryLocalModelLoad()
        }
    }

    func validateModelSettings() {
        guard let localAIManager else { return }

        Task { [weak self] in
            await localAIManager.validateSettingsAndReload { progress, message in
                self?.setRuntimeState(.loadingModel(progress: progress, message: message))
            }
            self?.updateBackendNotice(from: localAIManager.loadState)
        }
    }

    func testModelSettings() {
        guard let localAIManager else { return }

        Task { [weak self] in
            await localAIManager.testCurrentSettings { progress, message in
                self?.setRuntimeState(.loadingModel(progress: progress, message: message))
            }
            self?.updateBackendNotice(from: localAIManager.loadState)
        }
    }

    func retryLocalModelLoad() {
        Task { [weak self] in
            await self?.loadBackendIfNeeded()
        }
    }

    func useEfficientModelSettings() {
        updateModelSettings(LocalModelPreset.efficient.settings)
        retryLocalModelLoad()
    }

    var activeResponder: any ChatResponding {
        switch selectedProvider {
        case .local:
            return localResponder
        case .gemini:
            return geminiResponder
        }
    }

    var localProviderStatus: ProviderStatus {
        guard let localAIManager else {
            return ProviderStatus(
                provider: .local,
                health: .unknown,
                title: "Local provider unavailable",
                detail: "The local manager is not attached in this runtime."
            )
        }

        switch localAIManager.loadState {
        case .loaded:
            return ProviderStatus(
                provider: .local,
                health: .ready,
                title: "Local model ready",
                detail: "\(modelDiagnostics.modelName) is loaded and responses stay on device."
            )
        case .loading(_, let message):
            return ProviderStatus(
                provider: .local,
                health: .loading,
                title: "Loading local model",
                detail: message
            )
        case .unavailable(let message), .failed(let message):
            return ProviderStatus(
                provider: .local,
                health: .unavailable,
                title: "Local model unavailable",
                detail: message
            )
        case .idle:
            return ProviderStatus(
                provider: .local,
                health: .unknown,
                title: "Local model idle",
                detail: "The local provider will load the bundled model before the next response."
            )
        }
    }

    func updateBackendNotice(from loadState: LocalAIManager.LoadState) {
        switch loadState {
        case .failed(let message), .unavailable(let message):
            backendNotice = message
            setRuntimeState(.failed(message))
        case .idle:
            backendNotice = nil
            setRuntimeState(.idle)
        case .loading, .loaded:
            backendNotice = nil
            setRuntimeState(.idle)
        }
    }

    func setRuntimeState(_ state: ChatRuntimeState) {
        runtimeState = state
        isThinking = state.isThinking
        isGenerating = state.isGenerating

        if let loadingModel = state.loadingModel {
            isModelLoading = true
            modelLoadProgress = loadingModel.progress
            modelLoadMessage = loadingModel.message
        } else {
            isModelLoading = false
        }

        if let failureMessage = state.failureMessage {
            backendNotice = failureMessage
        }
    }
}
