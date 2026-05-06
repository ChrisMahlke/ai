//
//  ChatPersistenceService.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

@MainActor
final class ChatPersistenceService {
    let policy: ChatHistoryPolicy
    private let store: ChatHistoryStore
    private var pendingSaveTask: Task<Void, Never>?

    init(
        store: ChatHistoryStore = ChatHistoryStore(),
        policy: ChatHistoryPolicy = .default
    ) {
        self.store = store
        self.policy = policy
    }

    deinit {
        pendingSaveTask?.cancel()
    }

    func load() -> ChatHistorySnapshot? {
        guard let snapshot = store.load() else { return nil }

        return policy.pruneSnapshot(snapshot)
    }

    func scheduleSave(_ snapshot: ChatHistorySnapshot) {
        pendingSaveTask?.cancel()

        let prunedSnapshot = policy.pruneSnapshot(snapshot)
        let store = store
        pendingSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }

            store.save(prunedSnapshot)
        }
    }

    func saveImmediately(_ snapshot: ChatHistorySnapshot) {
        pendingSaveTask?.cancel()
        store.save(policy.pruneSnapshot(snapshot))
    }

    func clear() {
        pendingSaveTask?.cancel()
        store.clear()
    }

    func pruneVisibleMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        policy.pruneVisibleMessages(messages)
    }

    func pruneArchivedMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        Array(messages.suffix(policy.maxArchivedMessagesPerChat))
    }

    func pruneRecentChats(_ chats: [ChatSession]) -> [ChatSession] {
        guard chats.count > policy.maxRecentChats else { return chats }

        return Array(chats.prefix(policy.maxRecentChats))
    }
}
