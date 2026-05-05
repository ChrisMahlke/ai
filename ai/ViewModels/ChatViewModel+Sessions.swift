//
//  ChatViewModel+Sessions.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

@MainActor
extension ChatViewModel {
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

    func archiveCurrentChat() {
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

    func sortRecentChats() {
        recentChats.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func restoreHistory() {
        guard let snapshot = historyStore.load() else { return }
        let prunedSnapshot = historyPolicy.pruneSnapshot(snapshot)

        currentChatID = prunedSnapshot.currentChatID
        currentTitleOverride = normalizedChatTitle(prunedSnapshot.currentTitleOverride ?? "")
        messages = prunedSnapshot.currentMessages
        recentChats = prunedSnapshot.recentChats
        sortRecentChats()
    }

    func scheduleHistorySave() {
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

    func saveHistoryImmediately() {
        pendingHistorySaveTask?.cancel()

        let snapshot = historyPolicy.pruneSnapshot(ChatHistorySnapshot(
            currentChatID: currentChatID,
            currentTitleOverride: currentTitleOverride,
            currentMessages: messages,
            recentChats: recentChats
        ))

        historyStore.save(snapshot)
    }

    func trimVisibleMessagesIfNeeded() {
        guard messages.count > historyPolicy.maxVisibleMessages else { return }

        messages = historyPolicy.pruneVisibleMessages(messages)
    }

    func transcriptText() -> String {
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

    func normalizedChatTitle(_ title: String) -> String? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        return String(trimmedTitle.prefix(80))
    }
}
