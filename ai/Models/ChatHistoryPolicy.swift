//
//  ChatHistoryPolicy.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatHistoryPolicy: Equatable, Sendable {
    nonisolated static let `default` = ChatHistoryPolicy(
        maxRecentChats: 40,
        maxVisibleMessages: 120,
        maxArchivedMessagesPerChat: 80,
        maxCharactersPerMessage: 6_000,
        maxPersistedCharacters: 220_000
    )

    let maxRecentChats: Int
    let maxVisibleMessages: Int
    let maxArchivedMessagesPerChat: Int
    let maxCharactersPerMessage: Int
    let maxPersistedCharacters: Int

    func pruneVisibleMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        Array(messages.suffix(maxVisibleMessages))
    }

    func pruneSnapshot(_ snapshot: ChatHistorySnapshot) -> ChatHistorySnapshot {
        var remainingCharacters = maxPersistedCharacters
        let currentMessages = pruneMessages(snapshot.currentMessages, limit: maxVisibleMessages, remainingCharacters: &remainingCharacters)
        var recentChats: [ChatSession] = []

        for chat in snapshot.recentChats.prefix(maxRecentChats) {
            guard remainingCharacters > 0 else { break }

            let messages = pruneMessages(chat.messages, limit: maxArchivedMessagesPerChat, remainingCharacters: &remainingCharacters)
            guard messages.contains(where: { $0.role == .user }) else { continue }

            recentChats.append(ChatSession(
                id: chat.id,
                title: chat.title,
                messages: messages,
                createdAt: chat.createdAt,
                updatedAt: chat.updatedAt
            ))
        }

        return ChatHistorySnapshot(
            currentChatID: snapshot.currentChatID,
            currentTitleOverride: snapshot.currentTitleOverride,
            currentMessages: currentMessages,
            recentChats: recentChats
        )
    }

    private func pruneMessages(
        _ messages: [ChatMessage],
        limit: Int,
        remainingCharacters: inout Int
    ) -> [ChatMessage] {
        var pruned: [ChatMessage] = []

        for message in messages.suffix(limit).reversed() {
            guard remainingCharacters > 0 else { break }

            let text = String(message.text.prefix(min(message.text.count, maxCharactersPerMessage, remainingCharacters)))
            remainingCharacters -= text.count
            pruned.append(ChatMessage(id: message.id, role: message.role, text: text))
        }

        return pruned.reversed()
    }
}
