//
//  ChatSession.swift
//  falken
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
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case messages
        case createdAt
        case updatedAt
        case isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}
