//
//  LocalAIManager+Generation.swift
//  falken
//
//  Created by Chris Mahlke on 5/5/26.
//

import Foundation
import LlamaBackendKit

@MainActor
extension LocalAIManager {
    func cancelGeneration() {
        engine.cancelGeneration()
    }

    func generateResponse(prompt: String, history: [ChatMessage]) -> AsyncStream<String> {
        guard case .loaded = loadState else {
            return singleMessageStream("The local model is not loaded yet.")
        }

        let engine = engine
        let messages = LocalPromptBuilder.chatTurns(prompt: prompt, history: history)

        return AsyncStream { continuation in
            let generationTask = Task {
                do {
                    try await engine.generateChat(messages: messages) { token in
                        continuation.yield(token)
                        Task { @MainActor [weak self] in
                            self?.recordGenerationMemory()
                        }
                    }
                    continuation.finish()
                } catch LlamaBackendError.cancelled {
                    continuation.finish()
                } catch {
                    continuation.yield(error.localizedDescription)
                    continuation.finish()
                }
            }

            continuation.onTermination = { @Sendable _ in
                generationTask.cancel()
                engine.cancelGeneration()
            }
        }
    }

    func singleMessageStream(_ message: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            continuation.yield(message)
            continuation.finish()
        }
    }
}

enum LocalPromptBuilder {
    static func chatTurns(prompt: String, history: [ChatMessage]) -> [LlamaChatTurn] {
        let conversationalHistory = history.isEmpty ? [ChatMessage(role: .user, text: prompt)] : history
        var turns = [
            LlamaChatTurn(
                role: "system",
                content: "You are a concise, helpful assistant running locally on this device."
            )
        ]

        for message in conversationalHistory {
            switch message.role {
            case .user:
                turns.append(LlamaChatTurn(role: "user", content: message.text))
            case .assistant:
                turns.append(LlamaChatTurn(role: "assistant", content: message.text))
            }
        }

        return turns
    }
}
