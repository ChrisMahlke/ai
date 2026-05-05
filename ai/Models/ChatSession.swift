//
//  ChatSession.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatSession: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let title: String
    let messages: [ChatMessage]
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
