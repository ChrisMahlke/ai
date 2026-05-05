//
//  ChatResponding.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

protocol ChatResponding {
    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String>
}
