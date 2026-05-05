//
//  GeminiChatResponder.swift
//  ai
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation

struct GeminiChatResponder: ChatResponding {
    let configuration: InferenceConfiguration

    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String> {
        AsyncStream { continuation in
            let response = """
            Gemini is selected, but the remote SDK provider is not configured yet.

            The app is already routed through the provider abstraction, so the Gemini SDK can be added without changing the chat UI or local model path.
            """

            Task {
                for token in response.split(separator: " ", omittingEmptySubsequences: false) {
                    guard !Task.isCancelled else {
                        continuation.finish()
                        return
                    }

                    continuation.yield(String(token) + " ")
                    try? await Task.sleep(for: .milliseconds(24))
                }

                continuation.finish()
            }
        }
    }
}
