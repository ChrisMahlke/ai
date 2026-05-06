//
//  ChatMessage.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct ChatMessage: Identifiable, Equatable, Codable, Sendable {
    enum Role: Equatable, Codable, Sendable {
        case user
        case assistant
    }

    enum State: Equatable, Codable, Sendable {
        case complete
        case stopped
        case failed
    }

    let id: UUID
    let role: Role
    var text: String
    var state: State

    init(id: UUID = UUID(), role: Role, text: String, state: State = .complete) {
        self.id = id
        self.role = role
        self.text = text
        self.state = state
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case text
        case state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        role = try container.decode(Role.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        state = try container.decodeIfPresent(State.self, forKey: .state) ?? .complete
    }
}
