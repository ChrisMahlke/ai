//
//  ChatHistorySnapshot.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatHistorySnapshot: Codable, Equatable, Sendable {
    let currentChatID: UUID
    let currentTitleOverride: String?
    let currentMessages: [ChatMessage]
    let recentChats: [ChatSession]

    init(
        currentChatID: UUID,
        currentTitleOverride: String? = nil,
        currentMessages: [ChatMessage],
        recentChats: [ChatSession]
    ) {
        self.currentChatID = currentChatID
        self.currentTitleOverride = currentTitleOverride
        self.currentMessages = currentMessages
        self.recentChats = recentChats
    }
}
