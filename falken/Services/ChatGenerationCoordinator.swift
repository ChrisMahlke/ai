//
//  ChatGenerationCoordinator.swift
//  falken
//
//  Created by Chris Mahlke on 5/6/26.
//

import Foundation

struct ChatGenerationCoordinator {
    enum Event: Sendable {
        case started(UUID)
        case token(String, UUID)
        case finished(didStart: Bool)
    }

    let tokenFlushCharacterCount: Int
    let tokenFlushInterval: TimeInterval

    init(
        tokenFlushCharacterCount: Int = 32,
        tokenFlushInterval: TimeInterval = 0.045
    ) {
        self.tokenFlushCharacterCount = tokenFlushCharacterCount
        self.tokenFlushInterval = tokenFlushInterval
    }

    func events(
        prompt: String,
        history: [ChatMessage],
        responder: any ChatResponding
    ) async -> AsyncStream<Event> {
        let stream = await responder.responseStream(for: prompt, history: history)

        return AsyncStream { continuation in
            let assistantID = UUID()
            let task = Task {
                var didStartResponse = false
                var tokenBuffer = ""
                var lastFlush = Date()

                func flushBufferedTokens() {
                    guard !tokenBuffer.isEmpty else { return }

                    continuation.yield(.token(tokenBuffer, assistantID))
                    tokenBuffer = ""
                    lastFlush = Date()
                }

                for await token in stream {
                    guard !Task.isCancelled else {
                        flushBufferedTokens()
                        continuation.finish()
                        return
                    }

                    if !didStartResponse {
                        continuation.yield(.started(assistantID))
                        didStartResponse = true
                    }

                    tokenBuffer += token
                    if tokenBuffer.count >= tokenFlushCharacterCount
                        || Date().timeIntervalSince(lastFlush) >= tokenFlushInterval
                        || token.contains("\n") {
                        flushBufferedTokens()
                    }
                }

                flushBufferedTokens()
                continuation.yield(.finished(didStart: didStartResponse))
                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
