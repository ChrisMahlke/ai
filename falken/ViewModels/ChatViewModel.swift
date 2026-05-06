//
//  ChatViewModel.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import CoreGraphics
import Foundation
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var currentChatID = UUID()
    @Published var currentTitleOverride: String?
    @Published var messages: [ChatMessage] = []
    @Published var recentChats: [ChatSession] = []
    @Published var runtimeState: ChatRuntimeState = .idle
    @Published var isThinking = false
    @Published var isGenerating = false
    @Published var isModelLoading = false
    @Published var modelLoadProgress = 0.0
    @Published var modelLoadMessage = "Preparing local model"
    @Published var backendNotice: String?
    @Published var generationMetrics = GenerationMetrics.empty
    @Published var selectedProvider: ChatProvider
    @Published var promptTemplates: [PromptTemplate]
    @Published var activeModelProfile: LocalModelProfile
    @Published var installedModels: [InstalledLocalModel]
    @Published var appearanceMode: AppAppearanceMode

    @Published var prompt = ""
    @Published var chatSearchQuery = ""
    @Published var isDrawerOpen = false
    @Published var isSidebarCollapsed = false
    @Published var isOverflowOpen = false
    @Published var presentedOverflowItem: OverflowMenuItem?
    @Published var isPromptLibraryPresented = false
    @Published var isOnboardingPresented: Bool
    @Published var isComposerFocused = false
    @Published var composerInputHeight: CGFloat = 20
    @Published var sharePayload: SharePayload?
    @Published var generationBackoffUntil: Date?

    let localResponder: any ChatResponding
    let geminiResponder: any ChatResponding
    let localAIManager: LocalAIManager?
    let historyPersistence: ChatPersistenceService
    let providerStore: ChatProviderStore
    let promptTemplateStore: PromptTemplateStore
    let appearanceStore: AppAppearanceStore
    let onboardingStore: OnboardingStore
    let readinessEvaluator = OnDeviceReadinessEvaluator()
    let generationCoordinator = ChatGenerationCoordinator()
    var responseTask: Task<Void, Never>?
    var generationTimeoutTask: Task<Void, Never>?
    var generationBackoffTask: Task<Void, Never>?
    var generationStartedAt: Date?
    var consecutiveGenerationTimeouts = 0
    var cancellables: Set<AnyCancellable> = []
    let generationTimeoutNanoseconds: UInt64 = 120_000_000_000

    init(
        historyStore: ChatHistoryStore? = nil,
        historyPolicy: ChatHistoryPolicy = .default,
        providerStore: ChatProviderStore? = nil,
        promptTemplateStore: PromptTemplateStore? = nil,
        appearanceStore: AppAppearanceStore? = nil,
        onboardingStore: OnboardingStore? = nil
    ) {
        let manager = LocalAIManager.shared
        let resolvedProviderStore = providerStore ?? ChatProviderStore(defaults: .standard)
        let resolvedPromptTemplateStore = promptTemplateStore ?? PromptTemplateStore()
        let resolvedAppearanceStore = appearanceStore ?? AppAppearanceStore()
        let resolvedOnboardingStore = onboardingStore ?? OnboardingStore()
        self.localAIManager = manager
        self.localResponder = LocalModelChatResponder(manager: manager)
        self.geminiResponder = GeminiChatResponder(configuration: .default)
        self.historyPersistence = ChatPersistenceService(
            store: historyStore ?? ChatHistoryStore(),
            policy: historyPolicy
        )
        self.providerStore = resolvedProviderStore
        self.promptTemplateStore = resolvedPromptTemplateStore
        self.appearanceStore = resolvedAppearanceStore
        self.onboardingStore = resolvedOnboardingStore
        self.selectedProvider = resolvedProviderStore.load()
        self.promptTemplates = resolvedPromptTemplateStore.load()
        self.activeModelProfile = manager.activeModelProfile
        self.installedModels = manager.installedModels()
        self.appearanceMode = resolvedAppearanceStore.load()
        self.isOnboardingPresented = !resolvedOnboardingStore.isCompleted()
        restoreHistory()
        observeLocalAIManager(manager)
        observeApplicationLifecycle()
    }

    init(
        responder: any ChatResponding,
        localAIManager: LocalAIManager? = nil,
        historyStore: ChatHistoryStore? = nil,
        historyPolicy: ChatHistoryPolicy = .default,
        providerStore: ChatProviderStore? = nil,
        promptTemplateStore: PromptTemplateStore? = nil,
        appearanceStore: AppAppearanceStore? = nil,
        onboardingStore: OnboardingStore? = nil
    ) {
        let resolvedProviderStore = providerStore ?? ChatProviderStore(defaults: .standard)
        let resolvedPromptTemplateStore = promptTemplateStore ?? PromptTemplateStore()
        let resolvedAppearanceStore = appearanceStore ?? AppAppearanceStore()
        let resolvedOnboardingStore = onboardingStore ?? OnboardingStore()
        self.localResponder = responder
        self.geminiResponder = GeminiChatResponder(configuration: .default)
        self.localAIManager = localAIManager
        self.historyPersistence = ChatPersistenceService(
            store: historyStore ?? ChatHistoryStore(),
            policy: historyPolicy
        )
        self.providerStore = resolvedProviderStore
        self.promptTemplateStore = resolvedPromptTemplateStore
        self.appearanceStore = resolvedAppearanceStore
        self.onboardingStore = resolvedOnboardingStore
        self.selectedProvider = resolvedProviderStore.load()
        self.promptTemplates = resolvedPromptTemplateStore.load()
        self.activeModelProfile = localAIManager?.activeModelProfile ?? .smallFast
        self.installedModels = localAIManager?.installedModels() ?? LocalModelResourceValidator().installedModels()
        self.appearanceMode = resolvedAppearanceStore.load()
        self.isOnboardingPresented = !resolvedOnboardingStore.isCompleted()
        restoreHistory()
        if let localAIManager {
            observeLocalAIManager(localAIManager)
        }
        observeApplicationLifecycle()
    }

    deinit {
        responseTask?.cancel()
        generationTimeoutTask?.cancel()
        generationBackoffTask?.cancel()
    }

    var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponseActive && !isInGenerationBackoff
    }

    var isResponseActive: Bool {
        isThinking || isGenerating
    }

    var isInGenerationBackoff: Bool {
        guard let generationBackoffUntil else { return false }

        return generationBackoffUntil > Date()
    }

    var chatTitle: String {
        if let currentTitleOverride, !currentTitleOverride.isEmpty {
            return currentTitleOverride
        }

        return messages.first { $0.role == .user }?.text ?? "New chat"
    }

    var hasArchivableChat: Bool {
        messages.contains { $0.role == .user }
    }

    var canRegenerate: Bool {
        !isResponseActive && !isInGenerationBackoff && messages.contains { $0.role == .user }
    }

    var chatSearchMatchCount: Int {
        let query = chatSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return 0 }

        return messages.reduce(0) { count, message in
            count + message.text.localizedCaseInsensitiveMatchCount(of: query)
        }
    }

    var providerStatus: ProviderStatus {
        switch selectedProvider {
        case .local:
            return localProviderStatus
        case .gemini:
            return ProviderStatus(
                provider: .gemini,
                health: .notConfigured,
                title: "Gemini not configured",
                detail: "Remote SDK calls are intentionally behind the provider abstraction. Add Gemini credentials and SDK wiring before using it for production responses."
            )
        }
    }

    var readinessReport: OnDeviceReadinessReport {
        readinessEvaluator.evaluate(activeModelProfile: activeModelProfile)
    }

    var modelSettings: LocalModelSettings {
        localAIManager?.settings ?? .default
    }

    var modelDiagnostics: LocalModelDiagnostics {
        localAIManager?.diagnostics ?? .empty
    }

    var anonymizedDiagnosticsReport: String {
        diagnosticsReport()
    }

}
