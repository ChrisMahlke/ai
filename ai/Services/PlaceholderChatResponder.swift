//
//  PlaceholderChatResponder.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct PlaceholderChatResponder: ChatResponding {
    let configuration: InferenceConfiguration

    init(configuration: InferenceConfiguration = .default) {
        self.configuration = configuration
    }

    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String> {
        let response = "I can respond to \"\(prompt)\" once \(configuration.localModelIdentifier) is connected. For now, this is a minimal placeholder reply."

        return AsyncStream { continuation in
            Task {
                try? await Task.sleep(for: .milliseconds(450))

                for token in response.split(separator: " ") {
                    continuation.yield(String(token) + " ")
                    try? await Task.sleep(for: .milliseconds(35))
                }

                continuation.finish()
            }
        }
    }
}
