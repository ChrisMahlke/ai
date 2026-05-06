//
//  RemoteProviderChatResponder.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct RemoteProviderConfiguration: Equatable, Sendable {
    let provider: ChatProvider
    let isEnabled: Bool
    let modelName: String

    static let gemini = RemoteProviderConfiguration(
        provider: .gemini,
        isEnabled: false,
        modelName: "gemini"
    )
}

struct RemoteProviderChatResponder: ChatResponding {
    let configuration: RemoteProviderConfiguration

    func responseStream(for prompt: String, history: [ChatMessage]) async -> AsyncStream<String> {
        AsyncStream { continuation in
            let response: String
            if configuration.isEnabled {
                response = "\(configuration.modelName) is enabled, but no SDK transport has been attached in this build."
            } else {
                response = """
                \(configuration.provider.title) is selected but not configured.

                The responder path is shared with local chat, so an SDK transport can be attached without changing the chat UI.
                """
            }

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
