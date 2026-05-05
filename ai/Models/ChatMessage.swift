//
//  ChatMessage.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Codable, Sendable {
    enum Role: Equatable, Codable, Sendable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    var text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}
