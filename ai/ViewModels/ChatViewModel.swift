//
//  ChatViewModel.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Combine
import CoreGraphics
import Foundation
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var currentChatID = UUID()
    @Published private(set) var currentTitleOverride: String?
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var recentChats: [ChatSession] = []
    @Published private(set) var runtimeState: ChatRuntimeState = .idle
    @Published private(set) var isThinking = false
    @Published private(set) var isGenerating = false
    @Published private(set) var isModelLoading = false
    @Published private(set) var modelLoadProgress = 0.0
    @Published private(set) var modelLoadMessage = "Preparing local model"
    @Published private(set) var backendNotice: String?
    @Published private(set) var generationMetrics = GenerationMetrics.empty
    @Published private(set) var selectedProvider: ChatProvider
    @Published private(set) var promptTemplates: [PromptTemplate]

    @Published var prompt = ""
    @Published var chatSearchQuery = ""
    @Published var isDrawerOpen = false
    @Published var isSidebarCollapsed = false
    @Published var isOverflowOpen = false
    @Published var presentedOverflowItem: OverflowMenuItem?
    @Published var isPromptLibraryPresented = false
    @Published var isComposerFocused = false
    @Published var composerInputHeight: CGFloat = 20
    @Published var sharePayload: SharePayload?

    private let localResponder: any ChatResponding
    private let geminiResponder: any ChatResponding
    private let localAIManager: LocalAIManager?
    private let historyStore: ChatHistoryStore
    private let providerStore: ChatProviderStore
    private let promptTemplateStore: PromptTemplateStore
    private var responseTask: Task<Void, Never>?
    private var pendingHistorySaveTask: Task<Void, Never>?
    private var generationStartedAt: Date?
    private var cancellables: Set<AnyCancellable> = []
    private let historyPolicy: ChatHistoryPolicy

    init(
        historyStore: ChatHistoryStore? = nil,
        historyPolicy: ChatHistoryPolicy = .default,
        providerStore: ChatProviderStore? = nil,
        promptTemplateStore: PromptTemplateStore? = nil
    ) {
        let manager = LocalAIManager.shared
        let resolvedProviderStore = providerStore ?? ChatProviderStore(defaults: .standard)
        let resolvedPromptTemplateStore = promptTemplateStore ?? PromptTemplateStore()
        self.localAIManager = manager
        self.localResponder = LocalModelChatResponder(manager: manager)
        self.geminiResponder = GeminiChatResponder(configuration: .default)
        self.historyStore = historyStore ?? ChatHistoryStore()
        self.historyPolicy = historyPolicy
        self.providerStore = resolvedProviderStore
        self.promptTemplateStore = resolvedPromptTemplateStore
        self.selectedProvider = resolvedProviderStore.load()
        self.promptTemplates = resolvedPromptTemplateStore.load()
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
        promptTemplateStore: PromptTemplateStore? = nil
    ) {
        let resolvedProviderStore = providerStore ?? ChatProviderStore(defaults: .standard)
        let resolvedPromptTemplateStore = promptTemplateStore ?? PromptTemplateStore()
        self.localResponder = responder
        self.geminiResponder = GeminiChatResponder(configuration: .default)
        self.localAIManager = localAIManager
        self.historyStore = historyStore ?? ChatHistoryStore()
        self.historyPolicy = historyPolicy
        self.providerStore = resolvedProviderStore
        self.promptTemplateStore = resolvedPromptTemplateStore
        self.selectedProvider = resolvedProviderStore.load()
        self.promptTemplates = resolvedPromptTemplateStore.load()
        restoreHistory()
        if let localAIManager {
            observeLocalAIManager(localAIManager)
        }
        observeApplicationLifecycle()
    }

    deinit {
        responseTask?.cancel()
        pendingHistorySaveTask?.cancel()
    }

    var canSend: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isResponseActive
    }

    var isResponseActive: Bool {
        isThinking || isGenerating
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
        !isResponseActive && messages.contains { $0.role == .user }
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

    var modelSettings: LocalModelSettings {
        localAIManager?.settings ?? .default
    }

    var modelDiagnostics: LocalModelDiagnostics {
        localAIManager?.diagnostics ?? .empty
    }

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

    func selectProvider(_ provider: ChatProvider) {
        guard provider != selectedProvider else { return }

        stopGeneration()
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

    func openModelSettings() {
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = .settings
    }

    func openDrawer() {
        isComposerFocused = false
        isDrawerOpen = true
    }

    func closeDrawer() {
        isDrawerOpen = false
    }

    func togglePersistentSidebar() {
        isSidebarCollapsed.toggle()
    }

    func toggleOverflowMenu() {
        isComposerFocused = false
        isOverflowOpen.toggle()
    }

    func closeOverflowMenu() {
        isOverflowOpen = false
    }

    func selectOverflowItem(_ item: OverflowMenuItem) {
        isOverflowOpen = false
        isComposerFocused = false
        presentedOverflowItem = item
    }

    func dismissOverflowModal() {
        presentedOverflowItem = nil
    }

    func openPromptLibrary() {
        isComposerFocused = false
        isDrawerOpen = false
        isPromptLibraryPresented = true
    }

    func dismissPromptLibrary() {
        isPromptLibraryPresented = false
    }

    func usePromptTemplate(_ template: PromptTemplate) {
        guard !isResponseActive else { return }

        prompt = template.text
        isPromptLibraryPresented = false
        isComposerFocused = true
    }

    func savePromptTemplate(title: String, text: String) {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedText.isEmpty else { return }

        let template = PromptTemplate(
            title: String(normalizedTitle.prefix(64)),
            text: String(normalizedText.prefix(2_000)),
            category: "Saved"
        )
        promptTemplates.insert(template, at: PromptTemplate.builtIns.count)
        promptTemplateStore.save(promptTemplates)
    }

    func deletePromptTemplate(_ template: PromptTemplate) {
        guard !template.isBuiltIn else { return }

        promptTemplates.removeAll { $0.id == template.id }
        promptTemplateStore.save(promptTemplates)
    }

    func shareCurrentChat() {
        let transcript = transcriptText()
        guard !transcript.isEmpty else { return }

        isComposerFocused = false
        sharePayload = SharePayload(text: transcript)
    }

    func renameCurrentChat(to title: String) {
        let normalizedTitle = normalizedChatTitle(title)
        currentTitleOverride = normalizedTitle
        archiveCurrentChat()
        scheduleHistorySave()
    }

    func archiveCurrentChatAndStartNew() {
        guard hasArchivableChat else {
            dismissOverflowModal()
            return
        }

        stopGeneration()
        archiveCurrentChat()
        currentChatID = UUID()
        currentTitleOverride = nil
        prompt = ""
        chatSearchQuery = ""
        messages = []
        generationMetrics = .empty
        composerInputHeight = 20
        isComposerFocused = true
        dismissOverflowModal()
        scheduleHistorySave()
    }

    func deleteRecentChat(_ chat: ChatSession) {
        recentChats.removeAll { $0.id == chat.id }

        if chat.id == currentChatID {
            currentChatID = UUID()
            currentTitleOverride = nil
            messages = []
            prompt = ""
            chatSearchQuery = ""
            setRuntimeState(.idle)
        }

        scheduleHistorySave()
    }

    func togglePinnedRecentChat(_ chat: ChatSession) {
        guard let chatIndex = recentChats.firstIndex(where: { $0.id == chat.id }) else { return }

        recentChats[chatIndex].isPinned.toggle()
        sortRecentChats()
        scheduleHistorySave()
    }

    func clearChatHistory() {
        stopGeneration()
        currentChatID = UUID()
        currentTitleOverride = nil
        messages = []
        recentChats = []
        prompt = ""
        chatSearchQuery = ""
        generationMetrics = .empty
        historyStore.clear()
        scheduleHistorySave()
    }

    func useSuggestedPrompt(_ text: String) {
        guard !isResponseActive else { return }

        prompt = text
        isComposerFocused = true
    }

    func sendCurrentPrompt() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isResponseActive else { return }

        isComposerFocused = false
        messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        trimVisibleMessagesIfNeeded()
        prompt = ""
        scheduleHistorySave()

        startResponse(for: trimmedPrompt, history: messages)
    }

    func regenerateLastResponse() {
        guard canRegenerate, let lastUserIndex = messages.lastIndex(where: { $0.role == .user }) else { return }

        isComposerFocused = false
        let lastPrompt = messages[lastUserIndex].text
        messages = Array(messages.prefix(lastUserIndex + 1))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()

        startResponse(for: lastPrompt, history: messages)
    }

    func editMessage(_ message: ChatMessage) {
        guard !isResponseActive, message.role == .user,
              let messageIndex = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        prompt = messages[messageIndex].text
        messages = Array(messages.prefix(messageIndex))
        setRuntimeState(.idle)
        generationMetrics = .empty
        isComposerFocused = true
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func deleteMessage(_ message: ChatMessage) {
        guard !isResponseActive else { return }
        messages.removeAll { $0.id == message.id }
        if !messages.contains(where: { $0.role == .user }) {
            currentTitleOverride = nil
        }
        generationMetrics = .empty
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func continueFromMessage(_ message: ChatMessage) {
        guard !isResponseActive,
              let messageIndex = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        messages = Array(messages.prefix(messageIndex + 1))
        generationMetrics = .empty
        isComposerFocused = true
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    private func startResponse(for prompt: String, history: [ChatMessage]) {
        generationMetrics = GenerationMetrics.empty.starting(prompt: prompt)
        generationStartedAt = nil
        setRuntimeState(.thinking)
        backendNotice = nil

        let chatID = currentChatID
        let responder = activeResponder

        responseTask?.cancel()
        localAIManager?.cancelGeneration()
        responseTask = Task { [weak self, responder] in
            guard let self else { return }

            let stream = await responder.responseStream(for: prompt, history: history)
            let assistantID = UUID()
            var didStartResponse = false

            for await token in stream {
                guard !Task.isCancelled else { return }

                if !didStartResponse {
                    self.beginAssistantResponse(id: assistantID, chatID: chatID)
                    didStartResponse = true
                }

                self.appendAssistantToken(token, messageID: assistantID, chatID: chatID)
            }

            if didStartResponse {
                self.finishAssistantResponse(chatID: chatID)
            } else {
                self.finishCancelledOrEmptyResponse(chatID: chatID)
            }
        }
    }

    func stopGeneration() {
        let shouldMarkStopped = isResponseActive
        localAIManager?.cancelGeneration()
        responseTask?.cancel()
        responseTask = nil
        setRuntimeState(.idle)

        if messages.last?.role == .assistant, messages.last?.text.isEmpty == true {
            messages.removeLast()
        } else if shouldMarkStopped, messages.last?.role == .assistant {
            messages[messages.count - 1].state = .stopped
        }

        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    func cancelActiveResponse() {
        stopGeneration()
    }

    func startNewChat() {
        stopGeneration()
        archiveCurrentChat()

        currentChatID = UUID()
        currentTitleOverride = nil
        prompt = ""
        chatSearchQuery = ""
        messages = []
        setRuntimeState(.idle)
        isDrawerOpen = false
        isOverflowOpen = false
        presentedOverflowItem = nil
        composerInputHeight = 20
        isComposerFocused = true
        generationMetrics = .empty
        scheduleHistorySave()
    }

    func loadChat(_ chat: ChatSession) {
        guard chat.id != currentChatID else {
            closeDrawer()
            return
        }

        stopGeneration()
        archiveCurrentChat()

        currentChatID = chat.id
        currentTitleOverride = chat.title
        prompt = ""
        chatSearchQuery = ""
        messages = chat.messages
        setRuntimeState(.idle)
        isOverflowOpen = false
        presentedOverflowItem = nil
        isComposerFocused = false
        composerInputHeight = 20
        closeDrawer()
        generationMetrics = .empty
        scheduleHistorySave()
    }

    private func beginAssistantResponse(id: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }

        generationStartedAt = Date()
        generationMetrics = generationMetrics.starting(prompt: lastUserPrompt(for: chatID))
        setRuntimeState(.generating)
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    private func appendAssistantToken(_ token: String, messageID: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }

        messages[messageIndex].text += token
        messages[messageIndex].state = .complete
        updateGenerationMetrics(token)
        scheduleHistorySave()
    }

    private func finishAssistantResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        setRuntimeState(.idle)
        generationStartedAt = nil
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    private func finishCancelledOrEmptyResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        responseTask = nil
        setRuntimeState(.idle)
        generationStartedAt = nil
        scheduleHistorySave()
    }

    private func archiveCurrentChat() {
        guard messages.contains(where: { $0.role == .user }) else { return }

        let existingSession = recentChats.first { $0.id == currentChatID }
        let session = ChatSession(
            id: currentChatID,
            title: chatTitle,
            messages: Array(messages.suffix(historyPolicy.maxArchivedMessagesPerChat)),
            createdAt: existingSession?.createdAt ?? Date(),
            updatedAt: Date(),
            isPinned: existingSession?.isPinned ?? false
        )

        recentChats.removeAll { $0.id == currentChatID }
        recentChats.insert(session, at: 0)
        sortRecentChats()
        if recentChats.count > historyPolicy.maxRecentChats {
            recentChats.removeLast(recentChats.count - historyPolicy.maxRecentChats)
        }
    }

    private func sortRecentChats() {
        recentChats.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private var activeResponder: any ChatResponding {
        switch selectedProvider {
        case .local:
            return localResponder
        case .gemini:
            return geminiResponder
        }
    }

    private var localProviderStatus: ProviderStatus {
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

    private func updateBackendNotice(from loadState: LocalAIManager.LoadState) {
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

    private func setRuntimeState(_ state: ChatRuntimeState) {
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

    private func observeLocalAIManager(_ manager: LocalAIManager) {
        manager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func observeApplicationLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.trimVisibleMessagesIfNeeded()
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveHistoryImmediately()
            }
            .store(in: &cancellables)
    }

    private func restoreHistory() {
        guard let snapshot = historyStore.load() else { return }
        let prunedSnapshot = historyPolicy.pruneSnapshot(snapshot)

        currentChatID = prunedSnapshot.currentChatID
        currentTitleOverride = normalizedChatTitle(prunedSnapshot.currentTitleOverride ?? "")
        messages = prunedSnapshot.currentMessages
        recentChats = prunedSnapshot.recentChats
        sortRecentChats()
    }

    private func scheduleHistorySave() {
        pendingHistorySaveTask?.cancel()

        let snapshot = historyPolicy.pruneSnapshot(ChatHistorySnapshot(
            currentChatID: currentChatID,
            currentTitleOverride: currentTitleOverride,
            currentMessages: messages,
            recentChats: recentChats
        ))
        let store = historyStore

        pendingHistorySaveTask = Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            store.save(snapshot)
        }
    }

    private func saveHistoryImmediately() {
        pendingHistorySaveTask?.cancel()

        let snapshot = historyPolicy.pruneSnapshot(ChatHistorySnapshot(
            currentChatID: currentChatID,
            currentTitleOverride: currentTitleOverride,
            currentMessages: messages,
            recentChats: recentChats
        ))

        historyStore.save(snapshot)
    }

    private func trimVisibleMessagesIfNeeded() {
        guard messages.count > historyPolicy.maxVisibleMessages else { return }

        messages = historyPolicy.pruneVisibleMessages(messages)
    }

    private func updateGenerationMetrics(_ token: String) {
        guard let generationStartedAt else { return }

        generationMetrics = generationMetrics.addingChunk(
            token,
            elapsedSeconds: Date().timeIntervalSince(generationStartedAt)
        )
    }

    private func transcriptText() -> String {
        guard !messages.isEmpty else { return "" }

        let body = messages
            .map { message in
                let speaker = message.role == .user ? "You" : "Assistant"
                let suffix = message.state == .stopped ? " [stopped]" : ""
                return "\(speaker): \(message.text)\(suffix)"
            }
            .joined(separator: "\n\n")

        return "\(chatTitle)\n\n\(body)"
    }

    private func normalizedChatTitle(_ title: String) -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        return String(trimmedTitle.prefix(80))
    }

    private func lastUserPrompt(for chatID: UUID) -> String {
        guard chatID == currentChatID else { return "" }

        return messages.last { $0.role == .user }?.text ?? ""
    }
}
