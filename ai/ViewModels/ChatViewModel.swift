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

    @Published var prompt = ""
    @Published var isDrawerOpen = false
    @Published var isOverflowOpen = false
    @Published var presentedOverflowItem: OverflowMenuItem?
    @Published var isComposerFocused = false
    @Published var composerInputHeight: CGFloat = 20
    @Published var sharePayload: SharePayload?

    private let responder: any ChatResponding
    private let localAIManager: LocalAIManager?
    private let historyStore: ChatHistoryStore
    private var responseTask: Task<Void, Never>?
    private var pendingHistorySaveTask: Task<Void, Never>?
    private var generationStartedAt: Date?
    private var cancellables: Set<AnyCancellable> = []
    private let historyPolicy: ChatHistoryPolicy

    init(
        historyStore: ChatHistoryStore? = nil,
        historyPolicy: ChatHistoryPolicy = .default
    ) {
        let manager = LocalAIManager.shared
        self.localAIManager = manager
        self.responder = LocalModelChatResponder(manager: manager)
        self.historyStore = historyStore ?? ChatHistoryStore()
        self.historyPolicy = historyPolicy
        restoreHistory()
        observeLocalAIManager(manager)
        observeApplicationLifecycle()
    }

    init(
        responder: any ChatResponding,
        localAIManager: LocalAIManager? = nil,
        historyStore: ChatHistoryStore? = nil,
        historyPolicy: ChatHistoryPolicy = .default
    ) {
        self.responder = responder
        self.localAIManager = localAIManager
        self.historyStore = historyStore ?? ChatHistoryStore()
        self.historyPolicy = historyPolicy
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

    var modelSettings: LocalModelSettings {
        localAIManager?.settings ?? .default
    }

    var modelDiagnostics: LocalModelDiagnostics {
        localAIManager?.diagnostics ?? .empty
    }

    func loadBackendIfNeeded() async {
        guard let localAIManager else { return }

        await localAIManager.loadModelIfNeeded { [weak self] progress, message in
            self?.setRuntimeState(.loadingModel(progress: progress, message: message))
        }
        updateBackendNotice(from: localAIManager.loadState)
    }

    func updateModelSettings(_ settings: LocalModelSettings) {
        localAIManager?.updateSettings(settings)
        setRuntimeState(.idle)
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
            setRuntimeState(.idle)
        }

        scheduleHistorySave()
    }

    func clearChatHistory() {
        stopGeneration()
        currentChatID = UUID()
        currentTitleOverride = nil
        messages = []
        recentChats = []
        prompt = ""
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
        guard !trimmedPrompt.isEmpty, !isThinking else { return }

        isComposerFocused = false
        messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        trimVisibleMessagesIfNeeded()
        prompt = ""
        generationMetrics = .empty
        generationStartedAt = nil
        setRuntimeState(.thinking)
        backendNotice = nil
        scheduleHistorySave()

        let chatID = currentChatID
        let history = messages

        responseTask?.cancel()
        localAIManager?.cancelGeneration()
        responseTask = Task { [weak self, responder] in
            guard let self else { return }

            let stream = await responder.responseStream(for: trimmedPrompt, history: history)
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
        localAIManager?.cancelGeneration()
        responseTask?.cancel()
        responseTask = nil
        setRuntimeState(.idle)

        if messages.last?.role == .assistant, messages.last?.text.isEmpty == true {
            messages.removeLast()
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

    private func appendAssistantResponse(_ response: String, toChatID chatID: UUID) {
        guard chatID == currentChatID else { return }

        isThinking = false
        messages.append(ChatMessage(role: .assistant, text: response))
    }

    private func beginAssistantResponse(id: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }

        generationStartedAt = Date()
        generationMetrics = .empty
        setRuntimeState(.generating)
        messages.append(ChatMessage(id: id, role: .assistant, text: ""))
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    private func appendAssistantToken(_ token: String, messageID: UUID, chatID: UUID) {
        guard chatID == currentChatID else { return }
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageID }) else { return }

        messages[messageIndex].text += token
        updateGenerationMetrics()
        scheduleHistorySave()
    }

    private func finishAssistantResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
        setRuntimeState(.idle)
        generationStartedAt = nil
        trimVisibleMessagesIfNeeded()
        scheduleHistorySave()
    }

    private func finishCancelledOrEmptyResponse(chatID: UUID) {
        guard chatID == currentChatID else { return }
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
            updatedAt: Date()
        )

        recentChats.removeAll { $0.id == currentChatID }
        recentChats.insert(session, at: 0)
        if recentChats.count > historyPolicy.maxRecentChats {
            recentChats.removeLast(recentChats.count - historyPolicy.maxRecentChats)
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

    private func updateGenerationMetrics() {
        guard let generationStartedAt else { return }

        generationMetrics = generationMetrics.addingChunk(
            elapsedSeconds: Date().timeIntervalSince(generationStartedAt)
        )
    }

    private func transcriptText() -> String {
        guard !messages.isEmpty else { return "" }

        let body = messages
            .map { message in
                let speaker = message.role == .user ? "You" : "Assistant"
                return "\(speaker): \(message.text)"
            }
            .joined(separator: "\n\n")

        return "\(chatTitle)\n\n\(body)"
    }

    private func normalizedChatTitle(_ title: String) -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        return String(trimmedTitle.prefix(80))
    }
}
