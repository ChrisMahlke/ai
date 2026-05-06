//
//  ChatViewModel+Sessions.swift
//  falken
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
        AppHaptics.selection()
        guard hasArchivableChat else {
            dismissOverflowModal()
            return
        }

        stopGeneration(triggerHaptic: false)
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
        stopGeneration(triggerHaptic: false)
        currentChatID = UUID()
        currentTitleOverride = nil
        messages = []
        recentChats = []
        prompt = ""
        chatSearchQuery = ""
        generationMetrics = .empty
        historyPersistence.clear()
        scheduleHistorySave()
    }

    func startNewChat() {
        AppHaptics.selection()
        stopGeneration(triggerHaptic: false)
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

        AppHaptics.selection()
        stopGeneration(triggerHaptic: false)
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
            messages: historyPersistence.pruneArchivedMessages(messages),
            createdAt: existingSession?.createdAt ?? Date(),
            updatedAt: Date(),
            isPinned: existingSession?.isPinned ?? false
        )

        recentChats.removeAll { $0.id == currentChatID }
        recentChats.insert(session, at: 0)
        sortRecentChats()
        recentChats = historyPersistence.pruneRecentChats(recentChats)
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
        guard let prunedSnapshot = historyPersistence.load() else { return }

        currentChatID = prunedSnapshot.currentChatID
        currentTitleOverride = normalizedChatTitle(prunedSnapshot.currentTitleOverride ?? "")
        messages = prunedSnapshot.currentMessages
        recentChats = prunedSnapshot.recentChats
        sortRecentChats()
    }

    func scheduleHistorySave() {
        let snapshot = ChatHistorySnapshot(
            currentChatID: currentChatID,
            currentTitleOverride: currentTitleOverride,
            currentMessages: messages,
            recentChats: recentChats
        )

        historyPersistence.scheduleSave(snapshot)
    }

    func saveHistoryImmediately() {
        let snapshot = ChatHistorySnapshot(
            currentChatID: currentChatID,
            currentTitleOverride: currentTitleOverride,
            currentMessages: messages,
            recentChats: recentChats
        )

        historyPersistence.saveImmediately(snapshot)
    }

    func trimVisibleMessagesIfNeeded() {
        guard messages.count > historyPersistence.policy.maxVisibleMessages else { return }

        messages = historyPersistence.pruneVisibleMessages(messages)
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
